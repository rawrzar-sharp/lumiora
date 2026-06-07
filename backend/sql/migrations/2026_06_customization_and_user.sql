-- =========================================================================
-- Lumiora — Migration 2026_06
-- Run this ONCE in phpMyAdmin against the `cafe_db` database.
-- =========================================================================
--
-- Fixes covered by this script:
--   1. Adds `customization_options` JSON column to `menu_items` (if missing)
--      and populates it with the new preference/addon catalogue requested
--      by the team (Hot/Iced + sugar levels, aren series, non-coffee,
--      bundles, savory pastry, sweet pastry, skewers).
--   2. Relaxes `users.phone_no` (if it exists) so that POST /api/auth/register
--      stops failing with `Field 'phone_no' doesn't have a default value`.
--   3. Replaces the placeholder bcrypt hashes for the built-in CMS users
--      (`diamonddark269@gmail.com` / admin123 and `staff@lumiora.com` /
--      staff123) with REAL bcryptjs hashes so the CMS login works.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. CUSTOMIZATION OPTIONS COLUMN
-- -------------------------------------------------------------------------
-- The column already exists in the canonical schema (init.sql), but on
-- databases provisioned from older snapshots it may be missing. Adding via
-- a stored-routine trick keeps this migration idempotent.
SET @db := DATABASE();
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db
    AND TABLE_NAME = 'menu_items'
    AND COLUMN_NAME = 'customization_options'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `menu_items` ADD COLUMN `customization_options` JSON NULL AFTER `image_url`',
  'SELECT "menu_items.customization_options already exists" AS info');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- -------------------------------------------------------------------------
-- 2. SEED / UPDATE CUSTOMIZATION DATA (per user spec)
-- -------------------------------------------------------------------------

-- 2.1 Core Coffee & Lattes — Hot/Cold + sugar levels combined
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY(
    'Hot - Standard Bean', 'Hot - Strong Espresso',
    'Iced - Normal Sugar (100%)', 'Iced - Less Sugar (75%)',
    'Iced - Half Sugar (50%)', 'Iced - Slight Sugar (25%)', 'Iced - No Sugar'
  ),
  'addons', JSON_OBJECT(
    'Oat Milk Upgrade', 8000,
    'Almond Milk Upgrade', 9000,
    'Extra Espresso Shot', 5000,
    'Caramel Drizzle', 4000,
    'Vanilla Syrup', 4000
  )
) WHERE id IN (1, 3, 4, 5, 6, 9, 10, 11, 12, 14, 15, 16);

-- 2.2 Signature Aren Lattes — palm-sugar centric
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY(
    'Normal Sugar (100%)', 'Less Sugar (75%)',
    'Half Sugar (50%)', 'Slight Sugar (25%)'
  ),
  'addons', JSON_OBJECT(
    'Extra Palm Sugar', 3000,
    'Sea Salt Cream Foam', 5000,
    'Coffee Jelly Topping', 4000,
    'Oat Milk Upgrade', 8000
  )
) WHERE id IN (2, 7, 8);

-- 2.3 Non-Coffee Sweets — matcha/chocolate combos
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Normal Ice', 'Less Ice', 'No Ice', 'Hot'),
  'addons', JSON_OBJECT(
    'Strawberry Puree', 5000,
    'Matcha Cold Foam', 6000,
    'Chewy Boba Pearls', 4000,
    'Soy Milk Upgrade', 7000
  )
) WHERE id IN (17, 18, 19);

-- 2.4 Bundles (Duo + Trio)
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('All Iced', 'All Hot', 'Mix (Please add to notes)'),
  'addons', JSON_OBJECT(
    'Upgrade All to Large', 15000,
    'Add Greeting Card', 5000,
    'Premium Carrier Bag', 3000,
    'Add 3 Butter Croissants', 25000
  )
) WHERE id BETWEEN 20 AND 28;

-- 2.5 Savory Pastries & Sandwiches
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Toasted & Warmed', 'Room Temperature'),
  'addons', JSON_OBJECT(
    'Extra Melted Cheese', 5000,
    'Spicy Mayo Dip', 3000,
    'Truffle Oil Splash', 6000,
    'Smoked Beef Slice', 7000
  )
) WHERE id IN (29, 30, 33);

-- 2.6 Sweet Pastries
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Warmed Up (Gooey)', 'Normal'),
  'addons', JSON_OBJECT(
    'Vanilla Ice Cream Scoop', 8000,
    'Melted Chocolate Pour', 5000,
    'Matcha Powder Dusting', 2000,
    'Extra Butter Portion', 3000
  )
) WHERE id IN (31, 32, 34, 35);

-- 2.7 Skewers / Kitchen Snacks
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Mild', 'Medium Spicy', 'Volcano Spicy', 'Sweet Soy Sauce Only'),
  'addons', JSON_OBJECT(
    'Nori Seaweed Flakes', 2000,
    'Extra Gochujang Sauce', 4000,
    'Mozzarella Wrap', 7000,
    'Garlic Mayo Drizzle', 3000
  )
) WHERE id BETWEEN 36 AND 40;

-- -------------------------------------------------------------------------
-- 3. RELAX `users.phone_no` (only if the column exists)
-- -------------------------------------------------------------------------
SET @phone_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME = 'phone_no'
);
SET @sql := IF(@phone_exists = 1,
  'ALTER TABLE `users` MODIFY COLUMN `phone_no` VARCHAR(50) NULL DEFAULT NULL',
  'SELECT "users.phone_no not present — skipping" AS info');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- -------------------------------------------------------------------------
-- 4. REAL BCRYPT HASHES FOR THE BUILT-IN USERS
-- -------------------------------------------------------------------------
-- These hashes were generated with bcryptjs (rounds=10) and verified by the
-- backend's bcrypt.compare. If you want to rotate them, regenerate via
-- the helper endpoint `GET /fix-admin` on the backend instead.
--
--   admin123 → $2b$10$l2941.4eG0qThb2a86wLMeSDl/J4uw1QNf0EpggieKTuQWB9aaX02
--   staff123 → $2b$10$7zyQsIOZlWowqsSentRVF.zPyyy3Uq467Fn0G.Tbz5SdsC4K8gvua
UPDATE `users`
   SET `password_hash` = '$2b$10$l2941.4eG0qThb2a86wLMeSDl/J4uw1QNf0EpggieKTuQWB9aaX02',
       `role` = 'admin'
 WHERE `email` = 'diamonddark269@gmail.com';

UPDATE `users`
   SET `password_hash` = '$2b$10$7zyQsIOZlWowqsSentRVF.zPyyy3Uq467Fn0G.Tbz5SdsC4K8gvua',
       `role` = 'staff'
 WHERE `email` = 'staff@lumiora.com';

-- Backfill the rows if the seeds never ran
INSERT INTO `users` (`name`, `email`, `password_hash`, `role`)
SELECT 'Super Admin', 'diamonddark269@gmail.com',
       '$2b$10$l2941.4eG0qThb2a86wLMeSDl/J4uw1QNf0EpggieKTuQWB9aaX02', 'admin'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `users` WHERE `email` = 'diamonddark269@gmail.com');

INSERT INTO `users` (`name`, `email`, `password_hash`, `role`)
SELECT 'Staff Cafe', 'staff@lumiora.com',
       '$2b$10$7zyQsIOZlWowqsSentRVF.zPyyy3Uq467Fn0G.Tbz5SdsC4K8gvua', 'staff'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `users` WHERE `email` = 'staff@lumiora.com');

-- =========================================================================
-- DONE. Verify with:
--   SELECT id, name, email, role FROM users;
--   SELECT id, name, JSON_LENGTH(customization_options) AS opts
--     FROM menu_items ORDER BY id;
-- =========================================================================
