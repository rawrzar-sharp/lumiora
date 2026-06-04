exports.getAllMenu = async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, c.name as category_name
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       ORDER BY m.id`
    );
    res.json({ success: true, count: menu.length, data: menu });
  } catch (error) {
    next(error);
  }
};

exports.getMenuById = async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, c.name as category_name
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       WHERE m.id = ?`,
      [req.params.id]
    );
    if (menu.length === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }
    res.json({ success: true, data: menu[0] });
  } catch (error) {
    next(error);
  }
};

exports.getMenuByCategory = async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, c.name as category_name
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       WHERE m.category_id = ?
       ORDER BY m.id`,
      [req.params.categoryId]
    );
    res.json({ success: true, count: menu.length, data: menu });
  } catch (error) {
    next(error);
  }
};

exports.createMenu = async (req, res, next) => {
  try {
    const { category_id, item_name, description, image_url, price, stock, is_Available } = req.body;
    if (!category_id || !item_name || !price) {
      return res.status(400).json({ success: false, message: 'category_id, item_name, and price are required' });
    }
    const [result] = await req.db.query(
      'INSERT INTO menu (category_id, item_name, description, image_url, price, stock, is_Available) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [category_id, item_name, description || '', image_url || '', price, stock ?? 0, is_Available !== undefined ? is_Available : 1]
    );
    res.status(201).json({ success: true, message: 'Menu item created', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateMenu = async (req, res, next) => {
  try {
    const { category_id, item_name, description, image_url, price, stock, is_Available } = req.body;
    const [result] = await req.db.query(
      'UPDATE menu SET category_id = ?, item_name = ?, description = ?, image_url = ?, price = ?, stock = ?, is_Available = ? WHERE id = ?',
      [category_id, item_name, description, image_url, price, stock, is_Available, req.params.id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }
    res.json({ success: true, message: 'Menu item updated' });
  } catch (error) {
    next(error);
  }
};

exports.updateStock = async (req, res, next) => {
  try {
    const { stock, delta } = req.body;
    const [current] = await req.db.query('SELECT stock FROM menu WHERE id = ?', [req.params.id]);

    if (current.length === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }

    const currentStock = Number(current[0].stock || 0);
    const nextStock = Number.isFinite(Number(stock))
      ? Number(stock)
      : currentStock + Number(delta || 0);

    const safeStock = Math.max(0, nextStock);

    await req.db.query('UPDATE menu SET stock = ? WHERE id = ?', [safeStock, req.params.id]);

    res.json({ success: true, message: 'Stock updated', stock: safeStock });
  } catch (error) {
    next(error);
  }
};

exports.deleteMenu = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM menu WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }
    res.json({ success: true, message: 'Menu item deleted' });
  } catch (error) {
    next(error);
  }
};
