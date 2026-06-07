const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

/**
 * Ensure that a `customer` row exists for the given user. If it does not, create one.
 * Returns the customer row (id, name, phone, loyalty_stamps, vouchers, ...).
 *
 * This is the linchpin that fixes the FK error `fk_orders_customer` because the
 * mobile app uses the id returned by /api/auth/* as the `customer_id` when
 * creating orders. Without a `customer` row linked to the user, orders would fail.
 */
async function ensureCustomerForUser(db, user) {
  // Look up an existing customer linked to this user
  const [rows] = await db.query(
    'SELECT * FROM customer WHERE user_id = ? LIMIT 1',
    [user.id]
  );
  if (rows.length > 0) return rows[0];

  // No linked customer yet → create one
  const [result] = await db.query(
    'INSERT INTO customer (name, phone, user_id, loyalty_stamps, vouchers, created_at, modified_at) VALUES (?, ?, ?, 0, 0, NOW(), NOW())',
    [user.name || 'Guest', user.phone || null, user.id]
  );
  const [created] = await db.query('SELECT * FROM customer WHERE id = ?', [result.insertId]);
  return created[0];
}

exports.register = async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'name, email, and password are required' });
    }
    const [existing] = await req.db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }
    const password_hash = await bcrypt.hash(password, 10);
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

    // Default role is 'customer' (mobile sign-up). CMS staff/admin must be
    // explicitly created by an admin/seeder.
    const finalRole = role || 'customer';

    const [result] = await req.db.query(
      'INSERT INTO users (name, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?)',
      [name, email, password_hash, finalRole, now]
    );
    const userId = result.insertId;

    // For every regular customer login (mobile), ensure a matching `customer` row.
    let customer = null;
    if (finalRole === 'customer') {
      customer = await ensureCustomerForUser(req.db, { id: userId, name });
    }

    const token = jwt.sign(
      { id: userId, name, email, role: finalRole, customer_id: customer ? customer.id : null },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // The mobile app reads `id` and treats it as the customer id. To keep the
    // contract simple, expose `customer.id` as `id` when the user has a
    // customer profile. The user_id is still available separately.
    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        id: customer ? customer.id : userId,
        user_id: userId,
        customer_id: customer ? customer.id : null,
        name,
        email,
        role: finalRole,
        loyalty_stamps: customer ? customer.loyalty_stamps : 0,
        vouchers: customer ? customer.vouchers : 0,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }
    const [users] = await req.db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }
    const user = users[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    // For mobile customers, ensure a linked `customer` row exists. This also
    // backfills any pre-existing user that was created before this fix.
    let customer = null;
    if (user.role === 'customer' || user.role === null || user.role === undefined) {
      customer = await ensureCustomerForUser(req.db, { id: user.id, name: user.name });
    }

    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email, role: user.role, customer_id: customer ? customer.id : null },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        id: customer ? customer.id : user.id,
        user_id: user.id,
        customer_id: customer ? customer.id : null,
        name: user.name,
        email: user.email,
        role: user.role,
        loyalty_stamps: customer ? customer.loyalty_stamps : 0,
        vouchers: customer ? customer.vouchers : 0,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

exports.getMe = async (req, res, next) => {
  try {
    const [users] = await req.db.query(
      'SELECT id, name, email, role, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (users.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const user = users[0];
    let customer = null;
    if (user.role === 'customer' || user.role === null) {
      const [rows] = await req.db.query('SELECT * FROM customer WHERE user_id = ? LIMIT 1', [user.id]);
      customer = rows[0] || null;
    }
    res.json({
      success: true,
      data: {
        ...user,
        customer_id: customer ? customer.id : null,
        loyalty_stamps: customer ? customer.loyalty_stamps : 0,
        vouchers: customer ? customer.vouchers : 0,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Exported for use in other controllers (orderController) to lazily provision
// a customer for legacy clients sending stale ids.
exports.ensureCustomerForUser = ensureCustomerForUser;
