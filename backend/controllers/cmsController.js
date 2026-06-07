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

// =====================================================================
// Menu availability — for each menu item, walk its recipe and mark the
// item as `low_ingredient` if ANY required ingredient is at or below its
// low_stock_threshold. The CMS shows this beside the Stock card so staff
// instantly know which drinks need attention.
// =====================================================================
exports.getMenuAvailability = async (req, res, next) => {
  try {
    const [items] = await db.query(
      `SELECT m.id, m.item_name, m.is_Available AS is_available, m.price,
              c.name AS category_name
         FROM menu m
         LEFT JOIN category c ON c.id = m.category_id
         ORDER BY c.name, m.id`
    );
    const [recipeRows] = await db.query(
      `SELECT r.menu_item_id,
              i.id AS ingredient_id, i.name AS ingredient_name,
              i.stock_quantity, i.low_stock_threshold, i.unit,
              r.quantity_required
         FROM recipes r
         JOIN ingredients i ON i.id = r.ingredient_id`
    );

    const byMenu = new Map();
    for (const r of recipeRows) {
      const list = byMenu.get(r.menu_item_id) || [];
      const isLow = Number(r.stock_quantity) <= Number(r.low_stock_threshold);
      list.push({
        ingredient_id: r.ingredient_id,
        ingredient_name: r.ingredient_name,
        stock_quantity: Number(r.stock_quantity),
        low_stock_threshold: Number(r.low_stock_threshold),
        unit: r.unit,
        quantity_required: Number(r.quantity_required),
        is_low: isLow,
      });
      byMenu.set(r.menu_item_id, list);
    }

    const data = items.map((m) => {
      const recipe = byMenu.get(m.id) || [];
      const lowIngredients = recipe.filter((r) => r.is_low);
      let availability = 'available';
      if (Number(m.is_available) === 0) availability = 'hidden';
      else if (lowIngredients.length > 0) availability = 'low_ingredient';
      return {
        id: m.id,
        item_name: m.item_name,
        category_name: m.category_name,
        price: Number(m.price),
        is_available: Number(m.is_available),
        availability,
        low_ingredients: lowIngredients,
        recipe_size: recipe.length,
      };
    });

    res.json({ success: true, count: data.length, data });
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
    // Derive daily revenue from the live `orders` table so it stays in sync
    // with monthly sales (previously this read from the static seed table
    // `report_daily_sales`, which produced ghost rows that didn't match the
    // monthly total).
    const [rows] = await db.query(
      `SELECT DATE(created_at) AS report_date,
              COALESCE(SUM(total_amount), 0) AS total_sales,
              COUNT(*) AS orders_count
         FROM orders
        WHERE order_status <> 'cancelled'
          AND created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
        GROUP BY DATE(created_at)
        ORDER BY report_date DESC`
    );
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getMonthlySales = async (req, res, next) => {
  try {
    const [col] = await db.query("SELECT COUNT(*) as cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='orders' AND COLUMN_NAME='total_amount'");
    if (col[0].cnt > 0) {
      // Match the daily query: exclude cancelled orders so the totals line up
      // (a cancelled order should not appear in the monthly revenue either).
      const [rows] = await db.query(
        `SELECT YEAR(created_at) AS year,
                MONTH(created_at) AS month,
                COALESCE(SUM(total_amount), 0) AS total_sales,
                COUNT(*) AS orders_count
           FROM orders
          WHERE order_status <> 'cancelled'
          GROUP BY YEAR(created_at), MONTH(created_at)
          ORDER BY year DESC, month DESC
          LIMIT 36`
      );
      return res.json({ success: true, count: rows.length, data: rows });
    }
    res.json({ success: false, message: 'orders.total_amount column not present' });
  } catch (error) {
    next(error);
  }
};

// =====================================================================
// Sales pipeline analytics
//   - Total sales per day                       (already covered by getDailySales)
//   - Total sales per day per item              ← getItemSalesDaily
//   - Total quantity sold per day per item      ← (same row in getItemSalesDaily)
//   - Total quantity ordered per hour per day   ← getHourlyVolume
// =====================================================================
exports.getItemSalesDaily = async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.days || 30), 365);
    const [rows] = await db.query(
      `SELECT DATE(o.created_at) AS report_date,
              oi.menu_item_id,
              COALESCE(mi.name, CONCAT('Item #', oi.menu_item_id)) AS item_name,
              SUM(oi.quantity)                              AS qty_sold,
              SUM(oi.quantity * oi.price_at_sale)           AS revenue
         FROM orders o
         JOIN order_items oi ON oi.order_id = o.id
         LEFT JOIN menu_items mi ON mi.id = oi.menu_item_id
        WHERE o.order_status <> 'cancelled'
          AND o.created_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        GROUP BY DATE(o.created_at), oi.menu_item_id, mi.name
        ORDER BY report_date DESC, qty_sold DESC`,
      [limit]
    );
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    next(error);
  }
};

exports.getHourlyVolume = async (req, res, next) => {
  try {
    // ?date=YYYY-MM-DD (defaults to today). Returns 24 rows even for hours
    // with zero orders, so a chart can render a full day on the x-axis.
    const date = (req.query.date || '').slice(0, 10);
    const dateFilter = date && /^\d{4}-\d{2}-\d{2}$/.test(date) ? date : null;

    const [rows] = await db.query(
      `SELECT HOUR(created_at)                AS hour_of_day,
              SUM(quantity_per_order)         AS total_qty,
              COUNT(*)                        AS total_orders
         FROM (
           SELECT o.id, o.created_at,
                  (SELECT COALESCE(SUM(oi.quantity), 0)
                     FROM order_items oi WHERE oi.order_id = o.id) AS quantity_per_order
             FROM orders o
            WHERE o.order_status <> 'cancelled'
              AND DATE(o.created_at) = COALESCE(?, CURDATE())
         ) AS t
        GROUP BY HOUR(created_at)
        ORDER BY hour_of_day`,
      [dateFilter]
    );

    // Fill in any missing hours with zeros so the dashboard chart stays full.
    const byHour = new Map();
    for (const r of rows) byHour.set(Number(r.hour_of_day), r);
    const padded = [];
    for (let h = 0; h < 24; h++) {
      const r = byHour.get(h);
      padded.push({
        hour_of_day: h,
        total_qty:    Number(r ? r.total_qty    : 0),
        total_orders: Number(r ? r.total_orders : 0),
      });
    }
    res.json({ success: true, date: dateFilter || 'today', data: padded });
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
