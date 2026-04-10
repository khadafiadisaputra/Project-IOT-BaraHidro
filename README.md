🌿 HydroIoT: Smart Hydroponics Dashboard
Dashboard monitoring IoT berbasis web untuk memantau suhu air dan kadar nutrisi (PPM) secara realtime. Dibangun menggunakan Laravel 11, React, dan Tailwind CSS.

🚀 Fitur Utama
Realtime Monitoring: Grafik suhu dan PPM yang update otomatis.

Pump Control: Pengaturan mode pompa (Auto/Manual) dan delay pompa.

History Data: Logger riwayat sensor lengkap.

Device Status: Indikator Online/Offline ESP32 berdasarkan heartbeat data.

🛠️ Persyaratan Sistem
Sebelum memulai, pastikan kamu sudah menginstall:

PHP >= 8.2

Composer

Node.js & npm

MySQL / XAMPP

🏁 Langkah-Langkah Instalasi
1. Clone Repository
Buka terminal dan jalankan perintah berikut:

Bash

git clone https://github.com/MrRakyan/System-IOT-Sensor-PPM-Suhu-Pompa-.git
cd System-IOT-Sensor-PPM-Suhu-Pompa-
2. Install Dependency (Backend)
Install paket-paket Laravel yang dibutuhkan:

Bash

composer install
3. Konfigurasi Environment
Salin file .env.example menjadi .env:

Bash

cp .env.example .env
Lalu, buka file .env dan sesuaikan pengaturan database kamu:

Code snippet

DB_DATABASE=db_hidroponik
DB_USERNAME=root
DB_PASSWORD=
Jangan lupa buat database baru dengan nama db_hidroponik di phpMyAdmin.

4. Generate Key & Migration
Bash

php artisan key:generate
php artisan migrate
5. Install Dependency (Frontend)
Install library React dan Tailwind CSS:

Bash

npm install
🏃‍♂️ Menjalankan Aplikasi
Kamu butuh menjalankan dua terminal sekaligus:

Terminal 1 (Laravel Server):

Bash

php artisan serve
Terminal 2 (Vite Server - Frontend):

Bash

npm run dev
Akses aplikasi di browser pada alamat: http://127.0.0.1:8000

🧪 Simulasi Pengiriman Data (Postman)
Untuk mencoba fitur realtime tanpa ESP32, gunakan Postman:

Method: POST

URL: http://127.0.0.1:8000/api/device/sensor-data

Headers: Accept: application/json

Body (JSON):

JSON

{
    "temperature": 28.5,
    "ppm": 900
}
📁 Struktur Folder Penting
app/Http/Controllers/Api/: Logika API untuk ESP32.

resources/js/Dashboard.jsx: Komponen utama UI Dashboard.

routes/api.php: Jalur komunikasi data IoT.

Dibuat oleh Rakyan Adhitya Nugroho 🚀