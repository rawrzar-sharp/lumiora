-- =========================================================================
-- Lumiora — Migration 2026_07 (round-4)
-- Run this ONCE in phpMyAdmin against the `cafe_db` database.
-- =========================================================================
-- This migration introduces a richer customization model:
--   • menu_items.customization_options now exposes `preference_groups`
--     (one labelled group per axis: Ice Level / Sugar Level / Coffee Bean /
--      Temperature / Spice Level / Style). The legacy `preferences` array is
--      kept so older Flutter builds keep working.
--   • order_items gains `preferences_json` + `addons_json` so the kitchen
--     (CMS Orders page) can see exactly what each cup needs.
-- =========================================================================

SET @db := DATABASE();

-- -------------------------------------------------------------------------
-- 1. ADD order_items.preferences_json / addons_json (idempotent)
-- -------------------------------------------------------------------------
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'order_items'
              AND COLUMN_NAME = 'preferences_json');
SET @sql := IF(@c = 0,
  'ALTER TABLE `order_items` ADD COLUMN `preferences_json` JSON NULL AFTER `price_at_sale`',
  'SELECT "order_items.preferences_json already exists" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'order_items'
              AND COLUMN_NAME = 'addons_json');
SET @sql := IF(@c = 0,
  'ALTER TABLE `order_items` ADD COLUMN `addons_json` JSON NULL AFTER `preferences_json`',
  'SELECT "order_items.addons_json already exists" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'order_items'
              AND COLUMN_NAME = 'notes');
SET @sql := IF(@c = 0,
  'ALTER TABLE `order_items` ADD COLUMN `notes` TEXT NULL AFTER `addons_json`',
  'SELECT "order_items.notes already exists" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- -------------------------------------------------------------------------
-- 2. NEW customization_options PAYLOAD per category
-- -------------------------------------------------------------------------

-- 2.1 Core Coffee & Lattes — Ice / Sugar / Bean
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
    'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                              'Half Sugar (50%)', 'Slight Sugar (25%)', 'No Sugar'),
    'Coffee Bean', JSON_ARRAY('Standard', 'Strong')
  ),
  'addons', JSON_OBJECT(
    'Oat Milk Upgrade', 8000,
    'Almond Milk Upgrade', 9000,
    'Extra Espresso Shot', 5000,
    'Caramel Drizzle', 4000,
    'Vanilla Syrup', 4000
  )
) WHERE id IN (1, 3, 4, 5, 6, 9, 10, 11, 12, 14, 15, 16);

-- 2.2 Aren Lattes — Ice / Sugar only (no bean choice on signature drinks)
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
    'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                              'Half Sugar (50%)', 'Slight Sugar (25%)')
  ),
  'addons', JSON_OBJECT(
    'Extra Palm Sugar', 3000,
    'Sea Salt Cream Foam', 5000,
    'Coffee Jelly Topping', 4000,
    'Oat Milk Upgrade', 8000
  )
) WHERE id IN (2, 7, 8);

-- 2.3 Non-Coffee — Ice / Sugar
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Ice Level',   JSON_ARRAY('Hot', 'Less Ice', 'Normal Ice'),
    'Sugar Level', JSON_ARRAY('Normal Sugar (100%)', 'Less Sugar (75%)',
                              'Half Sugar (50%)', 'Slight Sugar (25%)', 'No Sugar')
  ),
  'addons', JSON_OBJECT(
    'Strawberry Puree', 5000,
    'Matcha Cold Foam', 6000,
    'Chewy Boba Pearls', 4000,
    'Soy Milk Upgrade', 7000
  )
) WHERE id IN (17, 18, 19);

-- 2.4 Bundles — single Style group
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Style', JSON_ARRAY('All Iced', 'All Hot', 'Mix (Please add to notes)')
  ),
  'addons', JSON_OBJECT(
    'Upgrade All to Large', 15000,
    'Add Greeting Card', 5000,
    'Premium Carrier Bag', 3000,
    'Add 3 Butter Croissants', 25000
  )
) WHERE id BETWEEN 20 AND 28;

-- 2.5 Savory pastries — Temperature group
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Temperature', JSON_ARRAY('Toasted & Warmed', 'Room Temperature')
  ),
  'addons', JSON_OBJECT(
    'Extra Melted Cheese', 5000,
    'Spicy Mayo Dip', 3000,
    'Truffle Oil Splash', 6000,
    'Smoked Beef Slice', 7000
  )
) WHERE id IN (29, 30, 33);

-- 2.6 Sweet pastries — Temperature group
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Temperature', JSON_ARRAY('Warmed Up (Gooey)', 'Normal')
  ),
  'addons', JSON_OBJECT(
    'Vanilla Ice Cream Scoop', 8000,
    'Melted Chocolate Pour', 5000,
    'Matcha Powder Dusting', 2000,
    'Extra Butter Portion', 3000
  )
) WHERE id IN (31, 32, 34, 35);

-- 2.7 Skewers / Kitchen Snacks — Spice Level group
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preference_groups', JSON_OBJECT(
    'Spice Level', JSON_ARRAY('Mild', 'Medium Spicy', 'Volcano Spicy', 'Sweet Soy Sauce Only')
  ),
  'addons', JSON_OBJECT(
    'Nori Seaweed Flakes', 2000,
    'Extra Gochujang Sauce', 4000,
    'Mozzarella Wrap', 7000,
    'Garlic Mayo Drizzle', 3000
  )
) WHERE id BETWEEN 36 AND 40;

-- =========================================================================
-- DONE. Verify:
--   SELECT id, name, JSON_KEYS(customization_options -> '$.preference_groups')
--     FROM menu_items ORDER BY id;
--   SHOW COLUMNS FROM order_items LIKE 'preferences_json';
-- =========================================================================
