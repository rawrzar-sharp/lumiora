import React, { useEffect, useState, useCallback } from 'react';

const palette = {
  cream: '#FBF8F1',
  ink: '#1F2117',
  moss: '#7B8C2A',
  mossDeep: '#5E6D1F',
  parchment: '#EFEAD8',
  amber: '#C28840',
  rust: '#C2452F',
  teal: '#3B7A5A',
};

const fmtRp = (n) => `Rp ${Number(n || 0).toLocaleString('id-ID')}`;

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

function StatTile({ label, value, accent, sub, testId }) {
  return (
    <div data-testid={testId} style={{ ...card, borderTop: `4px solid ${accent}` }}>
      <div style={{ fontSize: 12, color: '#777', textTransform: 'uppercase', letterSpacing: 1, fontWeight: 700 }}>{label}</div>
      <div style={{ fontSize: 26, fontWeight: 900, color: palette.ink, marginTop: 6 }}>{value}</div>
      {sub && <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>{sub}</div>}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Status pill — used by the staff order list so the kitchen instantly knows
// what to do with each order (New = start cooking, Cooking = in progress,
// Ready = hand to customer, Delivered = done, Cancelled = ignore).
// ---------------------------------------------------------------------------
function StatusPill({ status }) {
  const map = {
    pending:   { bg: '#FFF1D6', fg: '#8A5A12', label: 'New' },
    preparing: { bg: '#E4EBC1', fg: '#5E6D1F', label: 'Cooking' },
    ready:     { bg: '#D6E9DD', fg: '#1F5A3C', label: 'Ready' },
    delivered: { bg: '#E8E6DE', fg: '#5F5B4E', label: 'Delivered' },
    cancelled: { bg: '#F5D7D1', fg: '#8C2A1E', label: 'Cancelled' },
  };
  const s = map[(status || '').toLowerCase()] || { bg: '#EEE', fg: '#333', label: status || '-' };
  return (
    <span style={{
      background: s.bg, color: s.fg, padding: '4px 10px', borderRadius: 999,
      fontSize: 11, fontWeight: 800, textTransform: 'uppercase', letterSpacing: 0.5,
    }}>{s.label}</span>
  );
}

// ---------------------------------------------------------------------------
// Staff-only dashboard. Hides money, surfaces operational signals the kitchen
// actually needs: how many orders are sitting in each kitchen lane, who's the
// next order to start, which ingredients are running low, and a contextual
// "what to do now" hint.
// ---------------------------------------------------------------------------
function StaffDashboard({ summary, userName }) {
  const newCount    = summary.queue_pending   || 0;
  const cookingCount = summary.queue_preparing || 0;
  const readyCount  = summary.queue_ready     || 0;
  const lowStock    = summary.low_stock_count || 0;

  // Pick the most urgent active order (newest pending → preparing → ready).
  const activeOrders = (summary.recent_orders || [])
    .filter((o) => ['pending', 'preparing', 'ready'].includes((o.order_status || '').toLowerCase()));

  // Friendly next-action hint at the top of the page.
  let hint;
  if (newCount > 0)        hint = { tone: palette.amber, text: `You have ${newCount} new order${newCount === 1 ? '' : 's'} waiting to be started.` };
  else if (cookingCount > 0) hint = { tone: palette.moss,  text: `${cookingCount} order${cookingCount === 1 ? ' is' : 's are'} being prepared right now.` };
  else if (readyCount > 0)   hint = { tone: palette.teal,  text: `${readyCount} order${readyCount === 1 ? ' is' : 's are'} ready to hand over.` };
  else                       hint = { tone: palette.mossDeep, text: 'Kitchen is clear. Great job — nothing in the queue right now.' };

  return (
    <div data-testid="staff-dashboard" style={{ display: 'grid', gap: 18 }}>
      {/* Greeting + next-action hint */}
      <div data-testid="staff-greeting" style={{
        ...card,
        borderLeft: `5px solid ${hint.tone}`,
        background: '#FCFBF6',
      }}>
        <div style={{ fontSize: 12, color: '#888', textTransform: 'uppercase', letterSpacing: 1, fontWeight: 700 }}>
          Hi, {userName || 'Staff'} — Kitchen Today
        </div>
        <div data-testid="staff-hint" style={{ fontSize: 18, color: palette.ink, marginTop: 6, fontWeight: 700 }}>
          {hint.text}
        </div>
      </div>

      {/* Kitchen lane tiles — no money, just what's in the queue */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 14 }}>
        <StatTile testId="staff-stat-new"      label="New Orders"  value={newCount}     accent={palette.amber}    sub="Waiting to be started" />
        <StatTile testId="staff-stat-cooking"  label="Cooking"     value={cookingCount} accent={palette.moss}     sub="Being prepared now" />
        <StatTile testId="staff-stat-ready"    label="Ready"       value={readyCount}   accent={palette.teal}     sub="Ready to hand over" />
        <StatTile testId="staff-stat-today"    label="Orders Today" value={summary.orders_today || 0} accent={palette.mossDeep} sub="Closed + still open" />
        <StatTile testId="staff-stat-lowstock" label="Low Stock"   value={lowStock}     accent={palette.rust}     sub="Ingredients to restock" />
      </div>

      {/* Live active queue */}
      <section data-testid="staff-active-queue" style={card}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Active Queue</h3>
          <span style={{ fontSize: 12, color: '#888' }}>{activeOrders.length} order{activeOrders.length === 1 ? '' : 's'} in progress</span>
        </div>
        <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>Tap the Orders tab to update status. List auto-refreshes every 15s.</p>
        {activeOrders.length === 0 ? (
          <div style={{ padding: '24px 0', color: '#999', fontSize: 13 }}>Nothing in the queue. ✨</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: 8, fontSize: 13 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '8px 4px' }}>Order</th>
                <th style={{ padding: '8px 4px' }}>Customer</th>
                <th style={{ padding: '8px 4px' }}>Type</th>
                <th style={{ padding: '8px 4px' }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {activeOrders.map((o) => (
                <tr key={o.id} data-testid={`staff-queue-row-${o.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                  <td style={{ padding: '10px 4px', fontWeight: 700, color: palette.ink }}>{o.order_number || `ORD-${o.id}`}</td>
                  <td style={{ padding: '10px 4px' }}>{o.customer_name || `#${o.customer_id || '-'}`}</td>
                  <td style={{ padding: '10px 4px', textTransform: 'capitalize' }}>{(o.order_type || '').replace('_', ' ')}</td>
                  <td style={{ padding: '10px 4px' }}><StatusPill status={o.order_status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {/* Low stock — same data as admin, but framed as a to-do list */}
      <section data-testid="staff-low-stock" style={card}>
        <h3 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Restock Watchlist</h3>
        <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>
          {lowStock === 0
            ? 'All ingredients are above their low-stock threshold.'
            : `${lowStock} ingredient${lowStock === 1 ? '' : 's'} need${lowStock === 1 ? 's' : ''} attention — open the Menu / Stock tab to update counts.`}
        </p>
      </section>
    </div>
  );
}

export default function DashboardPage({ apiUrl, token, userRole, userName }) {
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState('');

  const fetchSummary = useCallback(async () => {
    if (!apiUrl) return;
    try {
      const res = await fetch(`${apiUrl}/api/cms/dashboard/summary`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      const json = await res.json();
      if (json && json.success) {
        setSummary(json.data);
        setErr('');
      } else {
        setErr(json.message || 'Failed to load dashboard');
      }
    } catch (e) {
      setErr('Could not reach the API');
    } finally {
      setLoading(false);
    }
  }, [apiUrl, token]);

  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    fetchSummary();
    const t = setInterval(fetchSummary, 15000);
    return () => clearInterval(t);
  }, [fetchSummary]);
  /* eslint-enable react-hooks/set-state-in-effect */

  if (loading) return <div data-testid="dashboard-loading" style={card}>Loading dashboard…</div>;
  if (err)     return <div data-testid="dashboard-error" style={{ ...card, color: palette.rust }}>{err}</div>;
  if (!summary) return null;

  // Staff get an operational view (no revenue numbers, kitchen-first layout).
  if (userRole === 'staff') {
    return <StaffDashboard summary={summary} userName={userName} />;
  }

  // Admin keeps the full revenue/insights view it always had.
  return (
    <div data-testid="cms-dashboard-page" style={{ display: 'grid', gap: 18 }}>
      {/* TOP STAT TILES */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 14 }}>
        <StatTile testId="stat-revenue-today" label="Revenue Today"    value={fmtRp(summary.revenue_today)}   accent={palette.moss}  sub={`${summary.orders_today} orders today`} />
        <StatTile testId="stat-revenue-total" label="Lifetime Revenue" value={fmtRp(summary.revenue_total)}   accent={palette.mossDeep} sub={`${summary.orders_total} total orders`} />
        <StatTile testId="stat-queue-active"  label="Active In Kitchen" value={`${summary.queue_pending + summary.queue_preparing + summary.queue_ready}`} accent={palette.amber}
                  sub={`New ${summary.queue_pending} · Cooking ${summary.queue_preparing} · Ready ${summary.queue_ready} (orders waiting / being prepared / ready to hand over)`} />
        <StatTile testId="stat-customers"     label="Customers"        value={summary.customers_total}        accent={palette.teal} sub="Total registered" />
        <StatTile testId="stat-low-stock"     label="Low Stock"        value={summary.low_stock_count}        accent={palette.rust}  sub="ingredients to restock" />
      </div>

      {/* TWO COLUMN: recent orders + top items */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.6fr) minmax(0, 1fr)', gap: 18 }}>
        {/* RECENT */}
        <section data-testid="recent-orders" style={card}>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Recent Orders</h3>
          <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>Last 5 orders, newest first.</p>
          {summary.recent_orders.length === 0 ? (
            <div style={{ padding: '24px 0', color: '#999', fontSize: 13 }}>No orders yet.</div>
          ) : (
            <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: 8, fontSize: 13 }}>
              <thead>
                <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                  <th style={{ padding: '8px 4px' }}>Order</th>
                  <th style={{ padding: '8px 4px' }}>Customer</th>
                  <th style={{ padding: '8px 4px' }}>Type</th>
                  <th style={{ padding: '8px 4px' }}>Status</th>
                  <th style={{ padding: '8px 4px', textAlign: 'right' }}>Total</th>
                </tr>
              </thead>
              <tbody>
                {summary.recent_orders.map((o) => (
                  <tr key={o.id} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                    <td style={{ padding: '10px 4px', fontWeight: 700, color: palette.ink }}>{o.order_number || `ORD-${o.id}`}</td>
                    <td style={{ padding: '10px 4px' }}>{o.customer_name || `#${o.customer_id || '-'}`}</td>
                    <td style={{ padding: '10px 4px', textTransform: 'capitalize' }}>{(o.order_type || '').replace('_', ' ')}</td>
                    <td style={{ padding: '10px 4px', textTransform: 'capitalize' }}>{o.order_status}</td>
                    <td style={{ padding: '10px 4px', textAlign: 'right', fontWeight: 700 }}>{fmtRp(o.total_amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>

        {/* TOP ITEMS */}
        <section data-testid="top-items" style={card}>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Top Selling Items</h3>
          <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>Across every order in the database.</p>
          {summary.top_items.length === 0 ? (
            <div style={{ padding: '24px 0', color: '#999', fontSize: 13 }}>No sales yet.</div>
          ) : (
            <ol style={{ paddingLeft: 18, margin: 0 }}>
              {summary.top_items.map((it) => (
                <li key={it.id} style={{ padding: '8px 0', borderBottom: `1px dashed ${palette.parchment}` }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                    <span style={{ fontWeight: 600 }}>{it.item_name}</span>
                    <span style={{ color: palette.moss, fontWeight: 800 }}>{it.qty_sold}x</span>
                  </div>
                  <div style={{ fontSize: 11, color: '#888' }}>{fmtRp(it.revenue)}</div>
                </li>
              ))}
            </ol>
          )}
        </section>
      </div>
    </div>
  );
}
