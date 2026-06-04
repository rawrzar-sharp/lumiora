exports.getAllCategories = async (req, res, next) => {
  try {
    const [categories] = await req.db.query(
      `SELECT c.*, COUNT(m.id) as menu_count
       FROM category c
       LEFT JOIN menu m ON c.id = m.category_id
       GROUP BY c.id
       ORDER BY c.id`
    );
    res.json({ success: true, count: categories.length, data: categories });
  } catch (error) {
    next(error);
  }
};

exports.getCategoryById = async (req, res, next) => {
  try {
    const [categories] = await req.db.query(
      `SELECT c.*, COUNT(m.id) as menu_count
       FROM category c
       LEFT JOIN menu m ON c.id = m.category_id
       WHERE c.id = ?
       GROUP BY c.id`,
      [req.params.id]
    );
    if (categories.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, data: categories[0] });
  } catch (error) {
    next(error);
  }
};

exports.createCategory = async (req, res, next) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
    }
    const [result] = await req.db.query('INSERT INTO category (name) VALUES (?)', [name]);
    res.status(201).json({ success: true, message: 'Category created', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateCategory = async (req, res, next) => {
  try {
    const { name } = req.body;
    const [result] = await req.db.query('UPDATE category SET name = ? WHERE id = ?', [name, req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, message: 'Category updated' });
  } catch (error) {
    next(error);
  }
};

exports.deleteCategory = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM category WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, message: 'Category deleted' });
  } catch (error) {
    next(error);
  }
};
