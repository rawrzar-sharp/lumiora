import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
  amber: '#C28840',
  rust: '#C2452F',
};

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

const tabBtn = (active) => ({
  padding: '8px 16px',
  borderRadius: 999,
  border: 'none',
  cursor: 'pointer',
  fontWeight: 700,
  fontSize: 12,
  background: active ? palette.moss : 'transparent',
  color: active ? 'white' : palette.ink,
});

export default function InventoryPage({ apiUrl, token, userRole }) {
  const [tab, setTab] = useState('stock'); // stock | kitchen
  const [ingredients, setIngredients] = useState([]);
  const [low, setLow] = useState([]);
  const [recipes, setRecipes] = useState([]);
  const [busyId, setBusyId] = useState(null);

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchInventory = useCallback(async () => {
    try {
      const [a, b] = await Promise.all([
        fetch(`${apiUrl}/api/cms/ingredients`,     { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/ingredients/low`, { headers: authHeaders }).then((r) => r.json()),
      ]);
      if (a && a.success) setIngredients(a.data || []);
      if (b && b.success) setLow(b.data || []);
    } catch (e) { /* ignore */ }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  const fetchRecipes = useCallback(async () => {
    try {
      const res = await fetch(`${apiUrl}/api/cms/recipes`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) setRecipes(json.data || []);
    } catch (e) { /* ignore */ }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { fetchInventory(); fetchRecipes(); }, [fetchInventory, fetchRecipes]);

  const adjust = async (it, delta) => {
    setBusyId(it.id);
    try {
      await fetch(`${apiUrl}/api/cms/ingredients/stock`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ ingredient_id: it.id, amount: delta, set: false }),
      });
      fetchInventory();
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
      fetchInventory();
    } catch (e) { /* ignore */ }
    finally { setBusyId(null); }
  };

  return (
    <div data-testid="cms-inventory-page">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, gap: 12, flexWrap: 'wrap' }}>
        <div>
          <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Menu / Stock</h3>
          <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
            Track ingredient stock and peek at the kitchen recipe book.
          </p>
        </div>
        <div data-testid="inventory-tabs" style={{ display: 'flex', gap: 6, background: palette.parchment, padding: 4, borderRadius: 999 }}>
          <button data-testid="inv-tab-stock"   onClick={() => setTab('stock')}   style={tabBtn(tab === 'stock')}>Stock</button>
          <button data-testid="inv-tab-kitchen" onClick={() => setTab('kitchen')} style={tabBtn(tab === 'kitchen')}>Kitchen Set</button>
        </div>
      </div>

      {low.length > 0 && (
        <div data-testid="inv-low-banner" style={{ ...card, background: '#FFF5E5', borderColor: palette.amber, marginBottom: 14 }}>
          <strong style={{ color: palette.rust }}>{low.length}</strong>{' '}
          <span style={{ fontSize: 13, color: palette.ink }}>ingredient{low.length > 1 ? 's are' : ' is'} at or below threshold — restock soon.</span>
        </div>
      )}

      {tab === 'stock' && (
        <div style={card} data-testid="inv-stock-panel">
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
                  {userRole === 'admin' && <th style={{ padding: '10px 6px' }}>Adjust</th>}
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
                      <td style={{ padding: '10px 6px' }}>
                        <span style={{
                          padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 700,
                          background: isLow ? '#FEE' : '#E7F3D9',
                          color: isLow ? palette.rust : palette.moss,
                        }}>{isLow ? 'Low' : 'OK'}</span>
                      </td>
                      {userRole === 'admin' && (
                        <td style={{ padding: '10px 6px' }}>
                          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                            <button data-testid={`inv-minus-${it.id}`} disabled={busyId === it.id} onClick={() => adjust(it, -1)} style={{ padding: '6px 10px', borderRadius: 8, border: `1px solid ${palette.parchment}`, background: 'white', cursor: 'pointer', fontWeight: 700 }}>-1</button>
                            <button data-testid={`inv-plus-${it.id}`}  disabled={busyId === it.id} onClick={() => adjust(it,  10)} style={{ padding: '6px 10px', borderRadius: 8, border: `1px solid ${palette.moss}`, background: palette.moss, color: 'white', cursor: 'pointer', fontWeight: 700 }}>+10</button>
                            <input
                              data-testid={`inv-set-${it.id}`}
                              type="number"
                              defaultValue={it.stock_quantity}
                              onKeyDown={(e) => { if (e.key === 'Enter') setExact(it, e.currentTarget.value); }}
                              style={{ width: 80, padding: 6, borderRadius: 6, border: `1px solid ${palette.parchment}`, textAlign: 'right' }}
                              title="Press Enter to set exact stock"
                            />
                          </div>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}

      {tab === 'kitchen' && (
        <div data-testid="inv-kitchen-panel" style={{ display: 'grid', gap: 12 }}>
          {recipes.length === 0 ? (
            <div data-testid="inv-kitchen-empty" style={{ ...card, color: '#777', textAlign: 'center' }}>
              No recipes defined yet. Add rows to the <code>recipes</code> table so the kitchen knows what each menu item consumes.
            </div>
          ) : recipes.map((r) => (
            <article key={r.menu_item_id} data-testid={`recipe-${r.menu_item_id}`} style={card}>
              <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8, flexWrap: 'wrap', gap: 6 }}>
                <strong style={{ color: palette.ink, fontSize: 16 }}>{r.menu_name}</strong>
                <span style={{ fontSize: 12, color: '#888' }}>{r.recipe.length} ingredient{r.recipe.length !== 1 ? 's' : ''}</span>
              </header>
              <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
                {r.recipe.map((ing, idx) => (
                  <li key={idx} style={{ padding: '6px 0', borderTop: idx === 0 ? 'none' : `1px dashed ${palette.parchment}`, display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                    <span>{ing.ingredient_name}</span>
                    <span style={{ color: '#666' }}>{Number(ing.quantity_required).toLocaleString('id-ID')}</span>
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
