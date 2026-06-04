exports.getBundles = async (req, res, next) => {
  try {
    const [bundles] = await req.db.query('SELECT * FROM bundles ORDER BY created_at DESC');
    res.json({ success: true, count: bundles.length, data: bundles });
  } catch (error) {
    next(error);
  }
};

exports.getBundleById = async (req, res, next) => {
  try {
    const [bundles] = await req.db.query('SELECT * FROM bundles WHERE id = ?', [req.params.id]);
    if (bundles.length === 0) {
      return res.status(404).json({ success: false, message: 'Bundle not found' });
    }
    res.json({ success: true, data: bundles[0] });
  } catch (error) {
    next(error);
  }
};

exports.createBundle = async (req, res, next) => {
  try {
    const { Type, name, description, price } = req.body;
    if (!name || price === undefined) {
      return res.status(400).json({ success: false, message: 'Name and price are required' });
    }
    const [result] = await req.db.query(
      'INSERT INTO bundles (Type, name, description, price) VALUES (?, ?, ?, ?)',
      [Type || null, name, description || null, price]
    );
    res.status(201).json({ success: true, message: 'Bundle created', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateBundle = async (req, res, next) => {
  try {
    const { Type, name, description, price } = req.body;
    const [result] = await req.db.query(
      'UPDATE bundles SET Type = ?, name = ?, description = ?, price = ? WHERE id = ?',
      [Type, name, description, price, req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Bundle not found' });
    }
    res.json({ success: true, message: 'Bundle updated' });
  } catch (error) {
    next(error);
  }
};

exports.deleteBundle = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM bundles WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Bundle not found' });
    }
    res.json({ success: true, message: 'Bundle deleted' });
  } catch (error) {
    next(error);
  }
};
