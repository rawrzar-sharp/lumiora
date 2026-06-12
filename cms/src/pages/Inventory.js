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
    low:            { background: '#FFF1D5', color: '#A06A1F',     label: 'Low'             },
    empty:          { background: '#FEE',    color: palette.rust,  label: 'Empty! Restock'  }, // <--- TAMBAHKAN INI
  };
  const m = map[tone] || map.ok;
  return { display: 'inline-block', padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 800, background: m.background, color: m.color };
};

export default function InventoryPage({ apiUrl, token, userRole }) {
  const [tab, setTab] = useState('stock'); // 'stock' | 'menu'
  const [ingredients, setIngredients] = useState([]);
  const [low, setLow] = useState([]);
  const [availability, setAvailability] = useState([]);
  const [recipes, setRecipes] = useState([]); // /api/cms/recipes/full payload
  const [busyId, setBusyId] = useState(null);
  const [filter, setFilter] = useState('');
  const [openRecipeId, setOpenRecipeId] = useState(null);

  // "Add Ingredient" modal (admin only). Lets the admin link the new
  // ingredient to one or many menu items so a single row (e.g. "Cheese") can
  // back both "Ham n Cheese Croissant" and "Mac n Cheese".
  const [showAddIng, setShowAddIng] = useState(false);
  const [addForm, setAddForm] = useState({ name: '', unit: 'grams', stock_quantity: 0, low_stock_threshold: 0 });
  const [addLinks, setAddLinks] = useState([]); // [{ menu_item_id, quantity_required }]
  const [addBusy, setAddBusy] = useState(false);
  const [addError, setAddError] = useState('');

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchAll = useCallback(async () => {
    try {
      const [a, b, c, d] = await Promise.all([
        fetch(`${apiUrl}/api/cms/ingredients`,        { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/ingredients/low`,    { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/menu-availability`,  { headers: authHeaders }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/recipes/full`,       { headers: authHeaders }).then((r) => r.json()),
      ]);
      if (a && a.success) setIngredients(a.data || []);
      if (b && b.success) setLow(b.data || []);
      if (c && c.success) setAvailability(c.data || []);
      if (d && d.success) setRecipes(d.data || []);
    } catch (e) { /* ignore */ }
  }, [apiUrl, token]);

      useEffect(() => { fetchAll(); }, [fetchAll]);

  // Look up the full recipe (ingredients + steps) for a menu item id. Used by
  // the expandable rows on the Menu tab.
  const recipeFor = (menuItemId) => recipes.find((r) => r.id === menuItemId) || null;

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

  // ---- "+ Add Ingredient" modal helpers (admin only) -----------------------
  const resetAddForm = () => {
    setAddForm({ name: '', unit: 'grams', stock_quantity: 0, low_stock_threshold: 0 });
    setAddLinks([]);
    setAddError('');
  };
  const addLinkRow = () => setAddLinks((prev) => [...prev, { menu_item_id: '', quantity_required: 1 }]);
  const updateLink = (idx, patch) => setAddLinks((prev) => prev.map((l, i) => (i === idx ? { ...l, ...patch } : l)));
  const removeLink = (idx) => setAddLinks((prev) => prev.filter((_, i) => i !== idx));
  const submitAddIngredient = async () => {
    if (!addForm.name.trim()) { setAddError('Ingredient name is required.'); return; }
    setAddBusy(true);
    setAddError('');
    try {
      const links = addLinks
        .filter((l) => l.menu_item_id)
        .map((l) => ({ menu_item_id: Number(l.menu_item_id), quantity_required: Number(l.quantity_required) || 1 }));
      const res = await fetch(`${apiUrl}/api/cms/ingredients`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify({ ...addForm, links }),
      });
      const json = await res.json();
      if (!res.ok || !json.success) { setAddError(json.message || 'Failed to add ingredient'); return; }
      setShowAddIng(false);
      resetAddForm();
      fetchAll();
    } catch (e) {
      setAddError('Could not reach the API');
    } finally {
      setAddBusy(false);
    }
  };

  const grouped = availability.reduce((acc, m) => {
    if (Number(m.is_available) === 0 || m.availability === 'hidden') return acc;
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
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 12, color: '#888' }}>{ingredients.length} ingredients</span>
            {userRole === 'admin' && (
              <button
                data-testid="add-ingredient-btn"
                onClick={() => { resetAddForm(); setShowAddIng(true); }}
                style={{ padding: '8px 14px', borderRadius: 999, border: 'none', cursor: 'pointer', fontWeight: 800, fontSize: 12, background: palette.moss, color: 'white' }}
              >
                + Add Ingredient
              </button>
            )}
          </div>
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
                const stockQty = Number(it.stock_quantity);
                const isEmpty = stockQty === 0;
                const isLow = stockQty <= Number(it.low_stock_threshold) && !isEmpty;
                return (
                  <tr key={it.id} data-testid={`inv-row-${it.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                    <td style={{ padding: '10px 6px', fontWeight: 600, color: palette.ink }}>{it.name}</td>
                    <td style={{ padding: '10px 6px', textAlign: 'right', fontWeight: 700 }}>{stockQty.toLocaleString('id-ID')} {it.unit || ''}</td>
                    <td style={{ padding: '10px 6px', textAlign: 'right', color: '#666' }}>{Number(it.low_stock_threshold).toLocaleString('id-ID')} {it.unit || ''}</td>
                    <td style={{ padding: '10px 6px' }}>
                      <span style={pill(isEmpty ? 'empty' : (isLow ? 'low' : 'ok'))}>
                        {isEmpty ? 'Empty! Restock' : (isLow ? 'Low' : 'OK')}
                      </span>
                    </td>
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
                {items.map((m) => {
                  const isOpen = openRecipeId === m.id;
                  const rcp = isOpen ? recipeFor(m.id) : null;
                  return (
                    <React.Fragment key={m.id}>
                      <tr
                        data-testid={`menu-availability-${m.id}`}
                        style={{ borderTop: `1px solid ${palette.parchment}`, cursor: 'pointer' }}
                        onClick={() => setOpenRecipeId(isOpen ? null : m.id)}
                      >
                        <td style={{ padding: '8px 0', fontWeight: 600, color: palette.ink }}>
                          <span style={{ marginRight: 6, color: palette.moss }}>{isOpen ? '▾' : '▸'}</span>
                          #{m.id} · {m.item_name}
                        </td>
                        <td style={{ padding: '8px 0', textAlign: 'right', fontWeight: 700 }}>{fmtRp(m.price)}</td>
                        <td style={{ padding: '8px 0' }}><span style={pill(m.availability)}>{m.availability === 'low_ingredient' ? 'Low ingredient' : m.availability === 'hidden' ? 'Hidden' : 'Available'}</span></td>
                        <td style={{ padding: '8px 0', color: '#A06A1F', fontSize: 12 }}>
                          {m.low_ingredients.length === 0 ? '—' : m.low_ingredients.map((li) => `${li.ingredient_name} (${li.stock_quantity}/${li.low_stock_threshold} ${li.unit || ''})`).join(', ')}
                        </td>
                      </tr>
                      {isOpen && (
                        <tr data-testid={`menu-recipe-${m.id}`}>
                          <td colSpan={4} style={{ background: '#FCFBF6', padding: '12px 14px', borderTop: `1px dashed ${palette.parchment}` }}>
                            {!rcp ? (
                              <div style={{ color: '#999', fontSize: 13 }}>Loading recipe…</div>
                            ) : (
                              <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) minmax(0,1.4fr)', gap: 24 }}>
                                <div>
                                  <div style={{ fontSize: 11, fontWeight: 800, color: palette.moss, textTransform: 'uppercase', letterSpacing: 1 }}>Ingredients</div>
                                  {rcp.ingredients.length === 0 ? (
                                    <div style={{ color: '#999', fontSize: 13, marginTop: 6 }}>No ingredients linked yet.</div>
                                  ) : (
                                    <ul style={{ paddingLeft: 18, margin: '6px 0 0 0' }}>
                                      {rcp.ingredients.map((ing) => (
                                        <li key={ing.ingredient_id} style={{ padding: '3px 0', fontSize: 13, color: palette.ink }}>
                                          <strong>{ing.quantity}{ing.unit ? ` ${ing.unit}` : ''}</strong> · {ing.ingredient_name}
                                        </li>
                                      ))}
                                    </ul>
                                  )}
                                </div>
                                <div>
                                  <div style={{ fontSize: 11, fontWeight: 800, color: palette.moss, textTransform: 'uppercase', letterSpacing: 1 }}>Step-by-step</div>
                                  {rcp.steps.length === 0 ? (
                                    <div style={{ color: '#999', fontSize: 13, marginTop: 6 }}>No preparation steps yet.</div>
                                  ) : (
                                    <ol style={{ paddingLeft: 22, margin: '6px 0 0 0' }}>
                                      {rcp.steps.map((s, idx) => (
                                        <li key={idx} style={{ padding: '3px 0', fontSize: 13, color: palette.ink, lineHeight: 1.5 }}>{s}</li>
                                      ))}
                                    </ol>
                                  )}
                                </div>
                              </div>
                            )}
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        ))}
      </section>
      )}
      {/* ========================= ADD INGREDIENT MODAL ========================= */}
      {showAddIng && userRole === 'admin' && (
        <div
          data-testid="add-ingredient-modal"
          onClick={() => !addBusy && setShowAddIng(false)}
          style={{ position: 'fixed', inset: 0, background: 'rgba(31, 33, 23, 0.55)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: 18 }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{ background: 'white', borderRadius: 16, padding: 22, maxWidth: 560, width: '100%', maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 20px 60px rgba(0,0,0,0.25)' }}
          >
            <h3 style={{ margin: 0, color: palette.ink, fontSize: 18 }}>Add Ingredient</h3>
            <p style={{ marginTop: 4, marginBottom: 14, color: '#888', fontSize: 12 }}>
              One ingredient can back many menu items (e.g. Cheese → Ham n Cheese Croissant + Mac n Cheese).
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              <label style={{ fontSize: 12, fontWeight: 700, color: palette.ink }}>
                Name
                <input
                  data-testid="add-ing-name"
                  value={addForm.name}
                  onChange={(e) => setAddForm({ ...addForm, name: e.target.value })}
                  placeholder="e.g. Cheese Slices"
                  style={{ marginTop: 4, width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13 }}
                />
              </label>
              <label style={{ fontSize: 12, fontWeight: 700, color: palette.ink }}>
                Unit
                <select
                  data-testid="add-ing-unit"
                  value={addForm.unit}
                  onChange={(e) => setAddForm({ ...addForm, unit: e.target.value })}
                  style={{ marginTop: 4, width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13 }}
                >
                  <option value="grams">grams</option>
                  <option value="ml">ml</option>
                  <option value="pcs">pcs</option>
                </select>
              </label>
              <label style={{ fontSize: 12, fontWeight: 700, color: palette.ink }}>
                Stock Quantity
                <input
                  data-testid="add-ing-stock"
                  type="number"
                  value={addForm.stock_quantity}
                  onChange={(e) => setAddForm({ ...addForm, stock_quantity: e.target.value })}
                  style={{ marginTop: 4, width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13 }}
                />
              </label>
              <label style={{ fontSize: 12, fontWeight: 700, color: palette.ink }}>
                Low-stock Threshold
                <input
                  data-testid="add-ing-threshold"
                  type="number"
                  value={addForm.low_stock_threshold}
                  onChange={(e) => setAddForm({ ...addForm, low_stock_threshold: e.target.value })}
                  style={{ marginTop: 4, width: '100%', padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13 }}
                />
              </label>
            </div>

            <div style={{ marginTop: 18 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <strong style={{ color: palette.ink, fontSize: 13 }}>Link to menu items</strong>
                <button
                  data-testid="add-ing-link-btn"
                  type="button"
                  onClick={addLinkRow}
                  style={{ padding: '6px 12px', borderRadius: 999, border: `1px solid ${palette.moss}`, background: 'transparent', color: palette.moss, fontWeight: 800, fontSize: 11, cursor: 'pointer' }}
                >+ Link to menu item</button>
              </div>
              <p style={{ marginTop: 4, marginBottom: 8, color: '#888', fontSize: 11 }}>Optional. Skip if this ingredient isn&apos;t tied to any drink/dish yet.</p>
              {addLinks.length === 0 ? (
                <div style={{ color: '#999', fontSize: 12, padding: '8px 0' }}>No links added yet.</div>
              ) : (
                addLinks.map((link, idx) => (
                  <div key={idx} style={{ display: 'grid', gridTemplateColumns: '1fr 100px 40px', gap: 8, marginTop: 8 }}>
                    <select
                      data-testid={`add-ing-link-menu-${idx}`}
                      value={link.menu_item_id}
                      onChange={(e) => updateLink(idx, { menu_item_id: e.target.value })}
                      style={{ padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13 }}
                    >
                      <option value="">— Select menu item —</option>
                      {availability.filter((m) => Number(m.is_available) !== 0 && m.availability !== 'hidden').map((m) => (
                        <option key={m.id} value={m.id}>#{m.id} · {m.item_name}</option>
                      ))}
                    </select>
                    <input
                      data-testid={`add-ing-link-qty-${idx}`}
                      type="number"
                      value={link.quantity_required}
                      onChange={(e) => updateLink(idx, { quantity_required: e.target.value })}
                      placeholder="Qty"
                      style={{ padding: 8, borderRadius: 8, border: `1px solid ${palette.parchment}`, fontSize: 13, textAlign: 'right' }}
                    />
                    <button
                      data-testid={`add-ing-link-remove-${idx}`}
                      type="button"
                      onClick={() => removeLink(idx)}
                      style={{ background: '#FFF0EC', color: palette.rust, border: `1px solid ${palette.rust}`, borderRadius: 8, cursor: 'pointer', fontWeight: 800 }}
                    >×</button>
                  </div>
                ))
              )}
            </div>

            {addError && (
              <div data-testid="add-ing-error" style={{ marginTop: 14, color: palette.rust, fontSize: 13, fontWeight: 700 }}>{addError}</div>
            )}

            <div style={{ marginTop: 20, display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button
                data-testid="add-ing-cancel"
                type="button"
                disabled={addBusy}
                onClick={() => setShowAddIng(false)}
                style={{ padding: '10px 18px', borderRadius: 999, border: `1px solid ${palette.parchment}`, background: 'white', color: palette.ink, fontWeight: 800, cursor: 'pointer' }}
              >Cancel</button>
              <button
                data-testid="add-ing-submit"
                type="button"
                disabled={addBusy}
                onClick={submitAddIngredient}
                style={{ padding: '10px 22px', borderRadius: 999, border: 'none', background: palette.moss, color: 'white', fontWeight: 800, cursor: 'pointer' }}
              >{addBusy ? 'Saving…' : 'Save Ingredient'}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
