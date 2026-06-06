const db = require('../config/db');

exports.getOrdersLog = async (req, res, next) => {
  try {
    // Check if orders table has a customer_id column
    const [[colInfo]] = await db.query("SELECT COUNT(*) as cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='orders' AND COLUMN_NAME='customer_id'");
    let orders;
    if (colInfo.cnt > 0) {
      [orders] = await db.query(
        `SELECT o.id, o.order_number, o.order_type, o.total_amount, o.order_status, o.created_at,
          c.name AS customer_name
         FROM orders o
         LEFT JOIN customer c ON o.customer_id = c.id
         WHERE (? IS NULL OR o.order_status = ?)
         ORDER BY o.created_at DESC`,
        [req.query.status || null, req.query.status || null]
      );
    } else {
      [orders] = await db.query(
        `SELECT id, order_number, order_type, total_amount, order_status, created_at
         FROM orders
         WHERE (? IS NULL OR order_status = ?)
         ORDER BY created_at DESC`,
        [req.query.status || null, req.query.status || null]
      );
    }
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

exports.getNotifications = async (req, res, next) => {
  try {
    // Recent orders for notification
    const limit = parseInt(req.query.limit) || 10;
    const [rows] = await db.query(
      `SELECT id, order_number, order_status, created_at FROM orders ORDER BY created_at DESC LIMIT ?`,
      [limit]
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getIngredients = async (req, res, next) => {
  try {
    const [ingredients] = await db.query('SELECT * FROM ingredients ORDER BY name');
    res.json({ success: true, count: ingredients.length, data: ingredients });
  } catch (error) {
    next(error);
  }
};

exports.getLowIngredients = async (req, res, next) => {
  try {
    const [rows] = await db.query('SELECT * FROM ingredients WHERE stock_quantity <= low_stock_threshold ORDER BY stock_quantity ASC');
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getRecipes = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT r.menu_item_id, mi.name as menu_name,
        JSON_ARRAYAGG(JSON_OBJECT('ingredient_id', i.id, 'ingredient_name', i.name, 'quantity_required', r.quantity_required)) as recipe
       FROM recipes r
       JOIN menu_items mi ON r.menu_item_id = mi.id
       JOIN ingredients i ON r.ingredient_id = i.id
       GROUP BY r.menu_item_id, mi.name`);
    // parse JSON strings returned by MySQL into objects
    const parsed = rows.map(r => ({ menu_item_id: r.menu_item_id, menu_name: r.menu_name, recipe: JSON.parse(r.recipe) }));
    res.json({ success: true, count: parsed.length, data: parsed });
  } catch (error) {
    next(error);
  }
};

exports.getRecipeByMenu = async (req, res, next) => {
  try {
    const menuId = req.params.id;
    const [rows] = await db.query(
      `SELECT r.*, i.name as ingredient_name FROM recipes r JOIN ingredients i ON r.ingredient_id = i.id WHERE r.menu_item_id = ?`,
      [menuId]
    );
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.updateIngredientStock = async (req, res, next) => {
  try {
    const { ingredient_id, amount, set } = req.body;
    if (!ingredient_id || amount == null) return res.status(400).json({ success: false, message: 'ingredient_id and amount required' });
    if (set === true) {
      await db.query('UPDATE ingredients SET stock_quantity = ? WHERE id = ?', [amount, ingredient_id]);
    } else {
      await db.query('UPDATE ingredients SET stock_quantity = stock_quantity + ? WHERE id = ?', [amount, ingredient_id]);
    }
    const [rows] = await db.query('SELECT * FROM ingredients WHERE id = ?', [ingredient_id]);
    res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
};

exports.getDailySales = async (req, res, next) => {
  try {
    const [rows] = await db.query('SELECT report_date, total_sales FROM report_daily_sales ORDER BY report_date DESC LIMIT 90');
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getMonthlySales = async (req, res, next) => {
  try {
    // Aggregate from orders table if total_amount exists
    const [col] = await db.query("SELECT COUNT(*) as cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='orders' AND COLUMN_NAME='total_amount'");
    if (col[0].cnt > 0) {
      const [rows] = await db.query(`SELECT YEAR(created_at) as year, MONTH(created_at) as month, SUM(total_amount) as total_sales FROM orders GROUP BY YEAR(created_at), MONTH(created_at) ORDER BY year DESC, month DESC LIMIT 36`);
      return res.json({ success: true, count: rows.length, data: rows });
    }
    res.json({ success: false, message: 'orders.total_amount column not present' });
  } catch (error) {
    next(error);
  }
};
