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
  `customization_options` JSON NULL,
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

CREATE TABLE IF NOT EXISTS `customers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `contact_info` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `name` VARCHAR(100) DEFAULT 'Guest',
  `loyalty_stamps` INT DEFAULT 0,
  `vouchers` INT DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO `customers` (`contact_info`, `password`, `name`, `loyalty_stamps`, `vouchers`) 
VALUES ('test@lumiora.com', '$2a$10$XyT5zN7e5N1yQJz8ZJ5a2O1bHq0z8G3b3/9KjG6V8U5e8e8e8e8e8', 'Test Customer', 0, 0);

-- Create `users` table used by the Express auth controllers (if not present)
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` VARCHAR(20) NOT NULL DEFAULT 'staff',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================================
-- 2. CORE SEED DATA (Menu Categories & Menu Items)
-- =========================================================================

INSERT INTO `menu_categories` (`id`, `name`, `printer_target`) VALUES
(1, 'Latte Series', 'Beverages'),
(2, 'Classics', 'Beverages'),
(3, 'Non-Coffee', 'Beverages'),
(4, 'Bundling Duo', 'Beverages'),
(5, 'Bundling Trio', 'Beverages'),
(6, 'Pastry & Bakery', 'Pastry'),
(7, 'Skewers', 'Kitchen');

INSERT INTO `menu_items` (`id`, `category_id`, `name`, `description`, `base_price`, `is_recommended`, `image_url`) VALUES
-- -----------------------------------------
-- LATTE SERIES (Category 1)
-- -----------------------------------------
(1, 1, 'Latte', 'Classic espresso with creamy steamed milk', 22000.00, 1, 'assets/images/latte.png'),
(2, 1, 'Aren Latte', 'Signature latte balanced with authentic palm sugar', 22000.00, 1, 'assets/images/arenlatte.png'),
(3, 1, 'Caramel Latte', 'Sweet caramel syrup infused with smooth latte', 25000.00, 0, 'assets/images/caramel.png'),
(4, 1, 'Hazelnut Latte', 'Roasted hazelnut flavors in a rich milk coffee', 25000.00, 0, 'assets/images/hazelnut.png'),
(5, 1, 'Vanilla Latte', 'Classic sweet vanilla notes with rich espresso', 25000.00, 0, 'assets/images/vanillalatte.png'),
(6, 1, 'Butterscotch Latte', 'Rich and buttery caramel notes in espresso', 25000.00, 1, 'assets/images/butterscotch.png'),
(7, 1, 'Buttercream Aren Latte', 'Creamy butter topping on our signature Aren Latte', 25000.00, 1, 'assets/images/buttercream.png'),
(8, 1, 'Creamy Aren Latte', 'Extra creamy version of the classic Aren Latte', 25000.00, 0, 'assets/images/creamyaren.png'),
(9, 1, 'Pandan Latte', 'Local pandan infusion for a fragrant coffee experience', 25000.00, 0, 'assets/images/pandan.png'),
(10, 1, 'Avocado Latte', 'Smooth avocado blended with espresso and milk', 25000.00, 0, 'assets/images/avocado.png'),
(11, 1, 'Banana Latte', 'Sweet banana notes perfectly paired with coffee', 25000.00, 0, 'assets/images/bananalatte.png'),
(12, 1, 'Coconut Latte', 'Tropical coconut flavors in a creamy latte', 25000.00, 0, 'assets/images/coconut.png'),
(13, 2, 'Espresso', 'A strong and bold single shot of coffee', 15000.00, 0, 'assets/images/espresso.png'),
(14, 2, 'Americano', 'Classic black coffee, simple and awakening', 17000.00, 1, 'assets/images/americano.png'),
(15, 2, 'Cappucino', 'Equal parts espresso, steamed milk, and thick foam', 22000.00, 0, 'assets/images/cappucino.png'),
(16, 2, 'Caffe Mocha', 'Chocolate and coffee combined for a sweet kick', 25000.00, 1, 'assets/images/caffemacha.png'),
(17, 3, 'Chocolate', 'Rich and creamy iced chocolate drink', 25000.00, 0, 'assets/images/chocolate.png'),
(18, 3, 'Matcha Latte', 'Earthy matcha blended with creamy milk', 25000.00, 0, 'assets/images/matchalatte.png'),
(19, 3, 'Strawberry Matcha Latte', 'Premium Japanese matcha with creamy milk and strawberry jam', 27000.00, 1, 'assets/images/strawberrymatcha.png'),
(20, 4, 'Twin Brew', '2 Cups of Americano', 30000.00, 0, 'assets/images/twinbrew.png'),
(21, 4, 'Signature Pair', 'Aren Latte + Americano', 35000.00, 1, 'assets/images/signaturepair.png'),
(22, 4, 'Nusantara Duo', '2 Cups of Aren Latte', 40000.00, 1, 'assets/images/nusantaraduo.png'),
(23, 4, 'The Classics Duo', '2 Cups of Latte', 40000.00, 0, 'assets/images/signaturepair.png'),
(24, 4, 'Double Choc', '2 Cups of Chocolate', 45000.00, 0, 'assets/images/doublechoco.png'),
(25, 5, 'Mood Booster', '3 Cups of Americano', 45000.00, 0, 'assets/images/moodbooster.png'),
(26, 5, 'Triple Treat', 'Hazelnut, Vanilla, and Caramel Latte', 60000.00, 1, 'assets/images/tripletreat.png'),
(27, 5, 'Sweetie Sweet', 'Pandan, Avocado, and Coconut Latte', 60000.00, 0, 'assets/images/sweetiesweet.png'),
(28, 5, 'House Favorites', 'Butterscotch, Matcha, and Chocolate', 60000.00, 1, 'assets/images/housefav.png'),
(29, 6, 'Egg Sando', 'Classic Japanese-style egg sandwich', 12000.00, 1, 'assets/images/eggsando.png'),
(30, 6, 'Ham n Cheese Croissant', 'Savory ham and cheese stuffed croissant', 18000.00, 1, 'assets/images/hamandcheese.png'),
(31, 6, 'Dark Choco Brownies', 'Rich and fudgy dark chocolate brownies', 15000.00, 1, 'assets/images/brownies.png'),
(32, 6, 'Chocochips Muffin', 'Soft muffin baked with chocolate chips', 10000.00, 0, 'assets/images/chocomuffin.png'),
(33, 6, 'Mac n Cheese', 'Creamy baked macaroni and cheese', 12000.00, 1, 'assets/images/macandcheese.png'),
(34, 6, 'Chocochips Cookies', 'Classic crunchy chocolate chip cookies', 12000.00, 0, 'assets/images/chocochip.png'),
(35, 6, 'Butter Croissant', 'Flaky and buttery golden croissant', 10000.00, 0, 'assets/images/croissant.png'),
(36, 7, 'Odeng', 'Korean fish cake skewer', 10000.00, 1, 'assets/images/odeng.png'),
(37, 7, 'Fish ball', 'Savory fish ball skewer', 10000.00, 0, 'assets/images/fishball.png'),
(38, 7, 'Cheese Dumpling', 'Dumpling filled with melted cheese', 10000.00, 1, 'assets/images/cheesedumpling.png'),
(39, 7, 'Chikuwa', 'Japanese tube-shaped fish paste', 8000.00, 0, 'assets/images/chikuwa.png'),
(40, 7, 'Fish Tofu', 'Soft and bouncy fish tofu', 12000.00, 0, 'assets/images/fishtofu.png');

-- =============================================================================================================

CREATE TABLE IF NOT EXISTS `category` (
  `id` INT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `menu` (
  `id` INT PRIMARY KEY,
  `category_id` INT NOT NULL,
  `item_name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `image_url` VARCHAR(255) NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `stock` INT NOT NULL DEFAULT 50,
  `is_Available` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Populate legacy `category` from `menu_categories` if empty
INSERT INTO `category` (`id`, `name`)
SELECT id, name FROM menu_categories
WHERE NOT EXISTS (SELECT 1 FROM category);




-- Populate legacy `menu` from `menu_items` if empty
INSERT INTO `menu` (`id`, `category_id`, `item_name`, `description`, `image_url`, `price`, `stock`, `is_Available`)
SELECT id, category_id, name, description, image_url, base_price, 50, is_available
FROM menu_items
WHERE NOT EXISTS (SELECT 1 FROM menu);

-- Add basic foreign key to maintain integrity if desired (optional)
ALTER TABLE `menu` 
  ADD CONSTRAINT `fk_menu_category_idx` FOREIGN KEY (`category_id`) REFERENCES `category`(`id`) ON DELETE RESTRICT;

UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Normal Ice', 'Less Ice', 'No Ice', 'Hot'),
  'addons',      JSON_OBJECT('Extra Shot Espresso', 5000, 'Oat Milk Upgrade', 8000, 'Caramel Drizzle', 4000, 'Vanilla Syrup', 4000)
) WHERE id BETWEEN 1 AND 18;

-- Sweet/Signature Drinks specifically getting Sugar Options
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Normal Sugar', 'Less Sugar', 'No Sugar'),
  'addons',      JSON_OBJECT('Extra Shot Espresso', 5000, 'Oat Milk Upgrade', 8000)
) WHERE id IN (2, 7, 8, 17, 18); -- Aren, Buttercream Aren, Chocolate, Matcha

-- Bundling (Duos and Trios)
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('All Iced', 'All Hot', 'Mixed (Notes required)'),
  'addons',      JSON_OBJECT('Upgrade All to Large', 15000, 'Paper Carrier Bag', 2000)
) WHERE id BETWEEN 19 AND 27;

-- Pastry & Bakery
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Warm/Toasted', 'Room Temperature'),
  'addons',      JSON_OBJECT('Extra Butter', 3000, 'Strawberry Jam', 4000)
) WHERE id IN (28, 29);

-- Kitchen / Savory
UPDATE menu_items SET customization_options = JSON_OBJECT(
  'preferences', JSON_ARRAY('Mild', 'Medium Spicy', 'Extra Spicy'),
  'addons',      JSON_OBJECT('Extra Cheese', 6000, 'Add Fried Egg', 5000)
) WHERE id = 30;


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
(6, 6, 1.00),
-- Matcha Latte (Item 18) requires Matcha Powder and Milk
(18, 7, 15.00),
(18, 2, 200.00);

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