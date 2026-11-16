# Kasir & Inventori — Full-Stack Point of Sale (Laravel 10 + Vue 2 + Vuetify 2 + MySQL)

Aplikasi Point of Sale (POS) & Inventori siap pakai dengan arsitektur lengkap:
- **Backend**: PHP Laravel 10 REST API + Sanctum Auth + Midtrans QRIS Webhook + Transaksi Atomik Resep/Bahan Baku
- **Frontend**: Vue.js 2 + Vuetify 2 + Vuex + Vue Router (UI Dark Teal `#0f4c3a` & Warm Cream `#f8f7f4`)
- **Database**: MySQL Schema + Seeder Data Awal (Kategori, Produk Retail & Resep, Bahan Baku, Promo, Pengaturan Toko)

## Struktur Folder
- `database/kasir_inventori_full.sql` — Skema tabel lengkap + data awal siap import ke MySQL
- `backend/` — Source code lengkap API Laravel (Models, Controllers, Migrations, Seeders, Routes, `.env.example`)
- `frontend/` — Source code lengkap SPA Vue.js + Vuetify (8 Halaman Lengkap: Kasir, Analitik, Pesanan, Produk, Bahan Baku, Cashflow, Promo, Pengaturan)

## Cara Menjalankan Cepat

### 1. Import Database MySQL
Buat database `kasir_inventori_db` di MySQL/phpMyAdmin, lalu import `database/kasir_inventori_full.sql`.

### 2. Jalankan Backend Laravel
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
# Atur DB_DATABASE=kasir_inventori_db, DB_USERNAME, DB_PASSWORD di .env
php artisan serve --port=8000
```
Akun default (dari Seeder / SQL):
- Email: `indorobotika01@gmail.com`
- Password: `password123`

### 3. Jalankan Frontend Vue.js
```bash
cd frontend
npm install
npm run serve
```
Buka browser di `http://localhost:8080`.
