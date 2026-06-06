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

exports.createOrder = async (req, res) => {
  try {
    const { 
        customer_id, menu_id, quantity, order_type, 
        payment_method, total, ice_level, sugar_level, order_number 
    } = req.body;

    const finalOrderNumber = order_number || `ORD-${Math.floor(100000 + Math.random() * 900000)}`;

    // 🔥 FIX: Insert into BOTH 'total' and 'total_amount' to satisfy the strict database rules
    const sql = `
      INSERT INTO orders 
      (customer_id, menu_id, quantity, order_type, payment_method, total, total_amount, ice_level, sugar_level, order_number)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    // Notice we pass the 'total' variable twice below (once for total, once for total_amount)
    const values = [
        customer_id, menu_id, quantity, order_type, 
        payment_method, total, total, ice_level, sugar_level, finalOrderNumber
    ];

    const [result] = await req.db.query(sql, values);
    
    res.status(201).json({ success: true, id: result.insertId, order_number: finalOrderNumber });
  } catch (error) {
    console.error("Create Order Error:", error);
    res.status(500).json({ success: false, message: error.message });
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
