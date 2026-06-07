import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  mossDeep: '#5E6D1F',
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

const inputStyle = {
  width: '100%', padding: '9px 10px', borderRadius: 8,
  border: `1px solid ${palette.parchment}`, boxSizing: 'border-box', fontSize: 13,
};

// Modal helper
function Modal({ title, onClose, children }) {
  return (
    <div data-testid="menu-modal" style={{ position: 'fixed', inset: 0, background: 'rgba(31,33,23,0.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50 }} onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()} style={{ background: 'white', borderRadius: 14, width: 'min(560px, 92vw)', padding: 24, boxShadow: '0 10px 30px rgba(0,0,0,0.2)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 18 }}>{title}</h3>
          <button data-testid="menu-modal-close" onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', fontSize: 22, color: '#888' }}>×</button>
        </div>
        {children}
      </div>
    </div>
  );
}

export default function MenuManagePage({ apiUrl, token, userRole }) {
  const [menu, setMenu] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [modal, setModal] = useState(null); // null | {mode:'create'|'edit', data}
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchMenu = useCallback(async () => {
    setLoading(true);
    try {
      const [m, c] = await Promise.all([
        fetch(`${apiUrl}/api/menu`, { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/categories`, { headers: authHeaders }).then((r) => r.json()),
      ]);
      if (m && m.success) setMenu(m.data || []);
      if (c && c.success) setCategories(c.data || []);
    } catch (e) { /* ignore */ }
    finally { setLoading(false); }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { fetchMenu(); }, [fetchMenu]);

  const filtered = menu.filter((m) => {
    const q = filter.toLowerCase();
    if (!q) return true;
    return (m.item_name || '').toLowerCase().includes(q) || (m.category_name || '').toLowerCase().includes(q);
  });

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
    } catch (e) { alert('Could not reach API'); }
  };

  const deleteItem = async (item) => {
    if (!window.confirm(`Delete "${item.item_name}"? This cannot be undone.`)) return;
    try {
      const res = await fetch(`${apiUrl}/api/menu/${item.id}`, {
        method: 'DELETE',
        headers: authHeaders,
      });
      const json = await res.json();
      if (json && json.success) {
        setMsg(`Deleted "${item.item_name}".`);
        fetchMenu();
      } else {
        alert(json?.message || 'Failed to delete');
      }
    } catch (e) { alert('Could not reach API'); }
  };

  const saveItem = async (e) => {
    e.preventDefault();
    setBusy(true);
    const f = e.target;
    const payload = {
      category_id: Number(f.category_id.value),
      item_name:   f.item_name.value.trim(),
      description: f.description.value.trim(),
      image_url:   f.image_url.value.trim(),
      price:       Number(f.price.value),
      stock:       Number(f.stock.value || 0),
      is_available: Number(f.is_available.value),
    };
    try {
      const isEdit = modal.mode === 'edit';
      const url = isEdit ? `${apiUrl}/api/menu/${modal.data.id}` : `${apiUrl}/api/menu`;
      const res = await fetch(url, {
        method: isEdit ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify(payload),
      });
      const json = await res.json();
      if (json && json.success) {
        setMsg(isEdit ? `Updated "${payload.item_name}".` : `Created "${payload.item_name}".`);
        setModal(null);
        fetchMenu();
      } else {
        alert(json?.message || 'Failed to save');
      }
    } catch (err) {
      alert('Could not reach API');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div data-testid="cms-manage-page">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Menu Manager</h3>
          <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
            Full CRUD for the <code>menu</code> table — create, edit, hide or delete items.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <input
            data-testid="menu-search"
            type="text"
            placeholder="Search by name or category…"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            style={{ padding: '10px 14px', borderRadius: 10, border: `1px solid ${palette.parchment}`, minWidth: 240, fontSize: 13 }}
          />
          {userRole === 'admin' && (
            <button
              data-testid="menu-create-btn"
              onClick={() => setModal({ mode: 'create', data: { is_available: 1, stock: 0 } })}
              style={{ background: palette.moss, color: 'white', border: 'none', padding: '10px 16px', borderRadius: 10, fontWeight: 700, cursor: 'pointer' }}
            >
              + Add menu item
            </button>
          )}
        </div>
      </div>

      {msg && (
        <div data-testid="menu-msg" style={{ background: '#E7F3D9', color: palette.mossDeep, padding: '10px 14px', borderRadius: 10, marginBottom: 14, fontSize: 13 }}>
          {msg}
        </div>
      )}

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
                  <td style={{ padding: '10px 6px', textAlign: 'right', fontWeight: 700 }}>{fmtRp(item.price)}</td>
                  <td style={{ padding: '10px 6px' }}>
                    <span data-testid={`menu-available-${item.id}`} style={{
                      display: 'inline-block', padding: '4px 10px', borderRadius: 999,
                      background: item.is_available === 0 ? '#FEE' : '#E7F3D9',
                      color: item.is_available === 0 ? palette.rust : palette.moss,
                      fontWeight: 700, fontSize: 11,
                    }}>{item.is_available === 0 ? 'Hidden' : 'Available'}</span>
                  </td>
                  {userRole === 'admin' && (
                    <td style={{ padding: '10px 6px' }}>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        <button data-testid={`menu-edit-${item.id}`}    onClick={() => setModal({ mode: 'edit', data: item })} style={{ padding: '6px 12px', borderRadius: 8, border: `1px solid ${palette.moss}`, background: 'white', color: palette.moss, cursor: 'pointer', fontWeight: 700, fontSize: 12 }}>Edit</button>
                        <button data-testid={`menu-toggle-${item.id}`}  onClick={() => toggleAvailability(item)} style={{ padding: '6px 12px', borderRadius: 8, border: `1px solid ${palette.parchment}`, background: 'white', color: palette.ink, cursor: 'pointer', fontWeight: 700, fontSize: 12 }}>{item.is_available === 0 ? 'Show' : 'Hide'}</button>
                        <button data-testid={`menu-delete-${item.id}`}  onClick={() => deleteItem(item)} style={{ padding: '6px 12px', borderRadius: 8, border: `1px solid ${palette.rust}`, background: 'white', color: palette.rust, cursor: 'pointer', fontWeight: 700, fontSize: 12 }}>Delete</button>
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {modal && (
        <Modal title={modal.mode === 'edit' ? `Edit "${modal.data.item_name}"` : 'New menu item'} onClose={() => setModal(null)}>
          <form onSubmit={saveItem} data-testid="menu-form" style={{ display: 'grid', gap: 10 }}>
            <label style={{ fontSize: 12, color: '#666' }}>
              Item name
              <input data-testid="menu-form-name" name="item_name" defaultValue={modal.data.item_name || ''} required style={inputStyle} />
            </label>
            <label style={{ fontSize: 12, color: '#666' }}>
              Category
              <select data-testid="menu-form-category" name="category_id" defaultValue={modal.data.category_id || (categories[0] && categories[0].id) || ''} required style={inputStyle}>
                {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </label>
            <label style={{ fontSize: 12, color: '#666' }}>
              Description
              <textarea data-testid="menu-form-description" name="description" defaultValue={modal.data.description || ''} rows={2} style={{ ...inputStyle, fontFamily: 'inherit', resize: 'vertical' }} />
            </label>
            <label style={{ fontSize: 12, color: '#666' }}>
              Image URL
              <input data-testid="menu-form-image" name="image_url" defaultValue={modal.data.image_url || ''} style={inputStyle} />
            </label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
              <label style={{ fontSize: 12, color: '#666' }}>
                Price (Rp)
                <input data-testid="menu-form-price" name="price" type="number" min="0" step="500" defaultValue={modal.data.price || 0} required style={inputStyle} />
              </label>
              <label style={{ fontSize: 12, color: '#666' }}>
                Stock
                <input data-testid="menu-form-stock" name="stock" type="number" min="0" defaultValue={modal.data.stock ?? 0} style={inputStyle} />
              </label>
              <label style={{ fontSize: 12, color: '#666' }}>
                Visibility
                <select data-testid="menu-form-available" name="is_available" defaultValue={modal.data.is_available !== undefined ? modal.data.is_available : 1} style={inputStyle}>
                  <option value={1}>Available</option>
                  <option value={0}>Hidden</option>
                </select>
              </label>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 6 }}>
              <button type="button" onClick={() => setModal(null)} style={{ background: 'white', border: `1px solid ${palette.parchment}`, padding: '10px 16px', borderRadius: 10, cursor: 'pointer', fontWeight: 700, fontSize: 13 }}>Cancel</button>
              <button data-testid="menu-form-submit" disabled={busy} type="submit" style={{ background: palette.moss, color: 'white', border: 'none', padding: '10px 18px', borderRadius: 10, cursor: 'pointer', fontWeight: 700, fontSize: 13 }}>
                {busy ? 'Saving…' : (modal.mode === 'edit' ? 'Save changes' : 'Create item')}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
