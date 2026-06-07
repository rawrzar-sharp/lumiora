// We LEFT JOIN the canonical `menu_items` table to pull in `customization_options`
// (a JSON column added in the 2026_06 migration). This is what the Flutter app
// needs to render the "Customize" bottom-sheet (preferences + addons) on the
// menu and cart pages. The legacy `menu` table stays the source of truth for
// price/name to avoid breaking the CMS that still reads it.
exports.getAllMenu = async (req, res, next) => {
  try {
    const [menu] = await req.db.query(
      `SELECT m.*, m.is_Available AS is_available, c.name as category_name, mi.customization_options
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       LEFT JOIN menu_items mi ON mi.id = m.id
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
      `SELECT m.*, m.is_Available AS is_available, c.name as category_name, mi.customization_options
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       LEFT JOIN menu_items mi ON mi.id = m.id
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
      `SELECT m.*, m.is_Available AS is_available, c.name as category_name, mi.customization_options
       FROM menu m
       LEFT JOIN category c ON m.category_id = c.id
       LEFT JOIN menu_items mi ON mi.id = m.id
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
    const { category_id, item_name, description, image_url, price, stock, is_Available, is_available } = req.body;
    // Use COALESCE so the CMS can send a single field (e.g. {price: 50000}) and
    // every other column keeps its current value. is_Available is the legacy
    // camel-cased column name; we also accept the lowercase variant.
    const finalAvail = is_Available !== undefined ? is_Available : is_available;
    const [result] = await req.db.query(
      `UPDATE menu SET
         category_id  = COALESCE(?, category_id),
         item_name    = COALESCE(?, item_name),
         description  = COALESCE(?, description),
         image_url    = COALESCE(?, image_url),
         price        = COALESCE(?, price),
         stock        = COALESCE(?, stock),
         is_Available = COALESCE(?, is_Available)
       WHERE id = ?`,
      [category_id ?? null, item_name ?? null, description ?? null, image_url ?? null,
       price ?? null, stock ?? null, finalAvail ?? null, req.params.id]
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
