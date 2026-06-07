import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';

// Coherent palette with the rest of the Lumiora CMS.
const palette = {
  cream: '#FBF8F1',
  ink: '#1F2117',
  moss: '#7B8C2A',
  mossDeep: '#5E6D1F',
  parchment: '#EFEAD8',
  amber: '#C28840',
  rust: '#C2452F',
};

// pending / preparing / ready / delivered / cancelled — display labels & next step
const STATUS_META = {
  pending: { label: 'New', tone: palette.amber, next: 'preparing', nextLabel: 'Start preparing' },
  preparing: { label: 'In Kitchen', tone: palette.moss, next: 'ready', nextLabel: 'Mark Ready' },
  ready: { label: 'Ready', tone: '#3B7A5A', next: 'delivered', nextLabel: 'Mark as Done' },
  delivered: { label: 'Done', tone: '#7280B2', next: null, nextLabel: null },
  cancelled: { label: 'Cancelled', tone: '#9B9B9B', next: null, nextLabel: null },
};

const fmtRp = (n) => `Rp ${Number(n || 0).toLocaleString('id-ID')}`;

const cardStyle = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

export default function OrdersPage({ apiUrl, token }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [lowStock, setLowStock] = useState([]);
  const [filter, setFilter] = useState('active'); // active | done | all
  const [busyId, setBusyId] = useState(null);

  const authHeaders = useMemo(
    () => (token ? { Authorization: `Bearer ${token}` } : {}),
    [token]
  );

  const fetchOrders = useCallback(async () => {
    if (!apiUrl) return;
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/api/orders`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) setOrders(json.data || []);
    } catch (e) {
      // swallow — show empty state
    } finally {
      setLoading(false);
    }
  }, [apiUrl, authHeaders]);

  const fetchLowStock = useCallback(async () => {
    if (!apiUrl) return;
    try {
      const res = await fetch(`${apiUrl}/api/cms/ingredients/low`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) setLowStock(json.data || []);
    } catch (e) {
      /* ignore */
    }
  }, [apiUrl, authHeaders]);

  // Keep latest fetchers in refs so the polling effect doesn't re-create the
  // interval on every render (and avoids triggering react-hooks/set-state-in-effect).
  const fetchOrdersRef = useRef(fetchOrders);
  const fetchLowStockRef = useRef(fetchLowStock);
  useEffect(() => {
    fetchOrdersRef.current = fetchOrders;
    fetchLowStockRef.current = fetchLowStock;
  }, [fetchOrders, fetchLowStock]);

  useEffect(() => {
    fetchOrdersRef.current();
    fetchLowStockRef.current();
    // Poll every 8s so a freshly-paid order appears without manual refresh.
    const t = setInterval(() => {
      fetchOrdersRef.current();
      fetchLowStockRef.current();
    }, 8000);
    return () => clearInterval(t);
  }, []);

  const advanceStatus = async (order, nextStatus) => {
    setBusyId(order.id);
    try {
      const res = await fetch(`${apiUrl}/api/orders/${order.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ order_status: nextStatus }),
      });
      const json = await res.json();
      if (json && json.success) {
        await fetchOrders();
        if (Array.isArray(json.low_stock_alerts) && json.low_stock_alerts.length) {
          setLowStock((prev) => {
            const next = [...prev];
            for (const alert of json.low_stock_alerts) {
              if (!next.find((p) => p.id === alert.ingredient_id)) {
                next.push({ ...alert, id: alert.ingredient_id });
              }
            }
            return next;
          });
        } else {
          fetchLowStock();
        }
      } else {
        alert(json?.message || 'Failed to update order status');
      }
    } catch (e) {
      alert('Could not reach API');
    } finally {
      setBusyId(null);
    }
  };

  const cancelOrder = async (order) => {
    if (!window.confirm(`Cancel order ${order.order_number || order.id}?`)) return;
    await advanceStatus(order, 'cancelled');
  };

  const filtered = useMemo(() => {
    if (filter === 'all') return orders;
    if (filter === 'done') return orders.filter((o) => o.order_status === 'delivered' || o.order_status === 'cancelled');
    return orders.filter((o) => !['delivered', 'cancelled'].includes(o.order_status));
  }, [orders, filter]);

  return (
    <div data-testid="cms-orders-page" style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) 320px', gap: 24 }}>
      {/* MAIN COLUMN */}
      <section>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <h3 style={{ margin: 0, color: palette.ink, fontWeight: 800, fontSize: 22 }}>Kitchen Orders</h3>
            <p style={{ margin: '4px 0 0', color: '#6b6b6b', fontSize: 13 }}>
              Auto-refreshes every 8 seconds. Mark each order through its lifecycle.
            </p>
          </div>
          <div data-testid="orders-filter" style={{ display: 'flex', gap: 6, background: palette.parchment, padding: 4, borderRadius: 999 }}>
            {[
              { id: 'active', label: 'Active' },
              { id: 'done', label: 'Completed' },
              { id: 'all', label: 'All' },
            ].map((opt) => (
              <button
                key={opt.id}
                data-testid={`filter-${opt.id}-btn`}
                onClick={() => setFilter(opt.id)}
                style={{
                  padding: '8px 16px',
                  borderRadius: 999,
                  border: 'none',
                  cursor: 'pointer',
                  fontWeight: 700,
                  fontSize: 12,
                  background: filter === opt.id ? palette.moss : 'transparent',
                  color: filter === opt.id ? 'white' : palette.ink,
                  transition: 'background 0.2s',
                }}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {loading && orders.length === 0 ? (
          <div style={{ ...cardStyle, textAlign: 'center', color: '#6b6b6b' }}>Loading orders…</div>
        ) : filtered.length === 0 ? (
          <div data-testid="orders-empty" style={{ ...cardStyle, textAlign: 'center', color: '#6b6b6b', padding: '40px 20px' }}>
            No orders in this view yet. New orders show up here as soon as a customer pays.
          </div>
        ) : (
          <div style={{ display: 'grid', gap: 14 }}>
            {filtered.map((order) => {
              const meta = STATUS_META[order.order_status] || STATUS_META.pending;
              const items = Array.isArray(order.items) ? order.items : [];
              return (
                <article
                  key={order.id}
                  data-testid={`order-card-${order.id}`}
                  style={{ ...cardStyle }}
                >
                  <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                    <div>
                      <div style={{ fontSize: 11, color: '#888', letterSpacing: 1, textTransform: 'uppercase' }}>
                        {order.order_type === 'dine_in' ? 'Dine in' : 'Takeaway'} • #{order.id}
                      </div>
                      <h4 style={{ margin: '4px 0 0', color: palette.ink, fontSize: 18 }}>
                        {order.order_number || `ORD-${order.id}`}
                      </h4>
                      <div style={{ fontSize: 12, color: '#666', marginTop: 2 }}>
                        Customer: {order.customer_name || `#${order.customer_id}`}
                      </div>
                    </div>
                    <div
                      data-testid={`order-status-${order.id}`}
                      style={{
                        background: meta.tone,
                        color: 'white',
                        padding: '6px 14px',
                        borderRadius: 999,
                        fontSize: 12,
                        fontWeight: 800,
                        letterSpacing: 0.5,
                      }}
                    >
                      {meta.label}
                    </div>
                  </header>

                  {items.length > 0 && (
                    <ul style={{ listStyle: 'none', padding: 0, margin: '14px 0 0' }}>
                      {items.map((it, idx) => (
                        <li
                          key={idx}
                          style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px dashed #EFE7D2', fontSize: 14 }}
                        >
                          <span>
                            <strong>{it.quantity}x</strong> {it.item_name || `Item #${it.menu_item_id}`}
                          </span>
                          <span style={{ color: '#6b6b6b' }}>{fmtRp(it.price_at_sale)}</span>
                        </li>
                      ))}
                    </ul>
                  )}

                  <footer style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16, gap: 10, flexWrap: 'wrap' }}>
                    <div>
                      <div style={{ fontSize: 11, color: '#999' }}>Total</div>
                      <div style={{ fontSize: 20, fontWeight: 900, color: palette.ink }}>{fmtRp(order.total_amount || order.total)}</div>
                    </div>

                    <div style={{ display: 'flex', gap: 8 }}>
                      {meta.next && (
                        <button
                          data-testid={`advance-${order.id}-btn`}
                          disabled={busyId === order.id}
                          onClick={() => advanceStatus(order, meta.next)}
                          style={{
                            background: palette.moss,
                            color: 'white',
                            border: 'none',
                            padding: '10px 18px',
                            borderRadius: 10,
                            fontWeight: 700,
                            cursor: 'pointer',
                            opacity: busyId === order.id ? 0.6 : 1,
                          }}
                        >
                          {busyId === order.id ? '…' : meta.nextLabel}
                        </button>
                      )}
                      {!['delivered', 'cancelled'].includes(order.order_status) && (
                        <button
                          data-testid={`cancel-${order.id}-btn`}
                          disabled={busyId === order.id}
                          onClick={() => cancelOrder(order)}
                          style={{
                            background: 'transparent',
                            color: palette.rust,
                            border: `1.5px solid ${palette.rust}`,
                            padding: '10px 14px',
                            borderRadius: 10,
                            fontWeight: 700,
                            cursor: 'pointer',
                          }}
                        >
                          Cancel
                        </button>
                      )}
                    </div>
                  </footer>
                </article>
              );
            })}
          </div>
        )}
      </section>

      {/* SIDEBAR — LOW STOCK ALERTS */}
      <aside data-testid="low-stock-panel">
        <div style={{ ...cardStyle, background: lowStock.length ? '#FFF5E5' : 'white', borderColor: lowStock.length ? palette.amber : palette.parchment }}>
          <h4 style={{ margin: 0, color: palette.ink, fontSize: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 8, height: 8, borderRadius: '50%', background: lowStock.length ? palette.rust : '#9CC471' }} />
            Low ingredient alerts
          </h4>
          <p style={{ fontSize: 12, color: '#6b6b6b', margin: '6px 0 14px' }}>
            {lowStock.length
              ? `${lowStock.length} item${lowStock.length > 1 ? 's' : ''} at or below threshold. Re-stock before service resumes.`
              : 'All ingredients are above their threshold. You\'re good to serve.'}
          </p>
          {lowStock.length > 0 && (
            <ul data-testid="low-stock-list" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
              {lowStock.map((ing) => (
                <li
                  key={ing.id}
                  style={{ padding: '10px 0', borderTop: '1px solid #F2E7CF', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                >
                  <div>
                    <div style={{ fontWeight: 700, color: palette.ink, fontSize: 13 }}>{ing.name}</div>
                    <div style={{ fontSize: 11, color: '#6b6b6b' }}>
                      threshold {Number(ing.low_stock_threshold).toLocaleString('id-ID')} {ing.unit || ''}
                    </div>
                  </div>
                  <div style={{ color: palette.rust, fontWeight: 800, fontSize: 14 }}>
                    {Number(ing.stock_quantity).toLocaleString('id-ID')} {ing.unit || ''}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </aside>
    </div>
  );
}
