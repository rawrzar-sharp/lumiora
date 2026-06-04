exports.getAllCustomers = async (req, res, next) => {
  try {
    const [customers] = await req.db.query(
      'SELECT id, name, phone, birthday, created_at, modified_at, user_id FROM customer ORDER BY created_at DESC'
    );
    res.json({ success: true, count: customers.length, data: customers });
  } catch (error) {
    next(error);
  }
};

exports.getCustomerById = async (req, res, next) => {
  try {
    const [customers] = await req.db.query('SELECT * FROM customer WHERE id = ?', [req.params.id]);
    if (customers.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    res.json({ success: true, data: customers[0] });
  } catch (error) {
    next(error);
  }
};

exports.addCustomer = async (req, res, next) => {
  try {
    const { name, phone, birthday, user_id } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Name is required' });
    }
    const [result] = await req.db.query(
      'INSERT INTO customer (name, phone, birthday, user_id, created_at, modified_at) VALUES (?, ?, ?, ?, NOW(), NOW())',
      [name, phone || '0', birthday || null, user_id || null]
    );
    res.status(201).json({ success: true, message: 'Customer added', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateCustomer = async (req, res, next) => {
  try {
    const { name, phone, birthday, user_id } = req.body;
    const [result] = await req.db.query(
      'UPDATE customer SET name = ?, phone = ?, birthday = ?, user_id = ?, modified_at = NOW() WHERE id = ?',
      [name, phone, birthday, user_id, req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    res.json({ success: true, message: 'Customer updated' });
  } catch (error) {
    next(error);
  }
};

exports.deleteCustomer = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM customer WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }
    res.json({ success: true, message: 'Customer deleted' });
  } catch (error) {
    next(error);
  }
};
