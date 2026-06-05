-- -- phpMyAdmin SQL Dump
-- -- version 5.2.1
-- -- https://www.phpmyadmin.net/
-- --
-- -- Host: 127.0.0.1
-- -- Generation Time: May 06, 2026 at 02:13 PM
-- -- Server version: 10.4.32-MariaDB
-- -- PHP Version: 8.2.12

-- SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
-- START TRANSACTION;
-- SET time_zone = "+00:00";


-- /*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
-- /*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
-- /*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
-- /*!40101 SET NAMES utf8mb4 */;

-- --
-- -- Database: `cafe_db`
-- --

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `category`
-- --

-- CREATE TABLE `category` (
--   `id` int(11) NOT NULL,
--   `name` enum('latte_series','classics','non_coffee') NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --
-- -- Dumping data for table `category`
-- --

-- INSERT INTO `category` (`id`, `name`) VALUES
-- (1, 'latte_series'),
-- (2, 'non_coffee'),
-- (3, 'classics');

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `checkout`
-- --

-- CREATE TABLE `checkout` (
--   `id` int(11) NOT NULL,
--   `orders_id` int(11) NOT NULL,
--   `payment_status` enum('cancelled','pending','paid','') NOT NULL,
--   `created_at` datetime NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `customer`
-- --

-- CREATE TABLE `customer` (
--   `id` int(11) NOT NULL,
--   `name` varchar(25) NOT NULL,
--   `email` varchar(30) NOT NULL,
--   `password_hash` varchar(255) NOT NULL,
--   `created_at` datetime NOT NULL,
--   `modified_at` datetime NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --
-- -- Dumping data for table `customer`
-- --

-- INSERT INTO `customer` (`id`, `name`, `email`, `password_hash`, `created_at`, `modified_at`) VALUES
-- (1, 'Stella', 'stella@uniji.ac.id', '$2b$10$dummyhashstring123456789', '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
-- (2, 'Arjuna', 'arjuna@uniji.ac.id', '$2b$10$dummyhashstring987654321', '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
-- (3, 'Budi Santoso', 'budi.santoso@gmail.com', '$2b$10$dummyhashstringabcdefghi', '0000-00-00 00:00:00', '0000-00-00 00:00:00'),
-- (4, 'Nisa', 'nisa@yahoo.com', '$2b$10$dummyhashstringzxcvbnm12', '0000-00-00 00:00:00', '0000-00-00 00:00:00');

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `menu`
-- --

-- CREATE TABLE `menu` (
--   `id` int(11) NOT NULL,
--   `category_id` int(11) NOT NULL,
--   `item_name` varchar(20) NOT NULL,
--   `description` varchar(255) NOT NULL,
--   `image_url` varchar(255) NOT NULL,
--   `price` int(6) NOT NULL,
--   `stock` int(3) NOT NULL,
--   `is_Available` tinyint(1) DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --
-- -- Dumping data for table `menu`
-- --

-- INSERT INTO `menu` (`id`, `category_id`, `item_name`, `description`, `image_url`, `price`, `stock`, `is_Available`) VALUES
-- (1, 3, 'Espresso', 'Classic espresso shot', '/assets/espresso.png', 15000, 50, 1),
-- (2, 3, 'Americano', 'Classic americano', '/assets/americano.png', 17000, 50, 1),
-- (3, 3, 'Cappucino', 'Classic cappucino', '/assets/cappucino.png', 22000, 50, 1),
-- (4, 3, 'Caffe Mocha', 'Classic caffe mocha', '/assets/mocha.png', 25000, 50, 1),
-- (5, 1, 'Latte', 'Signature latte', '/assets/latte.png', 22000, 50, 1),
-- (6, 1, 'Aren Latte', 'Sweet aren latte', '/assets/aren_latte.png', 22000, 50, 1),
-- (7, 1, 'Caramel Latte', 'Caramel infused latte', '/assets/caramel_latte.png', 25000, 50, 1),
-- (8, 1, 'Hazelnut Latte', 'Hazelnut latte', '/assets/hazelnut_latte.png', 25000, 50, 1),
-- (9, 1, 'Vanilla Latte', 'Vanilla latte', '/assets/vanilla_latte.png', 25000, 50, 1),
-- (10, 1, 'Butterscotch Latte', 'Butterscotch latte', '/assets/butterscotch.png', 25000, 50, 1),
-- (11, 1, 'Buttercream Aren', 'Buttercream aren latte', '/assets/buttercream.png', 25000, 50, 1),
-- (12, 1, 'Creamy Aren Latte', 'Creamy aren latte', '/assets/creamy_aren.png', 25000, 50, 1),
-- (13, 1, 'Pandan Latte', 'Pandan latte', '/assets/pandan_latte.png', 25000, 50, 1),
-- (14, 1, 'Avocado Latte', 'Avocado latte', '/assets/avocado_latte.png', 25000, 50, 1),
-- (15, 1, 'Banana Latte', 'Banana latte', '/assets/banana_latte.png', 25000, 50, 1),
-- (16, 1, 'Coconut Latte', 'Coconut latte', '/assets/coconut_latte.png', 25000, 50, 1),
-- (17, 2, 'Chocolate', 'Iced chocolate', '/assets/chocolate.png', 25000, 50, 1),
-- (18, 2, 'Matcha latte', 'Iced matcha latte', '/assets/matcha.png', 25000, 50, 1);

-- -- --------------------------------------------------------

-- --
-- -- Table structure for table `orders`
-- --

-- CREATE TABLE `orders` (
--   `id` int(11) NOT NULL,
--   `customer_id` int(11) NOT NULL,
--   `menu_id` int(11) NOT NULL,
--   `quantity` int(3) NOT NULL,
--   `ice_level` enum('iced','hot','','') NOT NULL,
--   `sugar_level` enum('less','normal','high') NOT NULL,
--   `total` int(6) NOT NULL,
--   `order_status` enum('cancelled','pending','success','') NOT NULL,
--   `created_at` datetime NOT NULL,
--   `modified_at` datetime NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- -- --------------------------------------------------------

-- --Bundle tableeee
-- CREATE TABLE bundles (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(100) NOT NULL,
--     description TEXT,
--     price DECIMAL(10, 2) NOT NULL,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- --
-- -- Table structure for table `user`
-- --

-- CREATE TABLE `user` (
--   `id` int(11) NOT NULL,
--   `name` varchar(25) NOT NULL,
--   `email` varchar(30) NOT NULL,
--   `password_hash` varchar(255) NOT NULL,
--   `role` varchar(10) NOT NULL,
--   `created_at` datetime NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --
-- -- Dumping data for table `user`
-- --

-- INSERT INTO `user` (`id`, `name`, `email`, `password_hash`, `role`, `created_at`) VALUES
-- (1, 'Stella', 'stella.admin@cafe.com', '$2b$10$dummyhashstring123456789', 'admin', '2026-04-30 08:00:00'),
-- (2, 'System Admin', 'sysadmin@cafe.com', '$2b$10$dummyhashstring987654321', 'admin', '2026-04-30 08:30:00'),
-- (3, 'Cafe Manager', 'manager@cafe.com', '$2b$10$dummyhashstringabcdefghi', 'admin', '2026-04-30 09:00:00');

-- --
-- -- Indexes for dumped tables
-- --

-- --
-- -- Indexes for table `category`
-- --
-- ALTER TABLE `category`
--   ADD UNIQUE KEY `unique_id` (`id`);

-- --
-- -- Indexes for table `checkout`
-- --
-- ALTER TABLE `checkout`
--   ADD UNIQUE KEY `unique_id` (`id`);

-- --
-- -- Indexes for table `customer`
-- --
-- ALTER TABLE `customer`
--   ADD UNIQUE KEY `unique_id` (`id`);

-- --
-- -- Indexes for table `menu`
-- --
-- ALTER TABLE `menu`
--   ADD UNIQUE KEY `unique_id` (`id`),
--   ADD KEY `category_menu` (`category_id`);

-- --
-- -- Indexes for table `orders`
-- --
-- ALTER TABLE `orders`
--   ADD UNIQUE KEY `unique_id` (`id`),
--   ADD KEY `customer_orders` (`customer_id`);

-- --
-- -- Indexes for table `user`
-- --
-- ALTER TABLE `user`
--   ADD UNIQUE KEY `unique_id` (`id`);

-- --
-- -- AUTO_INCREMENT for dumped tables
-- --

-- --
-- -- AUTO_INCREMENT for table `category`
-- --
-- ALTER TABLE `category`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

-- --
-- -- AUTO_INCREMENT for table `checkout`
-- --
-- ALTER TABLE `checkout`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

-- --
-- -- AUTO_INCREMENT for table `customer`
-- --
-- ALTER TABLE `customer`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

-- --
-- -- AUTO_INCREMENT for table `menu`
-- --
-- ALTER TABLE `menu`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

-- --
-- -- AUTO_INCREMENT for table `orders`
-- --
-- ALTER TABLE `orders`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

-- --
-- -- AUTO_INCREMENT for table `user`
-- --
-- ALTER TABLE `user`
--   MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

-- --
-- -- Constraints for dumped tables
-- --

-- --
-- -- Constraints for table `menu`
-- --
-- ALTER TABLE `menu`
--   ADD CONSTRAINT `category_menu` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`) ON UPDATE CASCADE;

-- --
-- -- Constraints for table `orders`
-- --
-- ALTER TABLE `orders`
--   ADD CONSTRAINT `customer_orders` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`) ON UPDATE CASCADE;
-- COMMIT;

-- /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
-- /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
-- /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;