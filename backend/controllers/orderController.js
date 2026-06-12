// Map mobile-facing payment-method labels to the ENUM values used in the DB.
function normalizePaymentMethod(input) {
  if (!input) return 'qris';
  const v = String(input).toLowerCase();
  if (v.includes('qris') || v.includes('e-wallet') || v.includes('gopay') || v.includes('ovo') || v.includes('shopee')) return 'qris';
  if (v.includes('debit') || v.includes('bank')) return 'debit';
  if (v.includes('credit') || v.includes('cc')) return 'cc';
  if (v.includes('cashier') || v.includes('cash')) return 'cashier';
  return 'qris';
}

function normalizeOrderType(input) {
  if (!input) return 'takeaway';
  const v = String(input).toLowerCase().replace(/\s|-/g, '_');
  if (v.includes('dine')) return 'dine_in';
  return 'takeaway';
}

async function resolveCustomerId(db, customerId) {
  if (!customerId) return null;
  const [rows] = await db.query('SELECT id FROM customer WHERE id = ? LIMIT 1', [customerId]);
  if (rows.length > 0) return rows[0].id;

  // Fallback: maybe a stale token sent users.id - try to find linked customer
  const [linked] = await db.query('SELECT id FROM customer WHERE user_id = ? LIMIT 1', [customerId]);
  if (linked.length > 0) return linked[0].id;

  return null;
}

exports.getOrders = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.*, c.name as customer_name
       FROM orders o
       LEFT JOIN customer c ON o.customer_id = c.id
       ORDER BY o.created_at DESC`
    );
    // attach items for each order
    for (const order of orders) {
      const [items] = await req.db.query(
        `SELECT oi.*, m.item_name, m.image_url
         FROM order_items oi
         LEFT JOIN menu m ON oi.menu_item_id = m.id
         WHERE oi.order_id = ?`,
        [order.id]
      );
      order.items = items;
    }
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

exports.getOrderById = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.*, c.name as customer_name
       FROM orders o
       LEFT JOIN customer c ON o.customer_id = c.id
       WHERE o.id = ?`,
      [req.params.id]
    );
    if (orders.length === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    const order = orders[0];
    const [items] = await req.db.query(
      `SELECT oi.*, m.item_name, m.image_url
       FROM order_items oi
       LEFT JOIN menu m ON oi.menu_item_id = m.id
       WHERE oi.order_id = ?`,
      [order.id]
    );
    order.items = items;
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

exports.getOrdersByCustomer = async (req, res, next) => {
  try {
    const [orders] = await req.db.query(
      `SELECT o.* FROM orders o WHERE o.customer_id = ? ORDER BY o.created_at DESC`,
      [req.params.customerId]
    );
    for (const order of orders) {
      const [items] = await req.db.query(
        `SELECT oi.*, m.item_name, m.image_url
         FROM order_items oi
         LEFT JOIN menu m ON oi.menu_item_id = m.id
         WHERE oi.order_id = ?`,
        [order.id]
      );
      order.items = items.map((it) => ({
        ...it,
        // present a friendly label for the mobile history page
        label: it.item_name ? `${it.quantity}x ${it.item_name}` : `${it.quantity}x Item #${it.menu_item_id}`,
      }));
    }
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

exports.createOrder = async (req, res) => {
  const conn = await req.db.getConnection();
  try {
    const {
      customer_id,
      items, // [{ id, quantity, basePrice|price, selectedAddons, selectedSpice, ... }]
      menu_id, // legacy single-item shape
      quantity,
      order_type,
      payment_method,
      total,
      total_amount,
      ice_level,
      sugar_level,
      order_number,
    } = req.body;

    const resolvedCustomerId = await resolveCustomerId(conn, customer_id);
    if (!resolvedCustomerId) {
      return res.status(400).json({
        success: false,
        message: `Invalid customer_id: ${customer_id}. Please login again so the app can resync your profile.`,
      });
    }

    const finalOrderNumber = order_number || `ORD-${Math.floor(100000 + Math.random() * 900000)}`;
    const normalizedPayment = normalizePaymentMethod(payment_method);
    const normalizedOrderType = normalizeOrderType(order_type);
    const grandTotal = Number(total_amount ?? total ?? 0);

    // Pre-compute items list for the new normalized shape.
    let normalizedItems = [];
    if (Array.isArray(items) && items.length > 0) {
      normalizedItems = items.map((it) => {
        const id = it.id ?? it.menu_id ?? it.menu_item_id;
        const qty = Number(it.quantity ?? 1);
        let price = Number(it.basePrice ?? it.price ?? 0);
        const addonOpts = it.addonOptions || {};
        const selected = Array.isArray(it.selectedAddons) ? it.selectedAddons : [];
        for (const a of selected) {
          price += Number(addonOpts[a] ?? 0);
        }
        // selectedPreferences is the new multi-axis map (Ice Level / Sugar Level / …).
        // Fall back to the legacy selectedSpice string so old carts still work.
        let prefs = it.selectedPreferences || it.preferences || null;
        if (!prefs && (it.selectedSpice !== undefined && it.selectedSpice !== null && it.selectedSpice !== '')) {
          prefs = { Preference: String(it.selectedSpice) };
        }
        return {
          menu_item_id: id,
          quantity: qty,
          price_at_sale: price,
          preferences_json: prefs && Object.keys(prefs).length ? prefs : null,
          addons_json: selected.length ? selected : null,
          notes: it.notes || null,
        };
      });
    } else if (menu_id) {
      normalizedItems = [{ menu_item_id: menu_id, quantity: Number(quantity || 1), price_at_sale: grandTotal, preferences_json: null, addons_json: null, notes: null }];
    }

    // Pull the first item to fill the legacy columns (menu_id, quantity, etc.) for
    // backwards compatibility with the CMS pages that still read them.
    const firstItem = normalizedItems[0] || {};

    await conn.beginTransaction();

    const insertSql = `
      INSERT INTO orders
      (customer_id, menu_id, quantity, order_type, payment_method, total, total_amount,
       ice_level, sugar_level, order_number, order_status, payment_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending_verification')
    `;
    const insertValues = [
      resolvedCustomerId,
      firstItem.menu_item_id || null,
      firstItem.quantity || null,
      normalizedOrderType,
      normalizedPayment,
      grandTotal,
      grandTotal,
      ice_level || null,
      sugar_level || null,
      finalOrderNumber,
    ];
    const [orderResult] = await conn.query(insertSql, insertValues);
    const orderId = orderResult.insertId;

    // Insert order_items (FK to menu_items table). We silently skip items whose
    // menu_item_id doesn't exist in menu_items, so cart entries created from the
    // legacy `menu` table don't blow up the entire order.
    for (const it of normalizedItems) {
      const [exists] = await conn.query('SELECT id FROM menu_items WHERE id = ? LIMIT 1', [it.menu_item_id]);
      if (exists.length === 0) continue;
      try {
        await conn.query(
          `INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_sale, preferences_json, addons_json, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            orderId,
            it.menu_item_id,
            it.quantity,
            it.price_at_sale,
            it.preferences_json ? JSON.stringify(it.preferences_json) : null,
            it.addons_json      ? JSON.stringify(it.addons_json)      : null,
            it.notes || null,
          ]
        );
      } catch (err) {
        if (err && err.code === 'ER_BAD_FIELD_ERROR') {
          await conn.query(
            `INSERT INTO order_items (order_id, menu_item_id, quantity, price_at_sale)
             VALUES (?, ?, ?, ?)`,
            [orderId, it.menu_item_id, it.quantity, it.price_at_sale]
          );
        } else {
          throw err;
        }
      }
    }

    await conn.commit();

    res.status(201).json({
      success: true,
      id: orderId,
      order_number: finalOrderNumber,
      customer_id: resolvedCustomerId,
      total_amount: grandTotal,
      payment_method: normalizedPayment,
      order_type: normalizedOrderType,
      order_status: 'pending',
    });
  } catch (error) {
    try { await conn.rollback(); } catch (_) { /* nothing to rollback */ }
    console.error('Create Order Error (Internal):', error);
    res.status(500).json({ 
      success: false, 
      error: "Connection lost or server busy. Please try again!" 
    });
  } finally {
    conn.release();
  }
};

exports.updateOrder = async (req, res, next) => {
  const conn = await req.db.getConnection();
  try {
    const { quantity, ice_level, sugar_level, order_status, payment_status } = req.body;
    const now = new Date().toISOString().slice(0, 19).replace('T', ' ');

    await conn.beginTransaction();

    // Read current status so we only decrement stock once on the
    // pending → preparing transition.
    const [prev] = await conn.query('SELECT id, order_status FROM orders WHERE id = ?', [req.params.id]);
    if (prev.length === 0) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    const previousStatus = prev[0].order_status;

    const [result] = await conn.query(
      `UPDATE orders SET quantity = COALESCE(?, quantity), ice_level = COALESCE(?, ice_level),
       sugar_level = COALESCE(?, sugar_level), order_status = COALESCE(?, order_status),
       payment_status = COALESCE(?, payment_status),
       modified_at = ? WHERE id = ?`,
      [quantity, ice_level, sugar_level, order_status, payment_status, now, req.params.id]
    );
    if (result.affectedRows === 0) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // 🍳 Stock decrement: when the kitchen actually starts preparing the order,
    // consume the ingredients required by every line item via the `recipes`
    // table. We only do this on the first transition into 'preparing' to
    // prevent double-decrementing on subsequent status flips.
    const lowAlerts = [];
    if (order_status === 'preparing' && previousStatus !== 'preparing'
        && previousStatus !== 'ready' && previousStatus !== 'delivered') {
      const [items] = await conn.query(
        'SELECT menu_item_id, quantity FROM order_items WHERE order_id = ?',
        [req.params.id]
      );
      for (const oi of items) {
        const [recipeRows] = await conn.query(
          'SELECT ingredient_id, quantity_required FROM recipes WHERE menu_item_id = ?',
          [oi.menu_item_id]
        );
        for (const r of recipeRows) {
          const consumed = Number(r.quantity_required) * Number(oi.quantity);
          await conn.query(
            'UPDATE ingredients SET stock_quantity = GREATEST(stock_quantity - ?, 0) WHERE id = ?',
            [consumed, r.ingredient_id]
          );
          const [[after]] = await conn.query(
            'SELECT id, name, stock_quantity, low_stock_threshold FROM ingredients WHERE id = ?',
            [r.ingredient_id]
          );
          if (after && Number(after.stock_quantity) <= Number(after.low_stock_threshold)) {
            lowAlerts.push({
              ingredient_id: after.id,
              name: after.name,
              stock_quantity: after.stock_quantity,
              low_stock_threshold: after.low_stock_threshold,
            });
          }
        }
      }
    }

    await conn.commit();
    res.json({ success: true, message: 'Order updated', low_stock_alerts: lowAlerts });
  } catch (error) {
    try { await conn.rollback(); } catch (_) { /* nothing to rollback */ }
    next(error);
  } finally {
    conn.release();
  }
};

exports.deleteOrder = async (req, res, next) => {
  try {
    const [result] = await req.db.query('DELETE FROM orders WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, message: 'Order deleted' });
  } catch (error) {
    next(error);
  }
};
