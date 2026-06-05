import React, { useEffect, useState } from 'react';

export default function RecipesPage({ apiUrl, token }) {
  const [recipes, setRecipes] = useState([]);

  useEffect(() => {
    if (!apiUrl) return;
    fetch(`${apiUrl}/api/cms/recipes`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json()).then(d => { if (d && d.success) setRecipes(d.data || []); }).catch(()=>{});
  }, [apiUrl, token]);

  return (
    <div>
      <h3>Recipes</h3>
      <ul>
        {recipes.length ? recipes.map(r => (
          <li key={r.id || r.menu_id}>{r.menu_name || r.name} - {r.ingredients ? r.ingredients.length : 'N/A'} ingredients</li>
        )) : <li>No recipes</li>}
      </ul>
    </div>
  );
}
