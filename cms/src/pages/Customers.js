import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
};

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

export default function CustomersPage({ apiUrl, token }) {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchCustomers = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/api/customers`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) setCustomers(json.data || []);
    } catch (e) {
      /* ignore */
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { fetchCustomers(); }, [fetchCustomers]);

  const filtered = customers.filter((c) => {
    const q = filter.toLowerCase();
    if (!q) return true;
    return (c.name || '').toLowerCase().includes(q) || (c.phone || '').toLowerCase().includes(q);
  });

  const fmtDate = (s) => {
    if (!s) return '—';
    try { return new Date(s).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }); }
    catch (e) { return s; }
  };

  return (
    <div data-testid="cms-customers-page">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Customers</h3>
          <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
            Live list pulled from the <code>customer</code> table.
          </p>
        </div>
        <input
          data-testid="customers-search"
          type="text"
          placeholder="Search by name or phone…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{ padding: '10px 14px', borderRadius: 10, border: `1px solid ${palette.parchment}`, minWidth: 260, fontSize: 13 }}
        />
      </div>

      <div style={card}>
        {loading ? (
          <div style={{ color: '#777' }}>Loading customers…</div>
        ) : filtered.length === 0 ? (
          <div data-testid="customers-empty" style={{ color: '#777', textAlign: 'center', padding: '24px 0' }}>No customers found.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '10px 6px' }}>ID</th>
                <th style={{ padding: '10px 6px' }}>Name</th>
                <th style={{ padding: '10px 6px' }}>Phone</th>
                <th style={{ padding: '10px 6px' }}>Birthday</th>
                <th style={{ padding: '10px 6px' }}>Joined</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c) => (
                <tr key={c.id} data-testid={`customer-row-${c.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                  <td style={{ padding: '10px 6px', color: '#999' }}>#{c.id}</td>
                  <td style={{ padding: '10px 6px', fontWeight: 600, color: palette.ink }}>{c.name}</td>
                  <td style={{ padding: '10px 6px', color: '#666' }}>{c.phone || '—'}</td>
                  <td style={{ padding: '10px 6px', color: '#666' }}>{fmtDate(c.birthday)}</td>
                  <td style={{ padding: '10px 6px', color: '#666' }}>{fmtDate(c.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
