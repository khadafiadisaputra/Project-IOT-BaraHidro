<?php

use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// ==========================================
// ENDPOINT PUBLIK (Tidak butuh Token)
// ==========================================
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'HydroIoT API',
        'timestamp' => now()
    ]);
});

// Endpoint untuk aplikasi Flutter mendapatkan Token
Route::post('/login', [AuthController::class, 'login']);


// ==========================================
// ENDPOINT TERLINDUNGI & RATE LIMITED
// ==========================================
Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    
    // Group endpoint khusus IoT
    Route::prefix('device')->group(function () {
        Route::post('sensor-data', [DeviceController::class, 'storeSensorData']);
        Route::post('control', [DeviceController::class, 'updateControl']);
        Route::get('pump-status', [DeviceController::class, 'getPumpStatus']);
        Route::get('latest-data', [DeviceController::class, 'getLatestData']);
    });

    // Endpoint untuk menghancurkan token saat user Flutter logout
    Route::post('/logout', [AuthController::class, 'logout']);
});