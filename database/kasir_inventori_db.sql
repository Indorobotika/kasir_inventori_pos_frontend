-- phpMyAdmin SQL Dump
-- version 5.0.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 18 Nov 2026 pada 10.33
-- Versi server: 10.4.14-MariaDB
-- Versi PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `kasir_inventori_db`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `cashflows`
--

CREATE TABLE `cashflows` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('IN','OUT') NOT NULL,
  `category` varchar(100) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `description` text DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `cashflows`
--

INSERT INTO `cashflows` (`id`, `user_id`, `type`, `category`, `amount`, `description`, `transaction_date`, `created_at`, `updated_at`) VALUES
(1, 1, 'IN', 'Tambah Modal', '5000000.00', 'Modal usaha awal', '2026-11-18', '2026-11-17 21:07:37', '2026-11-17 21:07:37'),
(2, 1, 'OUT', 'Belanja Operasionl', '100000.00', 'Pembelian bahan baku', '2026-11-18', '2026-11-17 21:08:14', '2026-11-17 21:08:14'),
(3, 1, 'IN', 'Penjualan Kasir (Pelunasan Manual)', '5750.00', 'Pelunasan manual Order #INV-261117-79772974', '2026-11-18', '2026-11-17 23:24:43', '2026-11-17 23:24:43'),
(4, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '5550.00', 'Pelunasan Order #INV-261118-23499440', '2026-11-18', '2026-11-17 23:32:59', '2026-11-17 23:32:59'),
(5, 1, 'IN', 'Penjualan Kasir', '5550.00', 'Pendapatan Order #INV-261118-39522969', '2026-11-18', '2026-11-17 23:37:35', '2026-11-17 23:37:35'),
(6, 1, 'IN', 'Penjualan Kasir', '5550.00', 'Pendapatan Order #INV-261118-86573200', '2026-11-18', '2026-11-17 23:41:00', '2026-11-17 23:41:00'),
(7, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '11100.00', 'Pelunasan Order #INV-261118-86510903', '2026-11-18', '2026-11-17 23:48:06', '2026-11-17 23:48:06'),
(8, 1, 'IN', 'Penjualan Kasir', '27750.00', 'Pendapatan Order #INV-261118-38652207', '2026-11-18', '2026-11-17 23:55:14', '2026-11-17 23:55:14'),
(9, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '55944.00', 'Pelunasan Order #INV-261118-93841174', '2026-11-18', '2026-11-18 00:10:37', '2026-11-18 00:10:37'),
(10, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '5550.00', 'Pelunasan Order #INV-261118-65039380', '2026-11-18', '2026-11-18 00:39:55', '2026-11-18 00:39:55'),
(11, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '36630.00', 'Pelunasan Order #INV-261118-84315862', '2026-11-18', '2026-11-18 00:54:07', '2026-11-18 00:54:07'),
(12, 1, 'IN', 'Penjualan Kasir', '38850.00', 'Pendapatan Order #INV-261118-81122990', '2026-11-18', '2026-11-18 00:55:20', '2026-11-18 00:55:20'),
(13, 1, 'IN', 'Penjualan Kasir (QRIS/Pelunasan)', '5550.00', 'Pelunasan Order #INV-261118-21476820', '2026-11-18', '2026-11-18 02:27:02', '2026-11-18 02:27:02');

-- --------------------------------------------------------

--
-- Struktur dari tabel `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `image`, `created_at`, `updated_at`) VALUES
(1, 'Minuman', 'minuman', NULL, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(2, 'Makanan', 'makanan', NULL, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(3, 'Snack', 'snack', NULL, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(4, 'Produk Rumahan', 'produk-rumahan', NULL, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(5, 'SMARTFARMING', 'smartfarming', NULL, '2026-11-16 10:04:08', '2026-11-16 10:04:08'),
(6, 'Kopi', 'kopi', NULL, '2026-11-17 21:35:43', '2026-11-17 21:35:43');

-- --------------------------------------------------------

--
-- Struktur dari tabel `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_100000_create_password_resets_table', 1),
(2, '2019_12_14_000001_create_personal_access_tokens_table', 1);

-- --------------------------------------------------------

--
-- Struktur dari tabel `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `invoice_number` varchar(100) NOT NULL,
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
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `orders`
--

INSERT INTO `orders` (`id`, `invoice_number`, `user_id`, `customer_name`, `platform`, `payment_method`, `numberCard`, `subtotal`, `discount_amount`, `tax`, `supplier_sales_tax`, `total_cost`, `total_bill`, `cash_received`, `cash_change`, `status`, `qris_reference`, `created_at`, `updated_at`) VALUES
(1, 'INV-261117-79772974', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '5000.00', '0.00', '750.00', '0.00', '3000.00', '5750.00', '5750.00', '0.00', 'success', NULL, '2026-11-17 08:38:57', '2026-11-17 23:24:43'),
(2, 'INV-261118-23499440', 1, 'Tomy', 'Offline Store', 'QRIS', NULL, '5000.00', '0.00', '550.00', '0.00', '800.00', '5550.00', '5550.00', '0.00', 'success', NULL, '2026-11-17 23:32:46', '2026-11-17 23:32:59'),
(3, 'INV-261118-39522969', 1, 'Umum', 'Offline Store', 'CARD', '3456', '5000.00', '0.00', '550.00', '0.00', '800.00', '5550.00', '5550.00', '0.00', 'success', NULL, '2026-11-17 23:37:35', '2026-11-17 23:37:35'),
(4, 'INV-261118-86573200', 1, 'Umum', 'Offline Store', 'CASH', NULL, '5000.00', '0.00', '550.00', '0.00', '800.00', '5550.00', '5550.00', '0.00', 'success', NULL, '2026-11-17 23:41:00', '2026-11-17 23:41:00'),
(5, 'INV-261118-86510903', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '10000.00', '0.00', '1100.00', '0.00', '1600.00', '11100.00', '11100.00', '0.00', 'success', NULL, '2026-11-17 23:48:00', '2026-11-17 23:48:06'),
(6, 'INV-261118-38652207', 1, 'Umum', 'Offline Store', 'CASH', NULL, '25000.00', '0.00', '2750.00', '0.00', '4000.00', '27750.00', '27750.00', '0.00', 'success', NULL, '2026-11-17 23:55:14', '2026-11-17 23:55:14'),
(7, 'INV-261118-93841174', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '56000.00', '5600.00', '5544.00', '0.00', '26600.00', '55944.00', '55944.00', '0.00', 'success', NULL, '2026-11-18 00:10:33', '2026-11-18 00:10:37'),
(8, 'INV-261118-65039380', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '5000.00', '0.00', '550.00', '0.00', '800.00', '5550.00', '5550.00', '0.00', 'success', NULL, '2026-11-18 00:39:41', '2026-11-18 00:39:55'),
(9, 'INV-261118-84315862', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '33000.00', '0.00', '3630.00', '0.00', '14100.00', '36630.00', '36630.00', '0.00', 'success', NULL, '2026-11-18 00:54:01', '2026-11-18 00:54:07'),
(10, 'INV-261118-81122990', 1, 'Umum', 'Shopee', 'CASH', NULL, '35000.00', '0.00', '3850.00', '0.00', '18000.00', '38850.00', '38850.00', '0.00', 'success', NULL, '2026-11-18 00:55:20', '2026-11-18 00:55:20'),
(11, 'INV-261118-21476820', 1, 'Umum', 'Offline Store', 'QRIS', NULL, '5000.00', '0.00', '550.00', '0.00', '800.00', '5550.00', '5550.00', '0.00', 'success', NULL, '2026-11-18 02:26:54', '2026-11-18 02:27:02');

-- --------------------------------------------------------

--
-- Struktur dari tabel `order_details`
--

CREATE TABLE `order_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `promotion_id` bigint(20) UNSIGNED DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `cost_product` decimal(15,2) NOT NULL DEFAULT 0.00,
  `price_product` decimal(15,2) NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `order_details`
--

INSERT INTO `order_details` (`id`, `order_id`, `product_id`, `promotion_id`, `quantity`, `cost_product`, `price_product`, `subtotal`, `created_at`, `updated_at`) VALUES
(1, 1, 1, NULL, 1, '3000.00', '5000.00', '5000.00', '2026-11-17 08:38:57', '2026-11-17 08:38:57'),
(2, 2, 12, NULL, 1, '800.00', '5000.00', '5000.00', '2026-11-17 23:32:46', '2026-11-17 23:32:46'),
(3, 3, 12, NULL, 1, '800.00', '5000.00', '5000.00', '2026-11-17 23:37:35', '2026-11-17 23:37:35'),
(4, 4, 12, NULL, 1, '800.00', '5000.00', '5000.00', '2026-11-17 23:41:00', '2026-11-17 23:41:00'),
(5, 5, 12, NULL, 2, '800.00', '5000.00', '10000.00', '2026-11-17 23:48:00', '2026-11-17 23:48:00'),
(6, 6, 12, NULL, 5, '800.00', '5000.00', '25000.00', '2026-11-17 23:55:14', '2026-11-17 23:55:14'),
(7, 7, 12, 4, 2, '800.00', '5000.00', '10000.00', '2026-11-18 00:10:33', '2026-11-18 00:10:33'),
(8, 7, 10, 4, 1, '5000.00', '8000.00', '8000.00', '2026-11-18 00:10:33', '2026-11-18 00:10:33'),
(9, 7, 8, 4, 1, '20000.00', '38000.00', '38000.00', '2026-11-18 00:10:33', '2026-11-18 00:10:33'),
(10, 8, 12, NULL, 1, '800.00', '5000.00', '5000.00', '2026-11-18 00:39:41', '2026-11-18 00:39:41'),
(11, 9, 12, NULL, 2, '800.00', '5000.00', '10000.00', '2026-11-18 00:54:01', '2026-11-18 00:54:01'),
(12, 9, 10, NULL, 1, '5000.00', '8000.00', '8000.00', '2026-11-18 00:54:01', '2026-11-18 00:54:01'),
(13, 9, 5, NULL, 1, '7500.00', '15000.00', '15000.00', '2026-11-18 00:54:01', '2026-11-18 00:54:01'),
(14, 10, 3, NULL, 1, '18000.00', '35000.00', '35000.00', '2026-11-18 00:55:20', '2026-11-18 00:55:20'),
(15, 11, 12, NULL, 1, '800.00', '5000.00', '5000.00', '2026-11-18 02:26:54', '2026-11-18 02:26:54');

-- --------------------------------------------------------

--
-- Struktur dari tabel `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `created_at`, `updated_at`) VALUES
(1, 'App\\Models\\User', 1, 'pos-token', '4a3da905cb06410ca34a4dcbc61bda6ca91a211a055a76c21d8c52e505516e59', '[\"*\"]', NULL, '2026-11-16 09:55:37', '2026-11-16 09:55:37'),
(2, 'App\\Models\\User', 1, 'pos-token', '97b0cd972f0972b063c298df51721aebbbd273718c5596edd14b3c0166c4e088', '[\"*\"]', NULL, '2026-11-16 09:56:41', '2026-11-16 09:56:41'),
(5, 'App\\Models\\User', 1, 'pos-token', '0128df68895c3f50aa4a92882e0bd670424e862d366517fdbe829b72bfbf75f8', '[\"*\"]', NULL, '2026-11-17 19:49:21', '2026-11-17 19:49:21'),
(10, 'App\\Models\\User', 1, 'pos-token', 'dc15f6c16ba2bc86d7162e72914092a7568465569801b6f69aea52dd87d6d57d', '[\"*\"]', '2026-11-17 20:49:55', '2026-11-17 20:47:37', '2026-11-17 20:49:55'),
(11, 'App\\Models\\User', 1, 'pos-token', '9de13694d91608705d96260df01206f2e9a96b1b1ca862db7d17d68e99575387', '[\"*\"]', '2026-11-18 01:06:25', '2026-11-17 20:52:38', '2026-11-18 01:06:25'),
(12, 'App\\Models\\User', 1, 'pos-token', 'cf6f12e241fbf47d349d52b3a63614a459859346349e26e2920458511c2d4b74', '[\"*\"]', '2026-11-18 02:03:43', '2026-11-18 01:55:08', '2026-11-18 02:03:43');

-- --------------------------------------------------------

--
-- Struktur dari tabel `products`
--

CREATE TABLE `products` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `sku` varchar(100) NOT NULL,
  `title` varchar(255) NOT NULL,
  `unit` varchar(50) NOT NULL DEFAULT 'pcs',
  `product_type` enum('retail','resep') NOT NULL DEFAULT 'retail',
  `cover` varchar(255) DEFAULT NULL,
  `cost_price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `stock` int(11) DEFAULT 0,
  `weight` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `products`
--

INSERT INTO `products` (`id`, `category_id`, `sku`, `title`, `unit`, `product_type`, `cover`, `cost_price`, `price`, `stock`, `weight`, `created_at`, `updated_at`) VALUES
(1, 1, 'MNM-01', 'Air Mineral 600ml', 'botol', 'retail', NULL, '3000.00', '5000.00', 47, 0, '2026-11-16 16:52:35', '2026-11-17 08:38:57'),
(2, 3, 'SNK-01', 'Butter Croissant', 'pcs', 'retail', NULL, '11000.00', '20000.00', 12, 0, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(3, 3, 'SNK-02', 'Choco Fudge Cake', 'slice', 'retail', NULL, '18000.00', '35000.00', 5, 0, '2026-11-16 16:52:35', '2026-11-18 00:55:20'),
(4, 1, 'MNM-02', 'Es Kopi Susu Gula Aren', 'cup', 'resep', NULL, '7770.00', '22000.00', 0, 0, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(5, 3, 'SNK-03', 'Glazed Donut', 'pcs', 'retail', NULL, '7500.00', '15000.00', 14, 0, '2026-11-16 16:52:35', '2026-11-18 00:54:01'),
(6, 1, 'MNM-04', 'Jus Jeruk Segar', 'gelas', 'resep', NULL, '6500.00', '20000.00', 0, 0, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(7, 1, 'MNM-03', 'Kopi Hitam Panas', 'cup', 'resep', NULL, '4800.00', '15000.00', 0, 0, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(8, 2, 'MKN-01', 'Nasi Ayam Sambal Matah', 'porsi', 'retail', NULL, '20000.00', '38000.00', 9, 0, '2026-11-16 16:52:35', '2026-11-18 00:10:33'),
(9, 4, 'RMH-01', 'Nastar Keju 250g', 'box', 'resep', NULL, '22000.00', '45000.00', 0, 0, '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(10, 6, 'SKU-4HTYMV', 'Kapucino', 'cup', 'retail', NULL, '5000.00', '8000.00', 8, 0, '2026-11-17 21:36:42', '2026-11-18 00:54:01'),
(11, 1, 'SKU-QHGPLX', 'es loreng', 'cup', 'resep', NULL, '5000.00', '7000.00', 0, 0, '2026-11-17 21:37:50', '2026-11-17 21:37:50'),
(12, 1, 'SKU-NJN2JY', 'Es Teh', 'cup', 'resep', 'http://127.0.0.1:8000/storage/products/product_1794987945.png', '3000.00', '5000.00', 0, 0, '2026-11-17 22:52:21', '2026-11-18 00:45:45');

-- --------------------------------------------------------

--
-- Struktur dari tabel `product_prices_platform`
--

CREATE TABLE `product_prices_platform` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `platform_name` varchar(100) NOT NULL,
  `price` decimal(15,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Struktur dari tabel `product_recipes`
--

CREATE TABLE `product_recipes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `raw_material_id` bigint(20) UNSIGNED NOT NULL,
  `qty_needed` decimal(15,4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `product_recipes`
--

INSERT INTO `product_recipes` (`id`, `product_id`, `raw_material_id`, `qty_needed`) VALUES
(1, 4, 1, '0.0200'),
(2, 4, 2, '0.0300'),
(3, 4, 6, '0.1500'),
(4, 6, 3, '0.2500'),
(5, 7, 1, '0.0200'),
(8, 12, 11, '1.0000'),
(9, 12, 10, '1.0000');

-- --------------------------------------------------------

--
-- Struktur dari tabel `promotions`
--

CREATE TABLE `promotions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `typ_promotion_id` tinyint(1) NOT NULL COMMENT '1=Nominal (Rp), 2=Persen (%)',
  `required` decimal(15,2) NOT NULL DEFAULT 0.00,
  `result` decimal(15,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `promotions`
--

INSERT INTO `promotions` (`id`, `title`, `typ_promotion_id`, `required`, `result`, `is_active`, `created_at`, `updated_at`) VALUES
(4, 'Nataru', 2, '50000.00', '10.00', 1, '2026-11-17 20:57:10', '2026-11-17 20:57:10');

-- --------------------------------------------------------

--
-- Struktur dari tabel `raw_materials`
--

CREATE TABLE `raw_materials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `unit` varchar(50) NOT NULL,
  `stock` decimal(15,3) NOT NULL DEFAULT 0.000,
  `min_stock` decimal(15,3) NOT NULL DEFAULT 1.000,
  `cost_price` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `raw_materials`
--

INSERT INTO `raw_materials` (`id`, `name`, `unit`, `stock`, `min_stock`, `cost_price`, `created_at`, `updated_at`) VALUES
(1, 'Biji Kopi', 'kg', '7.000', '1.000', '240000.00', '2026-11-16 16:52:35', '2026-11-17 21:15:11'),
(2, 'Gula Aren Cair', 'liter', '6.000', '2.000', '25000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(3, 'Jeruk Peras', 'kg', '4.000', '1.000', '20000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(4, 'Keju Cheddar', 'kg', '3.000', '1.000', '90000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(5, 'Mentega', 'kg', '10.000', '3.000', '24000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(6, 'Susu UHT', 'liter', '12.000', '3.000', '18000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(7, 'Telur', 'kg', '15.000', '4.000', '28000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(8, 'Tepung Terigu', 'kg', '25.000', '5.000', '12000.00', '2026-11-16 16:52:35', '2026-11-16 16:52:35'),
(9, 'Telo', 'kg', '10.000', '1.000', '2000.00', '2026-11-17 21:15:55', '2026-11-17 21:15:55'),
(10, 'Plastik', 'pcs', '485.000', '1.000', '300.00', '2026-11-17 21:17:14', '2026-11-18 02:26:54'),
(11, 'Air Galon', 'Liter', '484.000', '100.000', '500.00', '2026-11-17 21:20:55', '2026-11-18 02:26:54');

-- --------------------------------------------------------

--
-- Struktur dari tabel `settings`
--

CREATE TABLE `settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_name` varchar(255) NOT NULL DEFAULT 'Toko Sejahtera',
  `location_store` text DEFAULT NULL,
  `contact` varchar(100) DEFAULT NULL,
  `logo_path_url` varchar(255) DEFAULT NULL,
  `qris_path_url` varchar(255) DEFAULT NULL,
  `tax` decimal(5,2) NOT NULL DEFAULT 11.00,
  `receipt_width` varchar(20) NOT NULL DEFAULT '58 mm',
  `receipt_footer` varchar(255) NOT NULL DEFAULT 'Terima kasih telah berbelanja',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `settings`
--

INSERT INTO `settings` (`id`, `store_name`, `location_store`, `contact`, `logo_path_url`, `qris_path_url`, `tax`, `receipt_width`, `receipt_footer`, `created_at`, `updated_at`) VALUES
(1, 'Toko Kasir', 'BSD, SERPONG', '085852108546', 'http://127.0.0.1:8000/storage/logos/logo_1794986288.png', 'http://127.0.0.1:8000/storage/payment/qris_1794987272.png', '11.00', '58 mm', 'Terima kasih telah berbelanja di indorobotika', '2026-11-16 16:52:35', '2026-11-18 00:34:32');

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('owner','admin','kasir') NOT NULL DEFAULT 'owner',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `created_at`, `updated_at`) VALUES
(1, 'indorobotika 01', 'indorobotika01@gmail.com', '$2y$10$wKrCr61lmNdYX8JO.Sy3YegnpnqzFwfdsdoaUGCNNafoqT4xCtZt.', 'owner', '2026-11-16 16:52:35', '2026-11-16 16:55:21');

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `cashflows`
--
ALTER TABLE `cashflows`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`);

--
-- Indeks untuk tabel `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `order_details`
--
ALTER TABLE `order_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `promotion_id` (`promotion_id`);

--
-- Indeks untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indeks untuk tabel `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indeks untuk tabel `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sku` (`sku`),
  ADD KEY `category_id` (`category_id`);

--
-- Indeks untuk tabel `product_prices_platform`
--
ALTER TABLE `product_prices_platform`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indeks untuk tabel `product_recipes`
--
ALTER TABLE `product_recipes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `raw_material_id` (`raw_material_id`);

--
-- Indeks untuk tabel `promotions`
--
ALTER TABLE `promotions`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `raw_materials`
--
ALTER TABLE `raw_materials`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `cashflows`
--
ALTER TABLE `cashflows`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT untuk tabel `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT untuk tabel `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT untuk tabel `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT untuk tabel `order_details`
--
ALTER TABLE `order_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT untuk tabel `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT untuk tabel `products`
--
ALTER TABLE `products`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT untuk tabel `product_prices_platform`
--
ALTER TABLE `product_prices_platform`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `product_recipes`
--
ALTER TABLE `product_recipes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT untuk tabel `promotions`
--
ALTER TABLE `promotions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT untuk tabel `raw_materials`
--
ALTER TABLE `raw_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT untuk tabel `settings`
--
ALTER TABLE `settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `cashflows`
--
ALTER TABLE `cashflows`
  ADD CONSTRAINT `cashflows_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Ketidakleluasaan untuk tabel `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Ketidakleluasaan untuk tabel `order_details`
--
ALTER TABLE `order_details`
  ADD CONSTRAINT `order_details_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_details_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `order_details_ibfk_3` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE SET NULL;

--
-- Ketidakleluasaan untuk tabel `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `product_prices_platform`
--
ALTER TABLE `product_prices_platform`
  ADD CONSTRAINT `product_prices_platform_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Ketidakleluasaan untuk tabel `product_recipes`
--
ALTER TABLE `product_recipes`
  ADD CONSTRAINT `product_recipes_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_recipes_ibfk_2` FOREIGN KEY (`raw_material_id`) REFERENCES `raw_materials` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
