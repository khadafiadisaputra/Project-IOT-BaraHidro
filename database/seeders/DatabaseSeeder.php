<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Buat Akun Admin (Agar login admin@hydro.com di dashboard kamu tetap valid)
        User::factory()->create([
            'name' => 'Admin User',
            'email' => 'admin@hydro.com',
            'password' => bcrypt('password123'),
        ]);

        // 2. Isi Data Dummy ke tabel sensor_data
        // Sesuai migration: 2026_04_10_152000_add_temperature_ppm_to_sensor_data_table.php
        DB::table('sensor_data')->insert([
            'temperature' => 25.4,
            'ppm' => 820,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 3. Isi Data Dummy ke tabel pump_statuses
        // Sesuai migration: 2026_04_09_123420_add_status_to_pump_statuses_table.php
        DB::table('pump_statuses')->insert([
            'status' => 'off',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}