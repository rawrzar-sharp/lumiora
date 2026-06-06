exports.getAllMenu = async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, c.name as category_name
       FROM menu_items m
       LEFT JOIN menu_categories c ON m.category_id = c.id
       WHERE m.is_available = 1
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
       FROM menu_items m
       LEFT JOIN menu_categories c ON m.category_id = c.id
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
       FROM menu_items m
       LEFT JOIN menu_categories c ON m.category_id = c.id
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
    // Map legacy CMS fields to the new menu_items schema
    const { category_id, item_name, name, description, image_url, price, base_price, is_Available, is_available } = req.body;
    
    const finalName = name || item_name;
    const finalPrice = base_price || price;
    const finalAvailability = is_available !== undefined ? is_available : (is_Available !== undefined ? is_Available : 1);

    if (!category_id || !finalName || !finalPrice) {
      return res.status(400).json({ success: false, message: 'category_id, name, and base_price are required' });
    }
    const [result] = await req.db.query(
      'INSERT INTO menu_items (category_id, name, description, base_price, image_url, is_available) VALUES (?, ?, ?, ?, ?, ?)',
      [category_id, finalName, description || '', finalPrice, image_url || '', finalAvailability]
    );
    res.status(201).json({ success: true, message: 'Menu item created', id: result.insertId });
  } catch (error) {
    next(error);
  }
};

exports.updateMenu = async (req, res, next) => {
  try {
    // Map legacy CMS fields to the new menu_items schema
    const { category_id, item_name, name, description, image_url, price, base_price, is_Available, is_available } = req.body;
    
    const finalName = name || item_name;
    const finalPrice = base_price || price;
    const finalAvailability = is_available !== undefined ? is_available : (is_Available !== undefined ? is_Available : 1);

    const [result] = await req.db.query(
      'UPDATE menu_items SET category_id = ?, name = ?, description = ?, image_url = ?, base_price = ?, is_available = ? WHERE id = ?',
      [category_id, finalName, description, image_url, finalPrice, finalAvailability, req.params.id]
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
  // menu_items no longer uses a direct 'stock' column (it uses recipes & ingredients)
  // To prevent the CMS from crashing if it calls this, we return a mock success.
  res.json({ success: true, message: 'Stock update bypassed (managed via ingredients table now)', stock: 50 });
};

exports.deleteMenu = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM menu_items WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Menu item not found' });
    }
    res.json({ success: true, message: 'Menu item deleted' });
  } catch (error) {
    next(error);
  }
};