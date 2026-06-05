import React, { useEffect, useState } from 'react';

export default function InventoryPage({ apiUrl, token, userRole }) {
  const [ingredients, setIngredients] = useState([]);
  const [low, setLow] = useState([]);

  useEffect(() => {
    if (!apiUrl) return;
    fetch(`${apiUrl}/api/cms/ingredients`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json()).then(d => { if (d && d.success) setIngredients(d.data || []); }).catch(()=>{});
    fetch(`${apiUrl}/api/cms/ingredients/low`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json()).then(d => { if (d && d.success) setLow(d.data || []); }).catch(()=>{});
  }, [apiUrl, token]);

  const setStock = (id, amount) => {
    fetch(`${apiUrl}/api/cms/ingredients/stock`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify({ ingredient_id: id, amount, set: true }) })
      .then(r => r.json()).then(()=>{
        // refresh
        return fetch(`${apiUrl}/api/cms/ingredients`, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
      }).then(r=>r.json()).then(d=>{ if(d && d.success) setIngredients(d.data||[]); }).catch(()=>{});
  };

  return (
    <div>
      <h3>Inventory</h3>
      {low.length > 0 && <div style={{ color: 'orange' }}>Low stock alerts: {low.length}</div>}
      <table>
        <thead>
          <tr><th>Name</th><th>Qty</th><th>Cost</th><th>Action</th></tr>
        </thead>
        <tbody>
          {ingredients.length ? ingredients.map(it => (
            <tr key={it.id}>
              <td>{it.name || it.ingredient_name}</td>
              <td>{it.quantity || it.stock || 0}</td>
              <td>{it.cost || it.price || 0}</td>
              <td>
                {userRole === 'admin' && <button onClick={() => setStock(it.id || it.ingredient_id, (it.quantity||it.stock||0) + 10)}>+10</button>}
              </td>
            </tr>
          )) : <tr><td colSpan="4">No ingredients</td></tr>}
        </tbody>
      </table>
    </div>
  );
}
