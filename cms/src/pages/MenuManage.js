import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
  rust: '#C2452F',
};

const fmtRp = (n) => `Rp ${Number(n || 0).toLocaleString('id-ID')}`;

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

export default function MenuManagePage({ apiUrl, token, userRole }) {
  const [menu, setMenu] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [editing, setEditing] = useState(null); // null | menuItem

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchMenu = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/api/menu`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) setMenu(json.data || []);
    } catch (e) {
      /* ignore */
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { fetchMenu(); }, [fetchMenu]);

  const filtered = menu.filter((m) => {
    const q = filter.toLowerCase();
    if (!q) return true;
    return (m.item_name || '').toLowerCase().includes(q) || (m.category_name || '').toLowerCase().includes(q);
  });

  const savePrice = async (item, nextPrice) => {
    try {
      const res = await fetch(`${apiUrl}/api/menu/${item.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ price: Number(nextPrice) }),
      });
      const json = await res.json();
      if (json && json.success) {
        setEditing(null);
        fetchMenu();
      } else {
        alert(json?.message || 'Failed to update');
      }
    } catch (e) {
      alert('Could not reach API');
    }
  };

  const toggleAvailability = async (item) => {
    try {
      const next = item.is_available === 0 || item.is_available === false ? 1 : 0;
      const res = await fetch(`${apiUrl}/api/menu/${item.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ is_available: next }),
      });
      const json = await res.json();
      if (json && json.success) fetchMenu();
      else alert(json?.message || 'Failed to update');
    } catch (e) {
      alert('Could not reach API');
    }
  };

  return (
    <div data-testid="cms-manage-page">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Menu Management</h3>
          <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
            Direct view of the <code>menu</code> table. Edit prices or toggle availability per item.
          </p>
        </div>
        <input
          data-testid="menu-search"
          type="text"
          placeholder="Search by name or category…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{ padding: '10px 14px', borderRadius: 10, border: `1px solid ${palette.parchment}`, minWidth: 260, fontSize: 13 }}
        />
      </div>

      <div style={card}>
        {loading ? (
          <div style={{ color: '#777' }}>Loading menu…</div>
        ) : filtered.length === 0 ? (
          <div data-testid="menu-empty" style={{ color: '#777', textAlign: 'center', padding: '24px 0' }}>No menu items match.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '10px 6px' }}>ID</th>
                <th style={{ padding: '10px 6px' }}>Item</th>
                <th style={{ padding: '10px 6px' }}>Category</th>
                <th style={{ padding: '10px 6px', textAlign: 'right' }}>Price</th>
                <th style={{ padding: '10px 6px' }}>Available</th>
                {userRole === 'admin' && <th style={{ padding: '10px 6px' }}>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {filtered.map((item) => (
                <tr key={item.id} data-testid={`menu-row-${item.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                  <td style={{ padding: '10px 6px', color: '#999' }}>#{item.id}</td>
                  <td style={{ padding: '10px 6px', fontWeight: 600, color: palette.ink }}>{item.item_name}</td>
                  <td style={{ padding: '10px 6px', color: '#666' }}>{item.category_name || '—'}</td>
                  <td style={{ padding: '10px 6px', textAlign: 'right' }}>
                    {editing && editing.id === item.id ? (
                      <input
                        data-testid={`menu-price-input-${item.id}`}
                        type="number"
                        defaultValue={item.price}
                        autoFocus
                        onKeyDown={(e) => { if (e.key === 'Enter') savePrice(item, e.currentTarget.value); if (e.key === 'Escape') setEditing(null); }}
                        onBlur={(e) => savePrice(item, e.currentTarget.value)}
                        style={{ width: 110, padding: 6, borderRadius: 6, border: `1px solid ${palette.moss}`, textAlign: 'right' }}
                      />
                    ) : (
                      <span
                        style={{ cursor: userRole === 'admin' ? 'pointer' : 'default', fontWeight: 700 }}
                        onClick={() => userRole === 'admin' && setEditing(item)}
                        title={userRole === 'admin' ? 'Click to edit' : ''}
                      >
                        {fmtRp(item.price)}
                      </span>
                    )}
                  </td>
                  <td style={{ padding: '10px 6px' }}>
                    <span
                      data-testid={`menu-available-${item.id}`}
                      style={{
                        display: 'inline-block', padding: '4px 10px', borderRadius: 999,
                        background: item.is_available === 0 ? '#FEE' : '#E7F3D9',
                        color: item.is_available === 0 ? palette.rust : palette.moss,
                        fontWeight: 700, fontSize: 11,
                      }}
                    >
                      {item.is_available === 0 ? 'Hidden' : 'Available'}
                    </span>
                  </td>
                  {userRole === 'admin' && (
                    <td style={{ padding: '10px 6px' }}>
                      <button
                        data-testid={`menu-toggle-${item.id}`}
                        onClick={() => toggleAvailability(item)}
                        style={{ padding: '6px 12px', borderRadius: 8, border: `1px solid ${palette.moss}`, background: 'white', color: palette.moss, cursor: 'pointer', fontWeight: 700, fontSize: 12 }}
                      >
                        {item.is_available === 0 ? 'Show' : 'Hide'}
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
