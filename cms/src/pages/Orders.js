import React, { useEffect, useState } from 'react';

export default function OrdersPage({ apiUrl, token }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!apiUrl) return;
    setLoading(true);
    fetch(`${apiUrl}/api/cms/orders`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json())
      .then(d => { if (d && d.success) setOrders(d.data || []); })
      .catch(()=>{})
      .finally(() => setLoading(false));
  }, [apiUrl, token]);

  return (
    <div>
      <h3>Orders</h3>
      {loading && <p>Loading...</p>}
      {!loading && (
        <table>
          <thead>
            <tr><th>Order ID</th><th>Customer</th><th>Status</th><th>Total</th></tr>
          </thead>
          <tbody>
            {orders.length ? orders.map(o => (
              <tr key={o.id || o.order_id}>
                <td>{o.id || o.order_id}</td>
                <td>{o.customer_name || o.customer || '-'}</td>
                <td>{o.status || o.order_status || '-'}</td>
                <td>{o.total_amount || o.total || 0}</td>
              </tr>
            )) : (
              <tr><td colSpan="4">No orders found</td></tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
