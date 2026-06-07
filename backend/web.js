require('dotenv').config();

const express = require('express');
const cors = require('cors');
const pool = require('./config/db');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger/swagger');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
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
// which makes login impossible. Hitting `/fix-admin` rewrites both built-in
// accounts with real bcrypt hashes of `admin123` and `staff123` so the CMS
// (and Flutter) login starts working immediately.
const bcryptFix = require('bcryptjs');
app.get('/fix-admin', async (req, res) => {
  try {
    const adminHash = await bcryptFix.hash('admin123', 10);
    const staffHash = await bcryptFix.hash('staff123', 10);

    await req.db.query(
      "UPDATE users SET password_hash = ?, role = 'admin' WHERE email = 'diamonddark269@gmail.com'",
      [adminHash]
    );
    await req.db.query(
      "UPDATE users SET password_hash = ?, role = 'staff' WHERE email = 'staff@lumiora.com'",
      [staffHash]
    );

    // Backfill: if the seed users weren't there yet, create them.
    await req.db.query(
      `INSERT INTO users (name, email, password_hash, role)
       SELECT 'Super Admin', 'diamonddark269@gmail.com', ?, 'admin'
       WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'diamonddark269@gmail.com')`,
      [adminHash]
    );
    await req.db.query(
      `INSERT INTO users (name, email, password_hash, role)
       SELECT 'Staff Cafe', 'staff@lumiora.com', ?, 'staff'
       WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'staff@lumiora.com')`,
      [staffHash]
    );

    res.send(`<h1>SUKSES!</h1>
      <p>Password admin & staff sudah dienkripsi ulang dengan bcrypt.</p>
      <ul>
        <li><b>Admin:</b> diamonddark269@gmail.com / admin123</li>
        <li><b>Staff:</b> staff@lumiora.com / staff123</li>
      </ul>
      <p>Silakan kembali ke CMS dan login pakai email di atas.</p>`);
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

(async () => {
  try {
    await waitForDatabase(30, 1000);
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on http://localhost:${PORT}`);
      console.log(`API Docs: http://localhost:${PORT}/api-docs`);
    });
  } catch (err) {
    console.error('Failed to start server:', err.message);
    process.exit(1);
  }
})();

