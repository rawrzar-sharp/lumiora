SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `report_hourly_orders_daily`;
DROP TABLE IF EXISTS `report_item_sales_daily`;
DROP TABLE IF EXISTS `report_daily_sales`;
DROP TABLE IF EXISTS `order_items`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `recipes`;
DROP TABLE IF EXISTS `menu_items`;
DROP TABLE IF EXISTS `menu_categories`;
DROP TABLE IF EXISTS `ingredients`;
SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================================
-- 1. TABLE STRUCTURES
-- =========================================================================

CREATE TABLE `ingredients` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `stock_quantity` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `unit` VARCHAR(20) NOT NULL, 
  `low_stock_threshold` DECIMAL(10,2) NOT NULL DEFAULT 10.00,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `menu_categories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL, 
  `printer_target` ENUM('Beverages', 'Pastry', 'Kitchen') NOT NULL, 
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `menu_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `category_id` INT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `base_price` DECIMAL(10,2) NOT NULL,
  `is_recommended` TINYINT(1) NOT NULL DEFAULT 0,
  `image_url` VARCHAR(255) NULL,
  `customization_options` JSON NULL,     -- <<<< TAMBAH INI
  `is_available` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`category_id`) REFERENCES `menu_categories`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `recipes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `menu_item_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  `quantity_required` DECIMAL(10,2) NOT NULL, 
  FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `orders` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_number` VARCHAR(20) NOT NULL UNIQUE, 
  `order_type` ENUM('dine_in', 'takeaway') NOT NULL,
  `pickup_time` DATETIME NULL DEFAULT NULL, 
  `payment_method` ENUM('qris', 'debit', 'cc', 'cashier') NOT NULL,
  `payment_status` ENUM('pending_verification', 'paid', 'failed') NOT NULL DEFAULT 'pending_verification',
  `order_status` ENUM('pending', 'preparing', 'ready', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending',
  `total_amount` DECIMAL(10,2) NOT NULL,
  `payment_proof_url` VARCHAR(255) NULL, 
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `order_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `menu_item_id` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `price_at_sale` DECIMAL(10,2) NOT NULL, 
  FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Reporting Summary Tables (Target Tables for Python Pipeline)
CREATE TABLE `report_daily_sales` (
  `report_date` DATE PRIMARY KEY,
  `total_sales` DECIMAL(15,2) NOT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_item_sales_daily` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `report_date` DATE NOT NULL,
  `menu_item_id` INT NOT NULL,
  `item_name` VARCHAR(100) NOT NULL, 
  `total_quantity_sold` INT NOT NULL,
  `total_revenue` DECIMAL(12,2) NOT NULL,
  UNIQUE KEY `idx_date_item` (`report_date`, `menu_item_id`),
  FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_hourly_orders_daily` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `report_date` DATE NOT NULL,
  `order_hour` INT NOT NULL, 
  `total_quantity_ordered` INT NOT NULL,
  UNIQUE KEY `idx_date_hour` (`report_date`, `order_hour`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =========================================================================
-- 2. CORE SEED DATA (Menu Categories & Menu Items)
-- =========================================================================

INSERT INTO `menu_categories` (`id`, `name`, `printer_target`) VALUES
(1, 'Brunch', 'Kitchen'),
(2, 'Pastry', 'Pastry'),
(3, 'Coffee', 'Beverages'),
(4, 'Non-Coffee', 'Beverages'),
(5, 'Trio Deals', 'Kitchen');

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `base_price`, `is_recommended`, `image_url`) VALUES
-- Brunch
(1, 1, 'Truffle Scramble Egg Toast',   'Creamy truffle scrambled eggs on toasted brioche',          35000.00, 1, 'assets/images/prod_brunch_deals.png'),
(2, 1, 'Smoked Brisket Hash',          'Tender smoked brisket with crispy potato hash',             45000.00, 1, 'assets/images/prod_brunch_deals (2).png'),
(3, 1, 'Spicy Tuna Sando',             'Delicious signature sando with crisp tuna mix',             35000.00, 0, 'assets/images/sando(new_bonus_unlock).png'),
-- Pastry
(4, 2, 'Pistachio Raspberry Croissant','Flaky croissant with rich pistachio cream and raspberry',   30000.00, 1, 'assets/images/crossait(new_bonus_unlock).png'),
(5, 2, 'Butter Croissant',             'Classic golden French butter croissant',                    18000.00, 0, 'assets/images/crossait(new_bonus_unlock).png'),
(6, 2, 'Croissant Crisp',              'Flaky butter croissant baked flat and crunchy',             15000.00, 0, 'assets/images/crossait(new_bonus_unlock).png'),
-- Coffee
(7, 3, 'Iced Sea Salt Latte',          'Espresso over cold milk topped with creamy sea salt foam',  28000.00, 1, 'assets/images/prod_coffee_splash.png'),
(8, 3, 'Salted Caramel Latte',         'Smooth espresso blended with sweet and salty caramel',      25000.00, 1, 'assets/images/prod_triple_brew.png'),
(9, 3, 'Americano',                    'Classic bold espresso over water',                          20000.00, 0, 'assets/images/prod_coffee_splash.png'),
-- Non-Coffee
(10, 4, 'Matcha Strawberry',           'Premium matcha layered with fresh strawberry puree',        28000.00, 1, 'assets/images/prod_triple_brew.png'),
(11, 4, 'Iced Chocolate',              'Rich and creamy iced cocoa',                                25000.00, 0, 'assets/images/prod_triple_brew.png'),
(12, 4, 'Lychee Tea',                  'Refreshing iced tea with sweet lychee pieces',              20000.00, 0, 'assets/images/prod_triple_brew.png'),
-- Trio Deals
(13, 5, 'Spicy Tuna Sando + Drink',    'Combo Set: Signature tuna sando + chilled drink',           50000.00, 1, 'assets/images/prod_trio_cafe.png'),
(14, 5, 'Pistachio Croissant + Drink', 'Combo Set: Flaky pistachio pastry + beverage',              55000.00, 1, 'assets/images/Triplecafe(new_bonus_unlock).png');

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Extra Butter','Regular','Lesser Butter'),
  'addons',      JSON_OBJECT('Ham', 5000, 'Cheese', 7000, 'Extra Jam', 3000)
) WHERE id = 5;  -- Butter Croissant

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Extra Pistachio','Regular','Less Sweet'),
  'addons',      JSON_OBJECT('Vanilla Drizzle', 4000, 'Almond Flakes', 5000)
) WHERE id = 4;  -- Pistachio Raspberry Croissant

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Crunchy','Regular'),
  'addons',      JSON_OBJECT('Chocolate Dip', 4000, 'Caramel Sauce', 4000)
) WHERE id = 6;  -- Croissant Crisp

-- Brunch items: spice levels + addons
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Mild','Medium','Spicy'),
  'addons',      JSON_OBJECT('Extra Egg', 8000, 'Avocado Smash', 10000, 'Bacon', 12000)
) WHERE id = 1;  -- Truffle Scramble Egg Toast

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Mild','Medium','Spicy'),
  'addons',      JSON_OBJECT('Extra Brisket', 15000, 'Fried Egg', 8000)
) WHERE id = 2;  -- Smoked Brisket Hash

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Mild','Medium','Ghost Pepper'),
  'addons',      JSON_OBJECT('Extra Cheese', 5000, 'Avocado Smash', 8000)
) WHERE id = 3;  -- Spicy Tuna Sando

-- Coffee: sugar & ice + addons
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Less Sugar','Normal Sugar','Extra Sweet','No Ice','Less Ice'),
  'addons',      JSON_OBJECT('Extra Shot', 7000, 'Oat Milk', 8000, 'Whipped Cream', 5000)
) WHERE id IN (7, 8, 9);

-- Non-Coffee: sugar/ice
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Less Sugar','Normal Sugar','Extra Sweet','No Ice','Less Ice'),
  'addons',      JSON_OBJECT('Boba', 6000, 'Cheese Foam', 8000, 'Coconut Jelly', 5000)
) WHERE id IN (10, 11, 12);

-- Trio combos
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Coffee','Matcha','Chocolate'),
  'addons',      JSON_OBJECT('Upgrade to Large', 10000)
) WHERE id IN (13, 14);


-- =========================================================================
-- 3. INVENTORY & RECIPES SEED DATA
-- =========================================================================

INSERT INTO `ingredients` (`id`, `name`, `stock_quantity`, `unit`, `low_stock_threshold`) VALUES
(1, 'Espresso Beans', 5000.00, 'grams', 500.00),
(2, 'Fresh Milk', 12000.00, 'ml', 2000.00),
(3, 'Sea Salt Cream Foam', 3000.00, 'ml', 500.00),
(4, 'Tuna Mix Spread', 2500.00, 'grams', 400.00),
(5, 'Brioche Bread Slices', 80.00, 'pcs', 15.00),
(6, 'Croissant Dough Sheet', 100.00, 'pcs', 20.00),
(7, 'Matcha Powder', 1000.00, 'grams', 150.00);

INSERT INTO `recipes` (`menu_item_id`, `ingredient_id`, `quantity_required`) VALUES
-- Iced Sea Salt Latte (Item 7) requires Espresso, Milk, and Cream Foam
(7, 1, 18.00),
(7, 2, 150.00),
(7, 3, 50.00),
-- Spicy Tuna Sando (Item 3) requires Tuna Mix and Brioche Bread
(3, 4, 120.00),
(3, 5, 2.00),
-- Croissant Crisp (Item 6) requires 1 pre-made dough piece
(6, 6, 1.00);


-- =========================================================================
-- 4. OPERATIONAL MOCK DATA (Raw Orders Spanning Multiple Days/Hours)
-- =========================================================================

-- Day 1: May 30, 2026
INSERT INTO `orders` (`id`, `order_number`, `order_type`, `payment_method`, `payment_status`, `order_status`, `total_amount`, `created_at`) VALUES
(1, 'LUM-20260530-001', 'dine_in', 'qris', 'paid', 'delivered', 63000.00, '2026-05-30 09:15:00'),
(2, 'LUM-20260530-002', 'takeaway', 'cashier', 'paid', 'delivered', 33000.00, '2026-05-30 14:30:00');

INSERT INTO `order_items` (`order_id`, `menu_item_id`, `quantity`, `price_at_sale`) VALUES
(1, 1, 1, 35000.00), -- Truffle Scramble Egg Toast
(1, 7, 1, 28000.00), -- Iced Sea Salt Latte
(2, 5, 1, 18000.00), -- Butter Croissant
(2, 6, 1, 15000.00); -- Croissant Crisp

-- Day 2: May 31, 2026
INSERT INTO `orders` (`id`, `order_number`, `order_type`, `payment_method`, `payment_status`, `order_status`, `total_amount`, `created_at`) VALUES
(3, 'LUM-20260531-001', 'dine_in', 'debit', 'paid', 'delivered', 50000.00, '2026-05-31 10:05:00'),
(4, 'LUM-20260531-002', 'takeaway', 'qris', 'paid', 'delivered', 110000.00, '2026-05-31 10:45:00'),
(5, 'LUM-20260531-003', 'dine_in', 'qris', 'paid', 'delivered', 56000.00, '2026-05-31 16:20:00');

INSERT INTO `order_items` (`order_id`, `menu_item_id`, `quantity`, `price_at_sale`) VALUES
(3, 13, 1, 50000.00), -- Spicy Tuna Sando + Drink
(4, 14, 2, 55000.00), -- Pistachio Croissant + Drink (Qty: 2)
(5, 7, 2, 28000.00); -- Iced Sea Salt Latte (Qty: 2)


-- =========================================================================
-- 5. ANALYTICS PRE-POPULATED DATA (What Looker Studio reads)
-- =========================================================================

-- Daily Summaries
INSERT INTO `report_daily_sales` (`report_date`, `total_sales`) VALUES
('2026-05-30', 96000.00),
('2026-05-31', 216000.00);

-- Item Sales Summaries
INSERT INTO `report_item_sales_daily` (`report_date`, `menu_item_id`, `item_name`, `total_quantity_sold`, `total_revenue`) VALUES
('2026-05-30', 1, 'Truffle Scramble Egg Toast', 1, 35000.00),
('2026-05-30', 7, 'Iced Sea Salt Latte', 1, 28000.00),
('2026-05-30', 5, 'Butter Croissant', 1, 18000.00),
('2026-05-30', 6, 'Croissant Crisp', 1, 15000.00),
('2026-05-31', 13, 'Spicy Tuna Sando + Drink', 1, 50000.00),
('2026-05-31', 14, 'Pistachio Croissant + Drink', 2, 110000.00),
('2026-05-31', 7, 'Iced Sea Salt Latte', 2, 56000.00);

-- Hourly Load Volume Summaries
INSERT INTO `report_hourly_orders_daily` (`report_date`, `order_hour`, `total_quantity_ordered`) VALUES
('2026-05-30', 9, 2),   -- 9 AM items
('2026-05-30', 14, 2),  -- 2 PM items
('2026-05-31', 10, 3),  -- 10 AM items
('2026-05-31', 16, 2);  -- 4 PM items