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

// =====================================================================
// Admin dashboard overview — one round-trip for the Dashboard tab.
// Returns today's revenue, today's order count, queue counts by status,
// number of customers, and the 5 most recent orders. Everything is read
// from the live tables so the dashboard reflects the actual database.
// =====================================================================
exports.getDashboardSummary = async (req, res, next) => {
  try {
    const [[todayRow]] = await db.query(
      `SELECT
         COALESCE(SUM(total_amount), 0)            AS revenue_today,
         COUNT(*)                                  AS orders_today
       FROM orders
       WHERE DATE(created_at) = CURDATE()`
    );

    const [[totalsRow]] = await db.query(
      `SELECT
         COUNT(*)                                                                 AS orders_total,
         COALESCE(SUM(total_amount), 0)                                           AS revenue_total,
         SUM(CASE WHEN order_status = 'pending'    THEN 1 ELSE 0 END)             AS queue_pending,
         SUM(CASE WHEN order_status = 'preparing'  THEN 1 ELSE 0 END)             AS queue_preparing,
         SUM(CASE WHEN order_status = 'ready'      THEN 1 ELSE 0 END)             AS queue_ready,
         SUM(CASE WHEN order_status = 'delivered'  THEN 1 ELSE 0 END)             AS queue_done
       FROM orders`
    );

    const [[customersRow]] = await db.query(`SELECT COUNT(*) AS total FROM customer`);
    const [[lowStockRow]]  = await db.query(
      `SELECT COUNT(*) AS total FROM ingredients
        WHERE stock_quantity <= low_stock_threshold`
    );

    const [recent] = await db.query(
      `SELECT o.id, o.order_number, o.order_status, o.order_type,
              o.total_amount, o.created_at,
              c.name AS customer_name
         FROM orders o
         LEFT JOIN customer c ON o.customer_id = c.id
         ORDER BY o.created_at DESC
         LIMIT 5`
    );

    const [topItems] = await db.query(
      `SELECT m.id, m.item_name,
              SUM(oi.quantity)                  AS qty_sold,
              SUM(oi.quantity * oi.price_at_sale) AS revenue
         FROM order_items oi
         JOIN menu m ON m.id = oi.menu_item_id
         GROUP BY m.id, m.item_name
         ORDER BY qty_sold DESC
         LIMIT 5`
    );

    res.json({
      success: true,
      data: {
        revenue_today:    Number(todayRow.revenue_today)    || 0,
        orders_today:     Number(todayRow.orders_today)     || 0,
        orders_total:     Number(totalsRow.orders_total)    || 0,
        revenue_total:    Number(totalsRow.revenue_total)   || 0,
        queue_pending:    Number(totalsRow.queue_pending)   || 0,
        queue_preparing:  Number(totalsRow.queue_preparing) || 0,
        queue_ready:      Number(totalsRow.queue_ready)     || 0,
        queue_done:       Number(totalsRow.queue_done)      || 0,
        customers_total:  Number(customersRow.total)        || 0,
        low_stock_count:  Number(lowStockRow.total)         || 0,
        recent_orders:    recent,
        top_items:        topItems,
      },
    });
  } catch (error) {
    next(error);
  }
};
