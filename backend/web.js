require('dotenv').config();

const express = require('express');
const cors = require('cors');
const pool = require('./config/db');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger/swagger');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS — explicit allowlist for production hosts plus permissive fallback
// for tools that send no Origin (curl, Flutter app, Postman, server-to-server).
// Set CORS_ORIGINS as a comma-separated env var to extend the list.
const DEFAULT_CORS_ORIGINS = [
  'http://43.133.144.212:1234',   // production API host (Swagger / direct hits)
  'http://104.197.208.136',       // GCP-hosted CMS (HTTP)
  'http://104.197.208.136:80',
  'http://104.197.208.136:3000',
  'http://104.197.208.136:1234',
  'https://104.197.208.136',
  'http://localhost:3000',
  'http://localhost:1234',
];
const EXTRA = (process.env.CORS_ORIGINS || '').split(',').map((s) => s.trim()).filter(Boolean);
const ALLOWED_ORIGINS = [...new Set([...DEFAULT_CORS_ORIGINS, ...EXTRA])];
app.use(cors({
  origin: (origin, cb) => {
    // No-origin requests (curl, mobile apps, server-side) are allowed.
    if (!origin) return cb(null, true);
    if (ALLOWED_ORIGINS.includes(origin)) return cb(null, true);
    // Be permissive for *.preview.emergentagent.com (preview tunnels).
    if (/\.preview\.emergentagent\.com$/.test(new URL(origin).hostname)) return cb(null, true);
    return cb(null, true); // currently permissive — change to cb(new Error('CORS')) to lock down
  },
  credentials: true,
}));
app.use(express.json());

const path = require('path');
app.use('/assets', express.static(path.join(__dirname, 'assets')));

app.use((req, res, next) => {
  req.db = pool;
  next();
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Cafe API Docs',
}));

app.use('/api/bundles', require('./routes/bundleRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/customers', require('./routes/customerRoutes'));
app.use('/api/menu', require('./routes/menuRoutes'));
app.use('/api/categories', require('./routes/categoryRoutes'));
app.use('/api/checkouts', require('./routes/checkoutRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/cms', require('./routes/cmsRoutes'));

app.get('/products', async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, c.name as category_name
       FROM menu m LEFT JOIN category c ON m.category_id = c.id ORDER BY m.id`
    );
    res.json({ success: true, count: menu.length, data: menu });
  } catch (error) {
    next(error);
  }
});

app.get('/', (req, res) => {
  res.json({
    message: 'Cafe API is running!',
    version: '1.0.0',
    docs: '/api-docs',
    endpoints: {
      bundles: '/api/bundles',
      orders: '/api/orders',
      customers: '/api/customers',
      menu: '/api/menu',
      categories: '/api/categories',
      checkouts: '/api/checkouts',
      users: '/api/users',
      auth: '/api/auth',
    },
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

app.get('/check-columns', async (req, res) => {
  try {
    // Mengambil daftar kolom dari tabel users
    const [usersCols] = await req.db.query("SHOW COLUMNS FROM users");
    // Mengambil daftar kolom dari tabel customers
    const [customersCols] = await req.db.query("SHOW COLUMNS FROM customer");

    res.json({
      pesan: "Daftar Kolom di Database",
      kolom_tabel_users: usersCols.map(col => col.Field),
      kolom_tabel_customers: customersCols.map(col => col.Field)
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// --- JALAN TIKUS UNTUK MEMPERBAIKI PASSWORD ADMIN & STAFF ---
// The legacy seed put placeholder bcrypt strings into `users.password_hash`,
// which makes login impossible. Hitting `/fix-admin` rewrites the built-in
// accounts with real bcrypt hashes so the CMS (and Flutter) login starts
// working immediately. The startup migration below already does the same on
// every boot — this endpoint is just a manual escape hatch.
const bcryptFix = require('bcryptjs');

// Canonical set of CMS seed accounts. Edit this list to add/remove built-ins.
const SEED_ACCOUNTS = [
  { name: 'Super Admin', email: 'diamonddark269@gmail.com', password: 'admin123', role: 'admin' },
  { name: 'Admin Cafe',  email: 'admin12@gmail.com',        password: 'admin123', role: 'admin' },
  { name: 'Staff Cafe',  email: 'staff25@gmail.com',        password: 'staff123', role: 'staff' },
];

// Emails that used to be seeded but should now be retired.
const RETIRED_SEED_EMAILS = ['staff@lumiora.com'];

async function seedBuiltinAccounts(db) {
  for (const acc of SEED_ACCOUNTS) {
    const hash = await bcryptFix.hash(acc.password, 10);
    // Upsert: if the email already exists, force the role + password back to
    // the seeded values so a corrupted hash can't lock the operator out.
    await db.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), role = VALUES(role)`,
      [acc.name, acc.email, hash, acc.role]
    );
  }
  if (RETIRED_SEED_EMAILS.length > 0) {
    await db.query(
      `DELETE FROM users WHERE email IN (?)`,
      [RETIRED_SEED_EMAILS]
    );
  }
}

app.get('/fix-admin', async (req, res) => {
  try {
    await seedBuiltinAccounts(req.db);
    const list = SEED_ACCOUNTS
      .map(a => `<li><b>${a.role.toUpperCase()}:</b> ${a.email} / ${a.password}</li>`)
      .join('');
    res.send(`<h1>SUKSES!</h1>
      <p>Akun seed sudah dipasang ulang dengan bcrypt.</p>
      <ul>${list}</ul>
      <p>Silakan kembali ke CMS dan login pakai salah satu akun di atas.</p>`);
  } catch (error) {
    res.status(500).send('Gagal: ' + error.message);
  }
});

async function waitForDatabase(retries = 20, delayMs = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const conn = await pool.getConnection();
      conn.release();
      console.log('Database reachable, starting server');
      return;
    } catch (err) {
      console.warn(`DB not ready (attempt ${i + 1}/${retries}): ${err.message}`);
      await new Promise(res => setTimeout(res, delayMs));
    }
  }
  throw new Error('Database did not become ready in time');
}

// ---------------------------------------------------------------------------
// Self-healing startup migrations.
// We can't assume the operator has run the SQL files in phpMyAdmin (that has
// bitten us twice already), so the API quietly ensures its own schema on every
// boot. Each step is idempotent and cheap:
//   1. Make sure `order_items` has preferences_json / addons_json / notes.
//   2. Make sure `menu_items.customization_options` exists.
//   3. Rewrite the customization payload into the new `preference_groups`
//      shape (Ice / Sugar / Bean / Style / Temperature / Spice Level).
// If any step fails we log a warning and continue — the API still boots so
// the operator can investigate without losing the whole service.
// ---------------------------------------------------------------------------
async function runStartupMigrations() {
  const addColumnIfMissing = async (table, column, ddl) => {
    const [rows] = await pool.query(
      `SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      [table, column]
    );
    if (rows[0].cnt === 0) {
      console.log(`[startup-mig] adding ${table}.${column}`);
      await pool.query(`ALTER TABLE \`${table}\` ADD COLUMN ${ddl}`);
    }
  };

  try {
    // 1. order_items columns
    await addColumnIfMissing('order_items', 'preferences_json', '`preferences_json` JSON NULL AFTER `price_at_sale`');
    await addColumnIfMissing('order_items', 'addons_json',      '`addons_json` JSON NULL AFTER `preferences_json`');
    await addColumnIfMissing('order_items', 'notes',            '`notes` TEXT NULL AFTER `addons_json`');

    // 2. menu_items.customization_options
    await addColumnIfMissing('menu_items', 'customization_options', '`customization_options` JSON NULL');

    // 3. Seed preference_groups if at least one row is still on the old shape
    const [stale] = await pool.query(
      `SELECT COUNT(*) AS cnt FROM menu_items
        WHERE customization_options IS NULL
           OR JSON_EXTRACT(customization_options, '$.preference_groups') IS NULL`
    );
    if (stale[0].cnt > 0) {
      console.log(`[startup-mig] seeding preference_groups on ${stale[0].cnt} menu_items row(s)`);

      // Coffee + Lattes (Ice / Sugar / Bean)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
            'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                                      'Half Sugar (50%)', 'Slight Sugar (25%)', 'No Sugar'),
            'Coffee Bean', JSON_ARRAY('Standard', 'Strong')
          ),
          'addons', JSON_OBJECT(
            'Oat Milk Upgrade', 8000, 'Almond Milk Upgrade', 9000,
            'Extra Espresso Shot', 5000, 'Caramel Drizzle', 4000, 'Vanilla Syrup', 4000
          )
        ) WHERE id IN (1, 3, 4, 5, 6, 9, 10, 11, 12, 14, 15, 16)`);

      // Aren Lattes (Ice / Sugar)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
            'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                                      'Half Sugar (50%)', 'Slight Sugar (25%)')
          ),
          'addons', JSON_OBJECT(
            'Extra Palm Sugar', 3000, 'Sea Salt Cream Foam', 5000,
            'Coffee Jelly Topping', 4000, 'Oat Milk Upgrade', 8000
          )
        ) WHERE id IN (2, 7, 8)`);

      // Non-coffee (Ice / Sugar)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
            'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                                      'Half Sugar (50%)', 'Slight Sugar (25%)', 'No Sugar')
          ),
          'addons', JSON_OBJECT(
            'Strawberry Puree', 5000, 'Matcha Cold Foam', 6000,
            'Chewy Boba Pearls', 4000, 'Soy Milk Upgrade', 7000
          )
        ) WHERE id IN (17, 18, 19)`);

      // Bundles (Style)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Style', JSON_ARRAY('All Iced', 'All Hot', 'Mix (Please add to notes)')
          ),
          'addons', JSON_OBJECT(
            'Upgrade All to Large', 15000, 'Add Greeting Card', 5000,
            'Premium Carrier Bag', 3000, 'Add 3 Butter Croissants', 25000
          )
        ) WHERE id BETWEEN 20 AND 28`);

      // Savory pastries (Temperature)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Temperature', JSON_ARRAY('Toasted & Warmed', 'Room Temperature')
          ),
          'addons', JSON_OBJECT(
            'Extra Melted Cheese', 5000, 'Spicy Mayo Dip', 3000,
            'Truffle Oil Splash', 6000, 'Smoked Beef Slice', 7000
          )
        ) WHERE id IN (29, 30, 33)`);

      // Sweet pastries (Temperature)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Temperature', JSON_ARRAY('Warmed Up (Gooey)', 'Normal')
          ),
          'addons', JSON_OBJECT(
            'Vanilla Ice Cream Scoop', 8000, 'Melted Chocolate Pour', 5000,
            'Matcha Powder Dusting', 2000, 'Extra Butter Portion', 3000
          )
        ) WHERE id IN (31, 32, 34, 35)`);

      // Skewers (Spice Level)
      await pool.query(`
        UPDATE menu_items SET customization_options = JSON_OBJECT(
          'preference_groups', JSON_OBJECT(
            'Spice Level', JSON_ARRAY('Mild', 'Medium Spicy', 'Volcano Spicy', 'Sweet Soy Sauce Only')
          ),
          'addons', JSON_OBJECT(
            'Nori Seaweed Flakes', 2000, 'Extra Gochujang Sauce', 4000,
            'Mozzarella Wrap', 7000, 'Garlic Mayo Drizzle', 3000
          )
        ) WHERE id BETWEEN 36 AND 40`);
    }

    console.log('[startup-mig] complete');
  } catch (err) {
    console.error('[startup-mig] failed (continuing anyway):', err.message);
  }

  // Always (re)seed the built-in CMS accounts so the operator can never get
  // locked out of admin. Runs after the schema migration so the `users` table
  // is guaranteed to exist.
  try {
    await seedBuiltinAccounts(pool);
    console.log('[startup-mig] built-in CMS accounts ensured: ' +
      SEED_ACCOUNTS.map(a => `${a.email} (${a.role})`).join(', '));
  } catch (err) {
    console.error('[startup-mig] seedBuiltinAccounts failed:', err.message);
  }

  // Idempotently seed the master ingredients list, the per-item recipes
  // (ingredients + quantities) and the per-item prep steps that power the new
  // CMS "Recipes" page. Also soft-hides Bundling Duo + Trio so Menu Manager
  // stops showing them — order history remains intact.
  try {
    const { seedRecipesAndIngredients } = require('./seed-recipes');
    await seedRecipesAndIngredients(pool);
    console.log('[startup-mig] recipes + ingredients seeded; bundles soft-hidden');
  } catch (err) {
    console.error('[startup-mig] seedRecipesAndIngredients failed:', err.message);
  }
}

(async () => {
  try {
    await waitForDatabase(30, 1000);
    await runStartupMigrations();
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on http://localhost:${PORT}`);
      console.log(`API Docs: http://localhost:${PORT}/api-docs`);
    });
  } catch (err) {
    console.error('Failed to start server:', err.message);
    process.exit(1);
  }
})();

