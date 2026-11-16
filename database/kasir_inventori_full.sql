-- Full Database Schema & Initial Seed Data: Kasir & Inventori POS
CREATE DATABASE IF NOT EXISTS `kasir_inventori_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `kasir_inventori_db`;

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `role` enum('owner','admin','kasir') NOT NULL DEFAULT 'owner',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL UNIQUE,
  `image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

CREATE TABLE `raw_materials` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `unit` varchar(50) NOT NULL,
  `stock` decimal(15,3) NOT NULL DEFAULT 0.000,
  `min_stock` decimal(15,3) NOT NULL DEFAULT 1.000,
  `cost_price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

CREATE TABLE `products` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `sku` varchar(100) NOT NULL UNIQUE,
  `title` varchar(255) NOT NULL,
  `unit` varchar(50) NOT NULL DEFAULT 'pcs',
  `product_type` enum('retail','resep') NOT NULL DEFAULT 'retail',
  `cover` varchar(255) DEFAULT NULL,
  `cost_price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `stock` int(11) DEFAULT 0,
  `weight` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE CASCADE
);

CREATE TABLE `product_prices_platform` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `platform_name` varchar(100) NOT NULL,
  `price` decimal(15,2) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
);

CREATE TABLE `product_recipes` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `raw_material_id` bigint(20) UNSIGNED NOT NULL,
  `qty_needed` decimal(15,4) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`raw_material_id`) REFERENCES `raw_materials`(`id`) ON DELETE CASCADE
);

CREATE TABLE `promotions` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `typ_promotion_id` tinyint(1) NOT NULL COMMENT '1=Nominal (Rp), 2=Persen (%)',
  `required` decimal(15,2) NOT NULL DEFAULT 0.00,
  `result` decimal(15,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_number` varchar(100) NOT NULL UNIQUE,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `customer_name` varchar(150) DEFAULT 'Umum',
  `platform` varchar(100) NOT NULL DEFAULT 'Offline Store',
  `payment_method` enum('CASH','CARD','QRIS') NOT NULL DEFAULT 'CASH',
  `numberCard` varchar(100) DEFAULT NULL,
  `subtotal` decimal(15,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `tax` decimal(15,2) NOT NULL DEFAULT 0.00,
  `supplier_sales_tax` decimal(15,2) NOT NULL DEFAULT 0.00,
  `total_cost` decimal(15,2) NOT NULL DEFAULT 0.00,
  `total_bill` decimal(15,2) NOT NULL DEFAULT 0.00,
  `cash_received` decimal(15,2) DEFAULT 0.00,
  `cash_change` decimal(15,2) DEFAULT 0.00,
  `status` enum('pending','success','canceled') NOT NULL DEFAULT 'success',
  `qris_reference` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
);

CREATE TABLE `order_details` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `promotion_id` bigint(20) UNSIGNED DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `cost_product` decimal(15,2) NOT NULL DEFAULT 0.00,
  `price_product` decimal(15,2) NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`),
  FOREIGN KEY (`promotion_id`) REFERENCES `promotions`(`id`) ON DELETE SET NULL
);

CREATE TABLE `cashflows` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('IN','OUT') NOT NULL,
  `category` varchar(100) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `description` text DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
);

CREATE TABLE `settings` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `store_name` varchar(255) NOT NULL DEFAULT 'Toko Sejahtera',
  `location_store` text DEFAULT NULL,
  `contact` varchar(100) DEFAULT NULL,
  `logo_path_url` varchar(255) DEFAULT NULL,
  `tax` decimal(5,2) NOT NULL DEFAULT 11.00,
  `receipt_width` varchar(20) NOT NULL DEFAULT '58 mm',
  `receipt_footer` varchar(255) NOT NULL DEFAULT 'Terima kasih telah berbelanja',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

-- Seed Data Awal
INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`) VALUES
(1, 'indorobotika 01', 'indorobotika01@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner');

INSERT INTO `settings` (`id`, `store_name`, `location_store`, `contact`, `tax`, `receipt_width`, `receipt_footer`) VALUES
(1, 'Toko Sejahtera', 'Jl. Merdeka No. 12, Bandung', '0812-3456-7890', 11.00, '58 mm', 'Terima kasih telah berbelanja');

INSERT INTO `categories` (`id`, `name`, `slug`) VALUES
(1, 'Minuman', 'minuman'),
(2, 'Makanan', 'makanan'),
(3, 'Snack', 'snack'),
(4, 'Produk Rumahan', 'produk-rumahan');

INSERT INTO `raw_materials` (`id`, `name`, `unit`, `stock`, `min_stock`, `cost_price`) VALUES
(1, 'Biji Kopi', 'kg', 5.000, 1.000, 240000),
(2, 'Gula Aren Cair', 'liter', 6.000, 2.000, 25000),
(3, 'Jeruk Peras', 'kg', 4.000, 1.000, 20000),
(4, 'Keju Cheddar', 'kg', 3.000, 1.000, 90000),
(5, 'Mentega', 'kg', 10.000, 3.000, 24000),
(6, 'Susu UHT', 'liter', 12.000, 3.000, 18000),
(7, 'Telur', 'kg', 15.000, 4.000, 28000),
(8, 'Tepung Terigu', 'kg', 25.000, 5.000, 12000);

INSERT INTO `products` (`id`, `category_id`, `sku`, `title`, `unit`, `product_type`, `cost_price`, `price`, `stock`) VALUES
(1, 1, 'MNM-01', 'Air Mineral 600ml', 'botol', 'retail', 3000, 5000, 48),
(2, 3, 'SNK-01', 'Butter Croissant', 'pcs', 'retail', 11000, 20000, 12),
(3, 3, 'SNK-02', 'Choco Fudge Cake', 'slice', 'retail', 18000, 35000, 6),
(4, 1, 'MNM-02', 'Es Kopi Susu Gula Aren', 'cup', 'resep', 7770, 22000, 0),
(5, 3, 'SNK-03', 'Glazed Donut', 'pcs', 'retail', 7500, 15000, 15),
(6, 1, 'MNM-04', 'Jus Jeruk Segar', 'gelas', 'resep', 6500, 20000, 0),
(7, 1, 'MNM-03', 'Kopi Hitam Panas', 'cup', 'resep', 4800, 15000, 0),
(8, 2, 'MKN-01', 'Nasi Ayam Sambal Matah', 'porsi', 'retail', 20000, 38000, 10),
(9, 4, 'RMH-01', 'Nastar Keju 250g', 'box', 'resep', 22000, 45000, 0);

-- Resep Es Kopi Susu Gula Aren (20g Biji Kopi, 30ml Gula Aren, 150ml Susu UHT)
INSERT INTO `product_recipes` (`product_id`, `raw_material_id`, `qty_needed`) VALUES
(4, 1, 0.0200),
(4, 2, 0.0300),
(4, 6, 0.1500),
(6, 3, 0.2500),
(7, 1, 0.0200);

INSERT INTO `promotions` (`id`, `title`, `typ_promotion_id`, `required`, `result`, `is_active`) VALUES
(1, 'Diskon 10%', 2, 100000, 10, 1),
(2, 'Potongan 5.000', 1, 50000, 5000, 1);
