// =============================================================================
// Lumiora — Recipes & ingredient seed
// -----------------------------------------------------------------------------
// Source of truth for the new "Recipes" page and the "Add ingredient" feature.
// • INGREDIENTS  — master list of every raw material the café tracks. The
//                  startup seeder upserts these into the `ingredients` table by
//                  name (so existing ids are kept and stock counts aren't reset).
// • RECIPES      — per menu_item_id: { ingredient_name → quantity_required, steps[] }.
//                  The seeder rewrites the `recipes` table only for items we
//                  know about, and writes the prep `steps` into a new
//                  `menu_item_steps` table that we create lazily.
// • SOFT_HIDE_CATEGORY_IDS — Bundling Duo (#4) + Trio (#5) are flipped to
//                  `is_available = 0` and excluded from the recipe view, but
//                  the rows stay so historical orders keep their item names.
// All seeds are idempotent — safe to run on every boot.
// =============================================================================

const SOFT_HIDE_CATEGORY_IDS = [4, 5];

// -------------------- Ingredients (master list, ~25 rows) --------------------
const INGREDIENTS = [
  // Coffee / dairy
  { name: 'Espresso Beans',        unit: 'grams', stock_quantity: 5000,  low_stock_threshold: 500 },
  { name: 'Fresh Milk',            unit: 'ml',    stock_quantity: 12000, low_stock_threshold: 2000 },
  { name: 'Heavy Cream',           unit: 'ml',    stock_quantity: 3000,  low_stock_threshold: 500 },
  { name: 'Sea Salt Cream Foam',   unit: 'ml',    stock_quantity: 3000,  low_stock_threshold: 500 },
  { name: 'Butter Cream',          unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 300 },
  { name: 'Hot Water',             unit: 'ml',    stock_quantity: 20000, low_stock_threshold: 1000 },
  // Syrups & flavour
  { name: 'Aren Palm Sugar Syrup', unit: 'ml',    stock_quantity: 2500,  low_stock_threshold: 400 },
  { name: 'Caramel Syrup',         unit: 'ml',    stock_quantity: 2000,  low_stock_threshold: 300 },
  { name: 'Hazelnut Syrup',        unit: 'ml',    stock_quantity: 2000,  low_stock_threshold: 300 },
  { name: 'Vanilla Syrup',         unit: 'ml',    stock_quantity: 2000,  low_stock_threshold: 300 },
  { name: 'Butterscotch Syrup',    unit: 'ml',    stock_quantity: 1800,  low_stock_threshold: 300 },
  { name: 'Pandan Syrup',          unit: 'ml',    stock_quantity: 1500,  low_stock_threshold: 200 },
  { name: 'Avocado Puree',         unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 300 },
  { name: 'Banana Puree',          unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 300 },
  { name: 'Coconut Syrup',         unit: 'ml',    stock_quantity: 1500,  low_stock_threshold: 200 },
  { name: 'Chocolate Syrup',       unit: 'ml',    stock_quantity: 2500,  low_stock_threshold: 400 },
  { name: 'Cocoa Powder',          unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 250 },
  { name: 'Matcha Powder',         unit: 'grams', stock_quantity: 1000,  low_stock_threshold: 150 },
  { name: 'Strawberry Jam',        unit: 'grams', stock_quantity: 1200,  low_stock_threshold: 200 },
  // Pastry & savoury
  { name: 'Brioche Bread Slices',  unit: 'pcs',   stock_quantity: 80,    low_stock_threshold: 15 },
  { name: 'Croissant Dough Sheet', unit: 'pcs',   stock_quantity: 100,   low_stock_threshold: 20 },
  { name: 'Tuna Mix Spread',       unit: 'grams', stock_quantity: 2500,  low_stock_threshold: 400 },
  { name: 'Egg',                   unit: 'pcs',   stock_quantity: 200,   low_stock_threshold: 30 },
  { name: 'Mayonnaise',            unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 250 },
  { name: 'Ham Slices',            unit: 'pcs',   stock_quantity: 120,   low_stock_threshold: 20 },
  { name: 'Cheese Slices',         unit: 'pcs',   stock_quantity: 200,   low_stock_threshold: 30 },
  { name: 'Mozzarella Cheese',     unit: 'grams', stock_quantity: 2000,  low_stock_threshold: 300 },
  { name: 'Dark Chocolate',        unit: 'grams', stock_quantity: 2000,  low_stock_threshold: 300 },
  { name: 'Wheat Flour',           unit: 'grams', stock_quantity: 5000,  low_stock_threshold: 700 },
  { name: 'Butter',                unit: 'grams', stock_quantity: 3000,  low_stock_threshold: 400 },
  { name: 'Sugar',                 unit: 'grams', stock_quantity: 5000,  low_stock_threshold: 700 },
  { name: 'Chocochips',            unit: 'grams', stock_quantity: 1500,  low_stock_threshold: 250 },
  { name: 'Macaroni Pasta',        unit: 'grams', stock_quantity: 2500,  low_stock_threshold: 400 },
  { name: 'Béchamel Sauce',        unit: 'ml',    stock_quantity: 2000,  low_stock_threshold: 300 },
  // Skewers (kitchen)
  { name: 'Korean Fish Cake',      unit: 'pcs',   stock_quantity: 150,   low_stock_threshold: 25 },
  { name: 'Fish Ball',             unit: 'pcs',   stock_quantity: 200,   low_stock_threshold: 30 },
  { name: 'Cheese Dumpling',       unit: 'pcs',   stock_quantity: 120,   low_stock_threshold: 20 },
  { name: 'Chikuwa Stick',         unit: 'pcs',   stock_quantity: 150,   low_stock_threshold: 25 },
  { name: 'Fish Tofu',             unit: 'pcs',   stock_quantity: 150,   low_stock_threshold: 25 },
  { name: 'Bamboo Skewer Stick',   unit: 'pcs',   stock_quantity: 500,   low_stock_threshold: 100 },
];

// -------------------- Per-menu recipes (ingredients + steps) -----------------
// Quantities use the unit declared on the matching ingredient row.
const LATTE_BASE = [
  { name: 'Espresso Beans', qty: 18 },
  { name: 'Fresh Milk',     qty: 180 },
];
const lattePrepSteps = (flavour) => [
  `Grind 18g of espresso beans to a fine espresso grind.`,
  `Pull a double shot (≈40ml) of espresso into a 240ml cup.`,
  `Steam 180ml of fresh milk to 60–65°C with a silky microfoam.`,
  `Stir ${flavour} into the espresso before pouring.`,
  `Pour the steamed milk slowly to form a centred latte art tulip and serve immediately.`,
];

const RECIPES = {
  // ===== Latte Series (cat 1) =================================================
  1: { // Latte
    ingredients: LATTE_BASE,
    steps: [
      'Grind 18g of espresso beans to a fine espresso grind.',
      'Pull a double shot (≈40ml) of espresso directly into a 240ml cup.',
      'Steam 180ml of fresh milk to 60–65°C with a silky microfoam.',
      'Pour the steamed milk into the espresso to form a centred latte art rosetta.',
      'Wipe the rim and serve warm immediately.',
    ],
  },
  2: { // Aren Latte
    ingredients: [...LATTE_BASE, { name: 'Aren Palm Sugar Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of aren palm sugar syrup'),
  },
  3: { // Caramel Latte
    ingredients: [...LATTE_BASE, { name: 'Caramel Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of caramel syrup'),
  },
  4: { // Hazelnut Latte
    ingredients: [...LATTE_BASE, { name: 'Hazelnut Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of hazelnut syrup'),
  },
  5: { // Vanilla Latte
    ingredients: [...LATTE_BASE, { name: 'Vanilla Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of vanilla syrup'),
  },
  6: { // Butterscotch Latte
    ingredients: [...LATTE_BASE, { name: 'Butterscotch Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of butterscotch syrup'),
  },
  7: { // Buttercream Aren Latte
    ingredients: [...LATTE_BASE, { name: 'Aren Palm Sugar Syrup', qty: 20 }, { name: 'Butter Cream', qty: 25 }],
    steps: [
      'Grind 18g of espresso beans to a fine espresso grind.',
      'Pull a double shot of espresso into a 240ml cup.',
      'Stir 20ml of aren palm sugar syrup into the espresso.',
      'Steam 180ml of fresh milk to a velvety microfoam.',
      'Pour milk to fill the cup, then float 25g of whipped butter cream on top and lightly torch the surface.',
    ],
  },
  8: { // Creamy Aren Latte
    ingredients: [...LATTE_BASE, { name: 'Aren Palm Sugar Syrup', qty: 20 }, { name: 'Heavy Cream', qty: 30 }],
    steps: [
      'Pull a double shot of espresso into a chilled 240ml glass.',
      'Stir 20ml of aren palm sugar syrup into the espresso.',
      'Pour 180ml of cold fresh milk over the espresso.',
      'Slowly layer 30ml of lightly whipped heavy cream across the back of a spoon for a clean cream cap.',
      'Serve with a stainless straw.',
    ],
  },
  9: { // Pandan Latte
    ingredients: [...LATTE_BASE, { name: 'Pandan Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of pandan syrup'),
  },
  10: { // Avocado Latte
    ingredients: [...LATTE_BASE, { name: 'Avocado Puree', qty: 40 }, { name: 'Sugar', qty: 10 }],
    steps: [
      'Blend 40g of avocado puree with 10g of sugar until smooth.',
      'Pour avocado base into a chilled 240ml glass.',
      'Pull a double shot of espresso and pour over the avocado base.',
      'Top with 180ml of cold steamed milk.',
      'Stir gently and serve.',
    ],
  },
  11: { // Banana Latte
    ingredients: [...LATTE_BASE, { name: 'Banana Puree', qty: 40 }],
    steps: [
      'Pour 40g of banana puree into a chilled 240ml glass.',
      'Pull a double shot of espresso directly over the banana base.',
      'Pour 180ml of cold fresh milk in slowly to keep the layered look.',
      'Stir before drinking to combine the flavours.',
    ],
  },
  12: { // Coconut Latte
    ingredients: [...LATTE_BASE, { name: 'Coconut Syrup', qty: 20 }],
    steps: lattePrepSteps('20ml of coconut syrup'),
  },

  // ===== Classics (cat 2) =====================================================
  13: { // Espresso
    ingredients: [{ name: 'Espresso Beans', qty: 18 }],
    steps: [
      'Grind 18g of espresso beans to a fine espresso grind.',
      'Tamp evenly into the portafilter at 30 lbs of pressure.',
      'Pull a single shot of ≈30ml in 25–28 seconds.',
      'Serve immediately in a warmed demitasse cup.',
    ],
  },
  14: { // Americano
    ingredients: [{ name: 'Espresso Beans', qty: 18 }, { name: 'Hot Water', qty: 160 }],
    steps: [
      'Pull a double shot of espresso into a 240ml cup.',
      'Add 160ml of freshly boiled water (90°C) over the espresso.',
      'Optional: skim the crema for a cleaner finish.',
      'Serve hot with a small jug of milk on the side.',
    ],
  },
  15: { // Cappucino
    ingredients: [{ name: 'Espresso Beans', qty: 18 }, { name: 'Fresh Milk', qty: 120 }],
    steps: [
      'Pull a double shot of espresso into a 180ml cappuccino cup.',
      'Steam 120ml of fresh milk into a thick, dry foam.',
      'Pour ⅓ steamed milk, then top with ⅓ thick foam.',
      'Dust the foam with a pinch of cocoa powder and serve.',
    ],
  },
  16: { // Caffe Mocha
    ingredients: [
      { name: 'Espresso Beans',  qty: 18 },
      { name: 'Fresh Milk',      qty: 180 },
      { name: 'Chocolate Syrup', qty: 25 },
      { name: 'Cocoa Powder',    qty: 3 },
    ],
    steps: [
      'Pour 25ml of chocolate syrup into the bottom of a 300ml cup.',
      'Pull a double shot of espresso directly over the syrup and stir.',
      'Steam 180ml of fresh milk to a silky microfoam.',
      'Pour the milk to fill the cup, leaving room for foam.',
      'Dust the surface with cocoa powder and serve.',
    ],
  },

  // ===== Non-Coffee (cat 3) ===================================================
  17: { // Chocolate
    ingredients: [
      { name: 'Fresh Milk',      qty: 200 },
      { name: 'Chocolate Syrup', qty: 35 },
      { name: 'Cocoa Powder',    qty: 5 },
    ],
    steps: [
      'Whisk 5g of cocoa powder with 35ml of chocolate syrup into a paste.',
      'Steam 200ml of fresh milk to 65°C with a silky foam.',
      'Pour the chocolate paste into a 300ml cup.',
      'Pour the steamed milk slowly, stirring to combine.',
      'Top with a light dusting of cocoa powder and serve.',
    ],
  },
  18: { // Matcha Latte
    ingredients: [
      { name: 'Matcha Powder', qty: 4 },
      { name: 'Fresh Milk',    qty: 200 },
      { name: 'Hot Water',     qty: 60 },
    ],
    steps: [
      'Sift 4g of matcha powder into a bowl.',
      'Add 60ml of 75°C hot water and whisk in an "M" motion until frothy.',
      'Pour the matcha base into a 300ml cup.',
      'Steam 200ml of fresh milk to a velvety microfoam and pour over the matcha.',
      'Finish with a light dusting of matcha and serve.',
    ],
  },
  19: { // Strawberry Matcha Latte
    ingredients: [
      { name: 'Matcha Powder',  qty: 4 },
      { name: 'Fresh Milk',     qty: 200 },
      { name: 'Hot Water',      qty: 50 },
      { name: 'Strawberry Jam', qty: 25 },
    ],
    steps: [
      'Spoon 25g of strawberry jam into the bottom of a chilled 300ml glass.',
      'Pour 200ml of cold fresh milk over the jam without stirring.',
      'Whisk 4g of matcha powder with 50ml of 75°C water until frothy.',
      'Slowly pour the matcha over the back of a spoon to form a third top layer.',
      'Serve with a straw and let the customer mix before drinking.',
    ],
  },

  // ===== Pastry & Bakery (cat 6) =============================================
  29: { // Egg Sando
    ingredients: [
      { name: 'Brioche Bread Slices', qty: 2 },
      { name: 'Egg',                  qty: 2 },
      { name: 'Mayonnaise',           qty: 25 },
      { name: 'Butter',               qty: 10 },
    ],
    steps: [
      'Soft-boil 2 eggs for exactly 7 minutes, then chill in ice water.',
      'Peel and roughly chop the eggs, then fold with 25g of mayonnaise and a pinch of salt.',
      'Lightly butter both slices of brioche on the inside.',
      'Pile the egg salad onto one slice, top with the second and gently press.',
      'Trim the crusts and slice in half on the diagonal.',
    ],
  },
  30: { // Ham n Cheese Croissant
    ingredients: [
      { name: 'Croissant Dough Sheet', qty: 1 },
      { name: 'Ham Slices',            qty: 2 },
      { name: 'Cheese Slices',         qty: 2 },
      { name: 'Butter',                qty: 5 },
    ],
    steps: [
      'Slice a baked croissant horizontally without cutting all the way through.',
      'Layer 2 slices of ham and 2 slices of cheese inside.',
      'Brush the top with melted butter.',
      'Bake at 180°C for 6–8 minutes until the cheese is melted and the top is golden.',
      'Slice diagonally and serve warm.',
    ],
  },
  31: { // Dark Choco Brownies
    ingredients: [
      { name: 'Dark Chocolate', qty: 80 },
      { name: 'Butter',         qty: 60 },
      { name: 'Egg',            qty: 2 },
      { name: 'Sugar',          qty: 80 },
      { name: 'Wheat Flour',    qty: 50 },
    ],
    steps: [
      'Melt 80g of dark chocolate with 60g of butter over a bain-marie until smooth.',
      'Whisk 2 eggs with 80g of sugar until pale and ribbon stage.',
      'Fold the melted chocolate into the egg mixture.',
      'Sift in 50g of wheat flour and fold until just combined.',
      'Bake in a lined tin at 170°C for 22 minutes — the centre should still be fudgy.',
    ],
  },
  32: { // Chocochips Muffin
    ingredients: [
      { name: 'Wheat Flour', qty: 120 },
      { name: 'Sugar',       qty: 70 },
      { name: 'Butter',      qty: 50 },
      { name: 'Egg',         qty: 1 },
      { name: 'Fresh Milk',  qty: 80 },
      { name: 'Chocochips',  qty: 40 },
    ],
    steps: [
      'Whisk 120g flour, 70g sugar and a pinch of baking powder in a large bowl.',
      'In another bowl, mix 50g of melted butter, 1 egg and 80ml of milk.',
      'Fold the wet mix into the dry until just combined (lumps are fine).',
      'Stir in 40g of chocochips and scoop into muffin liners.',
      'Bake at 180°C for 18–20 minutes until a skewer comes out clean.',
    ],
  },
  33: { // Mac n Cheese
    ingredients: [
      { name: 'Macaroni Pasta',    qty: 90 },
      { name: 'Béchamel Sauce',    qty: 120 },
      { name: 'Mozzarella Cheese', qty: 50 },
      { name: 'Butter',            qty: 10 },
    ],
    steps: [
      'Boil 90g of macaroni in salted water until al dente, then drain.',
      'Warm 120ml of béchamel sauce in a pan with 10g of butter.',
      'Toss the macaroni in the béchamel, then transfer to a small oven-safe dish.',
      'Top with 50g of grated mozzarella.',
      'Bake at 200°C for 6–8 minutes until bubbling and golden on top.',
    ],
  },
  34: { // Chocochips Cookies
    ingredients: [
      { name: 'Wheat Flour', qty: 100 },
      { name: 'Butter',      qty: 60 },
      { name: 'Sugar',       qty: 60 },
      { name: 'Egg',         qty: 1 },
      { name: 'Chocochips',  qty: 40 },
    ],
    steps: [
      'Cream 60g of butter with 60g of sugar until pale and fluffy.',
      'Beat in 1 egg until fully combined.',
      'Fold in 100g of flour and a pinch of salt to form a stiff dough.',
      'Mix in 40g of chocochips and portion into balls on a lined tray.',
      'Bake at 180°C for 11 minutes — the edges should be set but the centres soft.',
    ],
  },
  35: { // Butter Croissant
    ingredients: [
      { name: 'Croissant Dough Sheet', qty: 1 },
      { name: 'Butter',                qty: 10 },
      { name: 'Egg',                   qty: 1 },
    ],
    steps: [
      'Shape the laminated croissant dough sheet into a triangle and roll it into a crescent.',
      'Proof at 26°C for 2 hours until visibly puffy.',
      'Beat 1 egg and brush the top of the croissant for a glossy finish.',
      'Bake at 200°C for 16–18 minutes until deep golden and crispy.',
      'Brush with a touch of melted butter while still warm before serving.',
    ],
  },

  // ===== Skewers (cat 7) ======================================================
  36: { // Odeng
    ingredients: [
      { name: 'Korean Fish Cake',    qty: 2 },
      { name: 'Bamboo Skewer Stick', qty: 1 },
      { name: 'Hot Water',           qty: 200 },
    ],
    steps: [
      'Bring 200ml of dashi-spiced broth to a gentle simmer.',
      'Thread 2 sheets of Korean fish cake onto a bamboo skewer.',
      'Submerge the skewer into the broth for 4 minutes.',
      'Brush lightly with sweet soy glaze and serve with a small cup of the broth on the side.',
    ],
  },
  37: { // Fish Ball
    ingredients: [
      { name: 'Fish Ball',           qty: 4 },
      { name: 'Bamboo Skewer Stick', qty: 1 },
      { name: 'Hot Water',           qty: 200 },
    ],
    steps: [
      'Simmer 200ml of broth and drop in 4 fish balls.',
      'Cook for 3 minutes until they float and are heated through.',
      'Thread the fish balls onto a bamboo skewer.',
      'Drizzle with sweet chilli sauce and serve hot.',
    ],
  },
  38: { // Cheese Dumpling
    ingredients: [
      { name: 'Cheese Dumpling',     qty: 3 },
      { name: 'Bamboo Skewer Stick', qty: 1 },
    ],
    steps: [
      'Steam 3 cheese dumplings for 6 minutes until the wrappers are translucent.',
      'Thread them gently onto a bamboo skewer.',
      'Pan-sear one side for 30 seconds for a crisp bottom.',
      'Drizzle with sweet soy and sprinkle sesame seeds before serving.',
    ],
  },
  39: { // Chikuwa
    ingredients: [
      { name: 'Chikuwa Stick',       qty: 2 },
      { name: 'Bamboo Skewer Stick', qty: 1 },
      { name: 'Hot Water',           qty: 150 },
    ],
    steps: [
      'Cut 2 chikuwa tubes in half and thread onto a bamboo skewer.',
      'Simmer the skewer in 150ml of dashi-spiced broth for 3 minutes.',
      'Brush the surface with a light teriyaki glaze.',
      'Char briefly over an open flame for a smoky finish and serve.',
    ],
  },
  40: { // Fish Tofu
    ingredients: [
      { name: 'Fish Tofu',           qty: 3 },
      { name: 'Bamboo Skewer Stick', qty: 1 },
      { name: 'Hot Water',           qty: 150 },
    ],
    steps: [
      'Score 3 fish tofu cubes lightly so they absorb broth better.',
      'Thread onto a bamboo skewer.',
      'Simmer in 150ml of broth for 4 minutes.',
      'Glaze with sweet chilli and torch lightly for caramelisation before serving.',
    ],
  },
};

// =============================================================================
// Seeder — called from web.js runStartupMigrations(). Safe to run on every boot.
// =============================================================================
async function seedRecipesAndIngredients(db) {
  // 1) Make sure the per-item prep-steps table exists.
  await db.query(`
    CREATE TABLE IF NOT EXISTS menu_item_steps (
      menu_item_id INT NOT NULL,
      step_no      INT NOT NULL,
      text         TEXT NOT NULL,
      PRIMARY KEY (menu_item_id, step_no)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  // 2) Upsert ingredients by name. We never reset stock_quantity once an
  //    ingredient already exists — only fill in missing ones.
  const nameToId = new Map();
  for (const ing of INGREDIENTS) {
    const [existing] = await db.query('SELECT id FROM ingredients WHERE name = ? LIMIT 1', [ing.name]);
    if (existing.length > 0) {
      nameToId.set(ing.name, existing[0].id);
    } else {
      const [result] = await db.query(
        'INSERT INTO ingredients (name, stock_quantity, unit, low_stock_threshold) VALUES (?, ?, ?, ?)',
        [ing.name, ing.stock_quantity, ing.unit, ing.low_stock_threshold]
      );
      nameToId.set(ing.name, result.insertId);
    }
  }

  // 3) Rewrite recipes + steps per menu item. We DELETE the existing rows for
  //    that menu_item_id first so updates to RECIPES above propagate cleanly,
  //    but we leave any menu_item that isn't in our config untouched (so
  //    custom user data isn't wiped).
  for (const [menuItemIdStr, recipe] of Object.entries(RECIPES)) {
    const menuItemId = Number(menuItemIdStr);

    // Make sure the menu item exists before touching its recipe.
    const [[exists]] = await db.query('SELECT COUNT(*) AS c FROM menu_items WHERE id = ?', [menuItemId]);
    if (!exists || Number(exists.c) === 0) continue;

    // ---- ingredients ------------------------------------------------------
    await db.query('DELETE FROM recipes WHERE menu_item_id = ?', [menuItemId]);
    for (const line of recipe.ingredients) {
      const ingId = nameToId.get(line.name);
      if (!ingId) continue;
      await db.query(
        'INSERT INTO recipes (menu_item_id, ingredient_id, quantity_required) VALUES (?, ?, ?)',
        [menuItemId, ingId, line.qty]
      );
    }

    // ---- prep steps -------------------------------------------------------
    await db.query('DELETE FROM menu_item_steps WHERE menu_item_id = ?', [menuItemId]);
    let stepNo = 1;
    for (const step of recipe.steps) {
      await db.query(
        'INSERT INTO menu_item_steps (menu_item_id, step_no, text) VALUES (?, ?, ?)',
        [menuItemId, stepNo++, step]
      );
    }
  }

  // 4) Bundling Duo + Trio (categories 4 & 5) are FULL menu items — the
  //    customer-facing menu and CMS Menu Manager both show them. We just keep
  //    them out of the "Recipes" page (handled in cmsController.getRecipesFull
  //    by an explicit category filter). Make sure they stay `is_available=1`
  //    in case an old migration flipped them off.
  for (const catId of SOFT_HIDE_CATEGORY_IDS) {
    await db.query('UPDATE menu_items SET is_available = 1 WHERE category_id = ?', [catId]);
    try {
      await db.query('UPDATE menu SET is_Available = 1 WHERE category_id = ?', [catId]);
    } catch (_) { /* legacy table may not exist on every install */ }
  }
}

module.exports = {
  INGREDIENTS,
  RECIPES,
  SOFT_HIDE_CATEGORY_IDS,
  seedRecipesAndIngredients,
};
