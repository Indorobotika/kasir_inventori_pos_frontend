USE `kasir_inventori_db`;

START TRANSACTION;

-- 1. Hapus tabel anak / relasi terlebih dahulu
DELETE FROM `order_details`;
DELETE FROM `order_cancellation_reports`;
DELETE FROM `product_prices_platform`;
DELETE FROM `product_recipes`;

-- 2. Hapus transaksi & arus kas
DELETE FROM `orders`;
DELETE FROM `cashflows`;

-- 3. Hapus master produk, bahan baku, kategori, promo & pengaturan
DELETE FROM `products`;
DELETE FROM `raw_materials`;
DELETE FROM `categories`;
DELETE FROM `promotions`;
DELETE FROM `settings`;

-- 4. Reset AUTO_INCREMENT ke 1
ALTER TABLE `order_details` AUTO_INCREMENT = 1;
ALTER TABLE `order_cancellation_reports` AUTO_INCREMENT = 1;
ALTER TABLE `product_prices_platform` AUTO_INCREMENT = 1;
ALTER TABLE `product_recipes` AUTO_INCREMENT = 1;
ALTER TABLE `orders` AUTO_INCREMENT = 1;
ALTER TABLE `cashflows` AUTO_INCREMENT = 1;
ALTER TABLE `products` AUTO_INCREMENT = 1;
ALTER TABLE `raw_materials` AUTO_INCREMENT = 1;
ALTER TABLE `categories` AUTO_INCREMENT = 1;
ALTER TABLE `promotions` AUTO_INCREMENT = 1;
ALTER TABLE `settings` AUTO_INCREMENT = 1;

COMMIT;