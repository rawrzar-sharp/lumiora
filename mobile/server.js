const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Perbaikan: Cukup panggil CORS sekali
app.use(cors({ origin: "*" }));
app.use(express.json());
app.use('/images', express.static('assets/images'));

// Initialize MySQL Database Connection Pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'lumiora',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

console.log(`[server] DB_HOST=${process.env.DB_HOST || '127.0.0.1'} DB_PORT=${process.env.DB_PORT || 3306} DB_NAME=${process.env.DB_NAME || 'lumiora'}`);

// Helper: Generate Unique Order Number (Menghasilkan Hex asli jika diinginkan)
function generateOrderNumber() {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    // Menghasilkan nilai acak berbasis Hex agar sesuai dengan nama variabelnya
    const randomHex = Math.floor(4096 + Math.random() * 61440).toString(16).toUpperCase(); 
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

  // Perbaikan: deklarasikan variabel di luar, isi di dalam try-catch
  let connection;
  
  try {
    connection = await pool.getConnection(); // Lebih aman di dalam blok try
    await connection.beginTransaction();
    const orderNumber = generateOrderNumber();

    const [orderResult] = await connection.execute(
      `INSERT INTO orders (order_number, order_type, payment_method, payment_status, order_status, total_amount)
       VALUES (?, ?, ?, 'pending_verification', 'pending', ?)`,
      [orderNumber, order_type, payment_method, total_amount]
    );
    const insertId = orderResult.insertId;

    // Perbaikan: Pastikan kolom di database Anda sanggup menyimpan text/JSON jika ingin mencatat customizations
    const itemInsertQuery = `
      INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_sale, customizations) 
      VALUES (?, ?, ?, ?, ?)
    `;
    
    for (const item of items) {
      const menuItemId = item.menu_item_id ?? null;
      const qty        = item.quantity ?? 1;
      const price      = item.price_at_sale ?? item.price ?? 0;
      
      // Ambil objek kustomisasi dari Flutter payload
      const customizations = item.customizations ? JSON.stringify(item.customizations) : null;

      if (menuItemId == null) {
        throw new Error(`Missing menu_item_id for item: ${JSON.stringify(item)}`);
      }
      
      // Eksekusi query dengan menyertakan string kustomisasi JSON
      await connection.execute(itemInsertQuery, [insertId, menuItemId, qty, price, customizations]);
    }

    await connection.commit();
    res.status(201).json({
      success: true,
      message: "Order placed successfully",
      order_id: insertId,
      order_number: orderNumber
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error("Order Transaction Error:", error);
    res.status(500).json({ success: false, error: error.message || "Internal Database Server Error" });
  } finally {
    if (connection) connection.release();
  }
});

// GET Customer Order History
app.get('/api/orders/customer/:customerId', async (req, res) => {
  const customerId = req.params.customerId;

  try {
    // 1. Get all orders for this customer
    const [orders] = await pool.execute(`
      SELECT id, order_number, order_status, total_amount, created_at 
      FROM orders 
      WHERE customer_id = ? 
      ORDER BY created_at DESC
    `, [customerId]);

    if (orders.length === 0) {
      return res.status(200).json({ success: true, data: [] });
    }

    // 2. Format the response and fetch items for each order
    const formattedOrders = [];

    for (let order of orders) {
      // Get the items inside this specific order
      const [items] = await pool.execute(`
        SELECT oi.quantity, mi.name 
        FROM order_items oi
        JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id = ?
      `, [order.id]);

      // Determine if active or completed based on your CMS flow
      // 'delivered', 'ready', 'cancelled' count as History. 
      // 'pending', 'preparing' count as Active.
      let displayStatus = 'Ongoing';
      if (order.order_status === 'delivered' || order.order_status === 'ready') displayStatus = 'success';
      if (order.order_status === 'cancelled') displayStatus = 'cancelled';

      formattedOrders.push({
        id: order.order_number,
        total: order.total_amount,
        order_status: displayStatus,
        created_at: order.created_at, // Send raw timestamp, let Flutter parse it
        items: items.map(i => `${i.quantity}x ${i.name}`) // e.g., ["2x Latte", "1x Croissant"]
      });
    }

    res.status(200).json({ success: true, data: formattedOrders });

  } catch (error) {
    console.error("History Fetch Error:", error);
    res.status(500).json({ success: false, error: "Internal Server Error" });
  }
});

// =========================================================================
// DEMO STEP 2: Feed Pending Orders to the Web CMS Layout
// =========================================================================
app.get('/api/orders/pending', async (req, res) => {
    try {
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
                oi.customizations,
                mi.name AS item_name,
                mc.printer_target
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            JOIN menu_categories mc ON mi.category_id = mc.id
            WHERE o.order_status = 'pending'
            ORDER BY o.created_at ASC
        `);

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
            
            // Parsing kembali teks kustomisasi JSON dari database jika ada
            let customObj = null;
            try { if (current.customizations) customObj = JSON.parse(current.customizations); } catch(e){}

            order.items.push({
                name: current.item_name,
                quantity: current.quantity,
                price: current.price_at_sale,
                station: current.printer_target,
                customizations: customObj
            });
            return acc;
        }, []);

        res.status(200).json({ success: true, orders: formattedOrders });
    } catch (error) {
        console.error("Fetch Pending Error:", error);
        res.status(500).json({ success: false, error: "Internal Server Error" });
    }
});

// Endpoint Fetch Menu Data back to Flutter
app.get('/api/menu', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM menu_items WHERE is_available = 1');
    console.log(`[/api/menu] returned ${rows.length} rows`);
    // Normalize image_url so clients can easily resolve to /images/<basename>
    const normalized = rows.map(r => {
      try {
        const img = r.image_url || '';
        if (typeof img === 'string' && img.length > 0) {
          if (img.startsWith('http')) {
            r.image_url = img;
          } else {
            // extract basename
            const parts = img.split('/');
            const base = parts.length ? parts[parts.length - 1] : img;
            r.image_url = `/images/${base}`;
          }
        } else {
          r.image_url = '';
        }
      } catch (e) {
        // ignore
      }
      return r;
    });

    res.status(200).json({ success: true, menu: normalized });
  } catch (error) {
    console.error("Menu Fetch Error:", error);
    res.status(500).json({ success: false, error: error.message, code: error.code });
  }
});

// Unified Login / Sign Up Endpoint
app.post('/api/auth', async (req, res) => {
    const { name, contactInfo, password } = req.body;
    
    if (!contactInfo || !password) {
        return res.status(400).json({ success: false, message: "Please provide contact info and password" });
    }

    // Map contactInfo from Flutter to the email column in the DB
    const email = contactInfo; 

    try {
        const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [email]);

        if (rows.length > 0) {
            const user = rows[0];
            // Validating existing user using bcrypt
            const match = await bcrypt.compare(password, user.password_hash); // Fix: use password_hash
            if (match) {
                // Do not return password field
                const { password_hash: _, ...safeUser } = user;
                console.log(`[auth] successful login for ${email}`);
                res.status(200).json({ success: true, message: "Welcome back to Lumiora!", user: safeUser });
            } else {
                console.log(`[auth] failed login (wrong password) for ${email}`);
                res.status(401).json({ success: false, message: "Incorrect password for this account." });
            }
        } else {
            // New user validation & creation (hash password)
            const newName = name && name.trim() !== '' ? name : 'Valued Guest';
            const hashed = await bcrypt.hash(password, 10);
            const [result] = await pool.execute(
                'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)',
                [newName, email, hashed]
            );
            const [newUserRows] = await pool.execute('SELECT id, name, email, role, created_at FROM users WHERE id = ?', [result.insertId]);
            const newUser = newUserRows[0] || null;
            console.log(`[auth] created new user id=${result.insertId} email=${email}`);
            res.status(201).json({ success: true, message: "Welcome to the Lumiora family!", user: newUser });
        }
    } catch (error) {
        console.error("Auth Error:", error);
        res.status(500).json({ success: false, error: "Internal Server Error" });
    }
});

// Start the service
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Lumiora Cloud API Engine running locally on port ${PORT}`);
});