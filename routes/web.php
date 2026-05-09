<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\IoTController;

Route::get('/', function () {
    return view('dashboard');
});

Route::get('/api/iot-data', [IoTController::class, 'getData']);
Route::get('/api/pump/on', [IoTController::class, 'pumpOn']);
Route::get('/pump/off', [IoTController::class, 'pumpOff']);