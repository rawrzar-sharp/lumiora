exports.getOrders = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.*, m.item_name, m.price as menu_price, c.name as customer_name
       FROM orders o
       LEFT JOIN menu m ON o.menu_id = m.id
       LEFT JOIN customer c ON o.customer_id = c.id
       ORDER BY o.created_at DESC`
    );
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

exports.getOrderById = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.*, m.item_name, m.price as menu_price, c.name as customer_name
       FROM orders o
       LEFT JOIN menu m ON o.menu_id = m.id
       LEFT JOIN customer c ON o.customer_id = c.id
       WHERE o.id = ?`,
      [req.params.id]
    );
    if (orders.length === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: orders[0] });
  } catch (error) {
    next(error);
  }
};

exports.getOrdersByCustomer = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.*, m.item_name, m.price as menu_price
       FROM orders o
       LEFT JOIN menu m ON o.menu_id = m.id
       WHERE o.customer_id = ?
       ORDER BY o.created_at DESC`,
      [req.params.customerId]
    );
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

exports.createOrder = async (req, res, next) => {
  try {
    const { customer_id, menu_id, quantity, ice_level, sugar_level } = req.body;
    if (!customer_id || !menu_id || !quantity) {
      return res.status(400).json({ success: false, message: 'customer_id, menu_id, and quantity are required' });
    }
    const [menu] = await req.db.query('SELECT price FROM menu WHERE id = ?', [menu_id]);
    if (menu.length === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }
    const total = menu[0].price * quantity;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const [result] = await req.db.query(
      `INSERT INTO orders (customer_id, menu_id, quantity, ice_level, sugar_level, total, order_status, created_at, modified_at)
       VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?)`,
      [customer_id, menu_id, quantity, ice_level || 'iced', sugar_level || 'normal', total, now, now]
    );
    res.status(201).json({ success: true, message: 'Order created', id: result.insertId, total });
  } catch (error) {
    next(error);
  }
};

exports.updateOrder = async (req, res, next) => {
  try {
    const { quantity, ice_level, sugar_level, order_status } = req.body;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const [result] = await req.db.query(
      `UPDATE orders SET quantity = COALESCE(?, quantity), ice_level = COALESCE(?, ice_level),
       sugar_level = COALESCE(?, sugar_level), order_status = COALESCE(?, order_status),
       modified_at = ? WHERE id = ?`,
      [quantity, ice_level, sugar_level, order_status, now, req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, message: 'Order updated' });
  } catch (error) {
    next(error);
  }
};

exports.deleteOrder = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM orders WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, message: 'Order deleted' });
  } catch (error) {
    next(error);
  }
};
