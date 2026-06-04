exports.getAllCheckouts = async (req, res, next) => {
  try {
    const [checkouts] = await req.db.query(
      `SELECT ch.*, o.total as order_total, o.order_status, c.name as customer_name
       FROM checkout ch
       LEFT JOIN orders o ON ch.orders_id = o.id
       LEFT JOIN customer c ON o.customer_id = c.id
       ORDER BY ch.created_at DESC`
    );
    res.json({ success: true, count: checkouts.length, data: checkouts });
  } catch (error) {
    next(error);
  }
};

exports.getCheckoutById = async (req, res, next) => {
  try {
    const [checkouts] = await req.db.query(
      `SELECT ch.*, o.total as order_total, o.order_status, c.name as customer_name
       FROM checkout ch
       LEFT JOIN orders o ON ch.orders_id = o.id
       LEFT JOIN customer c ON o.customer_id = c.id
       WHERE ch.id = ?`,
      [req.params.id]
    );
    if (checkouts.length === 0) {
      return res.status(404).json({ success: false, message: 'Checkout not found' });
    }
    res.json({ success: true, data: checkouts[0] });
  } catch (error) {
    next(error);
  }
};

exports.getCheckoutByOrder = async (req, res, next) => {
  try {
    const [checkouts] = await req.db.query(
      `SELECT ch.*, o.total as order_total, o.order_status
       FROM checkout ch
       LEFT JOIN orders o ON ch.orders_id = o.id
       WHERE ch.orders_id = ?`,
      [req.params.orderId]
    );
    res.json({ success: true, count: checkouts.length, data: checkouts });
  } catch (error) {
    next(error);
  }
};

exports.createCheckout = async (req, res, next) => {
  try {
    const { orders_id } = req.body;
    if (!orders_id) {
      return res.status(400).json({ success: false, message: 'orders_id is required' });
    }
    const [orders] = await req.db.query('SELECT id FROM orders WHERE id = ?', [orders_id]);
    if (orders.length === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const [result] = await req.db.query(
      'INSERT INTO checkout (orders_id, payment_status, created_at) VALUES (?, ?, ?)',
      [orders_id, 'pending', now]
    );
    res.status(201).json({ success: true, message: 'Checkout created', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateCheckoutStatus = async (req, res, next) => {
  try {
    const { payment_status } = req.body;
    const validStatuses = ['cancelled', 'pending', 'paid', ''];
    if (!validStatuses.includes(payment_status)) {
      return res.status(400).json({ success: false, message: 'Invalid payment status' });
    }
    const [result] = await req.db.query(
      'UPDATE checkout SET payment_status = ? WHERE id = ?',
      [payment_status, req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Checkout not found' });
    }
    if (payment_status === 'paid') {
      const [checkout] = await req.db.query('SELECT orders_id FROM checkout WHERE id = ?', [req.params.id]);
      if (checkout.length > 0) {
        await req.db.query(
          "UPDATE orders SET order_status = 'success', modified_at = NOW() WHERE id = ?",
          [checkout[0].orders_id]
        );
      }
    }
    res.json({ success: true, message: 'Payment status updated' });
  } catch (error) {
    next(error);
  }
};
