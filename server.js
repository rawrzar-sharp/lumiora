const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Initialize MySQL Database Connection Pool
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Helper: Generate Unique Order Number matching presentation requirements
function generateOrderNumber() {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randomHex = Math.floor(1000 + Math.random() * 9000);
    return `LUM-${today}-${randomHex}`;
}

// =========================================================================
// DEMO STEP 1: Receive Order from Phone App (Frontend)
// =========================================================================
app.post('/api/orders', async (req, res) => {
  const { order_type, payment_method, total_amount, items } = req.body;

  if (!order_type || !payment_method || total_amount == null || !items || !items.length) {
    return res.status(400).json({ success: false, error: "Missing required order payloads" });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const orderNumber = generateOrderNumber();

    const [orderResult] = await connection.execute(
      `INSERT INTO orders (order_number, order_type, payment_method, payment_status, order_status, total_amount)
       VALUES (?, ?, ?, 'pending_verification', 'pending', ?)`,
      [orderNumber, order_type, payment_method, total_amount]
    );
    const insertId = orderResult.insertId;

    const itemInsertQuery = `INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_sale) VALUES (?, ?, ?, ?)`;
    for (const item of items) {
      // Defensive: fallback ke null bukan undefined supaya driver tidak crash
      const menuItemId = item.menu_item_id ?? null;
      const qty        = item.quantity ?? 1;
      const price      = item.price_at_sale ?? item.price ?? 0;  // backward compatible

      if (menuItemId == null) {
        throw new Error(`Missing menu_item_id for item: ${JSON.stringify(item)}`);
      }
      await connection.execute(itemInsertQuery, [insertId, menuItemId, qty, price]);
    }

    await connection.commit();
    res.status(201).json({
      success: true,
      message: "Order placed successfully",
      order_id: insertId,
      order_number: orderNumber
    });
  } catch (error) {
    await connection.rollback();
    console.error("Order Transaction Error:", error);
    res.status(500).json({ success: false, error: error.message || "Internal Database Server Error" });
  } finally {
    connection.release();
  }
});

// =========================================================================
// DEMO STEP 2: Feed Pending Orders to the Web CMS Layout
// =========================================================================
app.get('/api/orders/pending', async (req, res) => {
    try {
        // Fetch pending orders, joining with categories to help staff identify printer targets
        const [rows] = await pool.execute(`
            SELECT 
                o.id AS order_id,
                o.order_number,
                o.order_type,
                o.payment_method,
                o.order_status,
                o.total_amount,
                o.created_at,
                oi.quantity,
                oi.price_at_sale,
                mi.name AS item_name,
                mc.printer_target
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            JOIN menu_categories mc ON mi.category_id = mc.id
            WHERE o.order_status = 'pending'
            ORDER BY o.created_at ASC
        `);

        // Format SQL rows into flat, clean JSON objects for the frontend developer
        const formattedOrders = rows.reduce((acc, current) => {
            let order = acc.find(o => o.order_id === current.order_id);
            if (!order) {
                order = {
                    order_id: current.order_id,
                    order_number: current.order_number,
                    order_type: current.order_type,
                    payment_method: current.payment_method,
                    order_status: current.order_status,
                    total_amount: current.total_amount,
                    created_at: current.created_at,
                    items: []
                };
                acc.push(order);
            }
            order.items.push({
                name: current.item_name,
                quantity: current.quantity,
                price: current.price_at_sale,
                station: current.printer_target
            });
            return acc;
        }, []);

        res.status(200).json({ success: true, orders: formattedOrders });
    } catch (error) {
        console.error("Fetch Pending Error:", error);
        res.status(500).json({ success: false, error: "Internal Server Error" });
    }
});

// Add this to server.js to feed dynamic menu data back to Flutter
app.get('/api/menu', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM menu_items WHERE is_available = 1');
        res.status(200).json({ success: true, menu: rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Start the service
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Lumiora Cloud API Engine running locally on port ${PORT}`);
});