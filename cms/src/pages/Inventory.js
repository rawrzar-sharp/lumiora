import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
  amber: '#C28840',
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

const stepBtn = (variant) => {
  const base = { padding: '6px 10px', borderRadius: 8, border: `1px solid ${palette.parchment}`, cursor: 'pointer', fontWeight: 800, fontSize: 12, minWidth: 38 };
  if (variant === 'plus')  return { ...base, background: palette.moss, color: 'white', border: `1px solid ${palette.moss}` };
  if (variant === 'minus') return { ...base, background: '#FFF0EC', color: palette.rust, border: `1px solid ${palette.rust}` };
  return { ...base, background: 'white', color: palette.ink };
};

// Slide tab switcher: the active tab fills with primary green; the inactive
// one stays transparent so it reads as a single pill with one side filled.
const tabBtn = (active) => ({
  padding: '10px 22px',
  borderRadius: 999,
  border: 'none',
  cursor: 'pointer',
  fontWeight: 800,
  fontSize: 13,
  background: active ? palette.moss : 'transparent',
  color: active ? 'white' : palette.ink,
  transition: 'background .15s ease, color .15s ease',
});

const pill = (tone) => {
  const map = {
    ok:             { background: '#E7F3D9', color: palette.moss,  label: 'Available'       },
    low_ingredient: { background: '#FFF1D5', color: '#A06A1F',     label: 'Low ingredient'  },
    hidden:         { background: '#FEE',    color: palette.rust,  label: 'Hidden'          },
    low:            { background: '#FEE',    color: palette.rust,  label: 'Low'             },
  };
  const m = map[tone] || map.ok;
  return { display: 'inline-block', padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 800, background: m.background, color: m.color };
};

export default function InventoryPage({ apiUrl, token, userRole }) {
  const [tab, setTab] = useState('stock'); // 'stock' | 'menu'
  const [ingredients, setIngredients] = useState([]);
  const [low, setLow] = useState([]);
  const [availability, setAvailability] = useState([]);
  const [busyId, setBusyId] = useState(null);
  const [filter, setFilter] = useState('');

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchAll = useCallback(async () => {
    try {
      const [a, b, c] = await Promise.all([
        fetch(`${apiUrl}/api/cms/ingredients`,        { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/ingredients/low`,    { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/menu-availability`,  { headers: authHeaders }).then((r) => r.json()),
      ]);
      if (a && a.success) setIngredients(a.data || []);
      if (b && b.success) setLow(b.data || []);
      if (c && c.success) setAvailability(c.data || []);
    } catch (e) { /* ignore */ }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const adjust = async (it, delta) => {
    setBusyId(it.id);
    try {
      await fetch(`${apiUrl}/api/cms/ingredients/stock`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ ingredient_id: it.id, amount: delta, set: false }),
      });
      fetchAll();
    } catch (e) { /* ignore */ }
    finally { setBusyId(null); }
  };

  const setExact = async (it, value) => {
    setBusyId(it.id);
    try {
      await fetch(`${apiUrl}/api/cms/ingredients/stock`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ ingredient_id: it.id, amount: Number(value), set: true }),
      });
      fetchAll();
    } catch (e) { /* ignore */ }
    finally { setBusyId(null); }
  };

  const grouped = availability.reduce((acc, m) => {
    const cat = m.category_name || 'Uncategorised';
    (acc[cat] = acc[cat] || []).push(m);
    return acc;
  }, {});
  const filteredCategories = Object.entries(grouped).filter(([cat]) => {
    if (!filter) return true;
    return cat.toLowerCase().includes(filter.toLowerCase());
  });
  const lowAvailability = availability.filter((m) => m.availability === 'low_ingredient');

  return (
    <div data-testid="cms-inventory-page" style={{ display: 'grid', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 14, flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Menu / Stock</h3>
          <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
            Slide between <strong>Stock</strong> (raw ingredients) and <strong>Menu</strong> (per-item availability).
          </p>
        </div>
        <div
          data-testid="inventory-tabs"
          style={{ display: 'inline-flex', background: palette.parchment, padding: 4, borderRadius: 999, gap: 4 }}
        >
          <button data-testid="inv-tab-stock" onClick={() => setTab('stock')} style={tabBtn(tab === 'stock')}>Stock</button>
          <button data-testid="inv-tab-menu"  onClick={() => setTab('menu')}  style={tabBtn(tab === 'menu')}>Menu</button>
        </div>
      </div>

      {low.length > 0 && (
        <div data-testid="inv-low-banner" style={{ ...card, background: '#FFF5E5', borderColor: palette.amber }}>
          <strong style={{ color: palette.rust }}>{low.length}</strong>{' '}
          <span style={{ fontSize: 13, color: palette.ink }}>ingredient{low.length > 1 ? 's are' : ' is'} at or below the threshold</span>
          {lowAvailability.length > 0 && (
            <span style={{ fontSize: 13, color: palette.ink, marginLeft: 4 }}>
              — this affects <strong>{lowAvailability.length}</strong> menu item{lowAvailability.length > 1 ? 's' : ''}.
            </span>
          )}
        </div>
      )}

      {/* ========================= STOCK TAB ========================= */}
      {tab === 'stock' && (
      <section style={card} data-testid="inv-stock-card">
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10, flexWrap: 'wrap', gap: 6 }}>
          <h4 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Stock</h4>
          <span style={{ fontSize: 12, color: '#888' }}>{ingredients.length} ingredients</span>
        </header>
        {ingredients.length === 0 ? (
          <div data-testid="inv-stock-empty" style={{ color: '#777', textAlign: 'center', padding: '24px 0' }}>No ingredients in the database yet.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '10px 6px' }}>Ingredient</th>
                <th style={{ padding: '10px 6px', textAlign: 'right' }}>Stock</th>
                <th style={{ padding: '10px 6px', textAlign: 'right' }}>Threshold</th>
                <th style={{ padding: '10px 6px' }}>Status</th>
                {userRole === 'admin' && <>
                  <th style={{ padding: '10px 6px' }}>Adjust</th>
                  <th style={{ padding: '10px 6px' }}>Result</th>
                </>}
              </tr>
            </thead>
            <tbody>
              {ingredients.map((it) => {
                const isLow = Number(it.stock_quantity) <= Number(it.low_stock_threshold);
                return (
                  <tr key={it.id} data-testid={`inv-row-${it.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                    <td style={{ padding: '10px 6px', fontWeight: 600, color: palette.ink }}>{it.name}</td>
                    <td style={{ padding: '10px 6px', textAlign: 'right', fontWeight: 700 }}>{Number(it.stock_quantity).toLocaleString('id-ID')} {it.unit || ''}</td>
                    <td style={{ padding: '10px 6px', textAlign: 'right', color: '#666' }}>{Number(it.low_stock_threshold).toLocaleString('id-ID')} {it.unit || ''}</td>
                    <td style={{ padding: '10px 6px' }}><span style={pill(isLow ? 'low' : 'ok')}>{isLow ? 'Low' : 'OK'}</span></td>
                    {userRole === 'admin' && (
                      <>
                        <td style={{ padding: '10px 6px' }}>
                          <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                            <button data-testid={`inv-minus10-${it.id}`} disabled={busyId === it.id} onClick={() => adjust(it, -10)} style={stepBtn('minus')}>-10</button>
                            <button data-testid={`inv-minus1-${it.id}`}  disabled={busyId === it.id} onClick={() => adjust(it,  -1)} style={stepBtn('minus')}>-1</button>
                            <button data-testid={`inv-plus1-${it.id}`}   disabled={busyId === it.id} onClick={() => adjust(it,   1)} style={stepBtn('plus')}>+1</button>
                            <button data-testid={`inv-plus10-${it.id}`}  disabled={busyId === it.id} onClick={() => adjust(it,  10)} style={stepBtn('plus')}>+10</button>
                          </div>
                        </td>
                        <td style={{ padding: '10px 6px' }}>
                          <input
                            data-testid={`inv-set-${it.id}`}
                            type="number"
                            defaultValue={it.stock_quantity}
                            onKeyDown={(e) => { if (e.key === 'Enter') setExact(it, e.currentTarget.value); }}
                            style={{ width: 110, padding: 6, borderRadius: 6, border: `1px solid ${palette.parchment}`, textAlign: 'right' }}
                            title="Press Enter to set exact stock"
                          />
                        </td>
                      </>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>
      )}

      {/* ========================= MENU TAB ========================= */}
      {tab === 'menu' && (
      <section style={card} data-testid="inv-menu-card">
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10, flexWrap: 'wrap', gap: 6 }}>
          <div>
            <h4 style={{ margin: 0, color: palette.ink, fontSize: 17 }}>Menu Availability</h4>
            <span style={{ fontSize: 12, color: '#888' }}>Each item is checked against its recipe — items needing low-stock ingredients are flagged.</span>
          </div>
          <input
            data-testid="menu-availability-search"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            placeholder="Filter by category…"
            style={{ padding: '8px 12px', borderRadius: 10, border: `1px solid ${palette.parchment}`, fontSize: 13, minWidth: 220 }}
          />
        </header>

        {availability.length === 0 ? (
          <div data-testid="inv-menu-empty" style={{ color: '#777', textAlign: 'center', padding: '24px 0' }}>No menu items yet.</div>
        ) : filteredCategories.length === 0 ? (
          <div data-testid="inv-menu-noresult" style={{ color: '#777', textAlign: 'center', padding: '12px 0' }}>No categories match that filter.</div>
        ) : filteredCategories.map(([cat, items]) => (
          <div key={cat} data-testid={`menu-availability-cat-${cat.replace(/\s+/g, '-').toLowerCase()}`} style={{ marginTop: 14 }}>
            <strong style={{ color: palette.ink, fontSize: 14 }}>{cat}</strong>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, marginTop: 6 }}>
              <thead>
                <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                  <th style={{ padding: '6px 0' }}>Item</th>
                  <th style={{ padding: '6px 0', textAlign: 'right' }}>Price</th>
                  <th style={{ padding: '6px 0' }}>Status</th>
                  <th style={{ padding: '6px 0' }}>Low ingredients</th>
                </tr>
              </thead>
              <tbody>
                {items.map((m) => (
                  <tr key={m.id} data-testid={`menu-availability-${m.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                    <td style={{ padding: '8px 0', fontWeight: 600, color: palette.ink }}>#{m.id} · {m.item_name}</td>
                    <td style={{ padding: '8px 0', textAlign: 'right', fontWeight: 700 }}>{fmtRp(m.price)}</td>
                    <td style={{ padding: '8px 0' }}><span style={pill(m.availability)}>{m.availability === 'low_ingredient' ? 'Low ingredient' : m.availability === 'hidden' ? 'Hidden' : 'Available'}</span></td>
                    <td style={{ padding: '8px 0', color: '#A06A1F', fontSize: 12 }}>
                      {m.low_ingredients.length === 0 ? '—' : m.low_ingredients.map((li) => `${li.ingredient_name} (${li.stock_quantity}/${li.low_stock_threshold} ${li.unit || ''})`).join(', ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}
      </section>
      )}
    </div>
  );
}
