<?php

use App\Http\Controllers\Api\DeviceController;
use Illuminate\Support\Facades\Route;

Route::prefix('device')->group(function () {
    Route::post('sensor-data', [DeviceController::class, 'storeSensorData']);
    Route::post('control', [DeviceController::class, 'updateControl']);
    Route::get('pump-status', [DeviceController::class, 'getPumpStatus']);
    Route::get('latest-data', [DeviceController::class, 'getLatestData']);
});
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'HydroIoT API',
        'timestamp' => now()
    ]);
});
