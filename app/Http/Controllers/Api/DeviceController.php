<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PumpStatus;
use App\Models\Setting;
use App\Models\SensorData;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DeviceController extends Controller
{
    public function storeSensorData(Request $request): JsonResponse
    {
        // SECURITY UPDATE: Penambahan batas min dan max untuk mencegah Integer/Float Overflow
        $validator = Validator::make($request->all(), [
            'temperature' => 'required|numeric|between:0,100', // Suhu air logis antara 0 - 100 Celcius
            'ppm' => 'required|numeric|between:0,5000',        // PPM logis mentok di kisaran 5000
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();

        $sensorData = SensorData::create([
            'temperature' => $validated['temperature'],
            'ppm' => $validated['ppm'],
        ]);

        $settings = Setting::first();
        $response = [
            'success' => true,
            'message' => 'Sensor data saved successfully.',
            'data' => [
                'temperature' => $sensorData->temperature,
                'ppm' => $sensorData->ppm,
            ],
        ];

        if ($settings && $settings->mode === 'auto' && $validated['ppm'] < $settings->ppm_min) {
            $pumpStatus = PumpStatus::first();

            if ($pumpStatus) {
                $pumpStatus->status = 'on';
                $pumpStatus->save();
            } else {
                PumpStatus::create(['status' => 'on']);
            }

            $response['pump'] = 'on';
            $response['delay'] = $settings->pump_delay;
        }

        return response()->json($response, 201);
    }

    public function updateControl(Request $request): JsonResponse
    {
        // SECURITY UPDATE: Penambahan batas max agar sistem tidak bisa dijebol dengan angka absurd
        $validator = Validator::make($request->all(), [
            'mode' => 'sometimes|string|in:auto,manual',
            'ppm_min' => 'sometimes|integer|min:0|max:5000',
            'pump_delay' => 'sometimes|integer|min:0|max:3600', // Maksimal delay 3600 detik (1 jam)
            'pump_action' => 'sometimes|string|in:on,off',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();

        // Get existing setting atau buat default
        $existing = Setting::find(1);
        
        // Prepare data untuk update/create
        $updateData = [];
        if (array_key_exists('mode', $validated)) {
            $updateData['mode'] = $validated['mode'];
        }
        if (array_key_exists('ppm_min', $validated)) {
            $updateData['ppm_min'] = $validated['ppm_min'];
        }
        if (array_key_exists('pump_delay', $validated)) {
            $updateData['pump_delay'] = $validated['pump_delay'];
        }

        // Jika data tidak ada, set default values
        if (!$existing && !empty($updateData)) {
            $updateData = array_merge([
                'mode' => 'manual',
                'ppm_min' => 800,
                'pump_delay' => 5,
            ], $updateData);
        }

        // Update atau buat Settings
        $settings = Setting::updateOrCreate(['id' => 1], $updateData);

        $currentMode = $settings->mode;
        $currentPumpStatus = PumpStatus::first();

        if (array_key_exists('pump_action', $validated) && $currentMode === 'manual') {
            if ($currentPumpStatus) {
                $currentPumpStatus->status = $validated['pump_action'];
                $currentPumpStatus->save();
            } else {
                $currentPumpStatus = PumpStatus::create([
                    'status' => $validated['pump_action'],
                ]);
            }
        }

        if (array_key_exists('mode', $validated) && $validated['mode'] === 'auto') {
            if ($currentPumpStatus) {
                $currentPumpStatus->status = 'off';
                $currentPumpStatus->save();
            } else {
                $currentPumpStatus = PumpStatus::create(['status' => 'off']);
            }
        }

        $status = 'off';

        if ($currentPumpStatus && isset($currentPumpStatus->status)) {
            $status = strtolower($currentPumpStatus->status) === 'on' ? 'on' : 'off';
        }

        return response()->json([
            'success' => true,
            'message' => 'Control values updated successfully.',
            'mode' => $currentMode,
            'pump_status' => $status,
        ]);
    }

    public function getPumpStatus(): JsonResponse
    {
        $pumpStatus = PumpStatus::latest('created_at')->first();
        $status = 'off';

        if ($pumpStatus && isset($pumpStatus->status)) {
            $status = strtolower($pumpStatus->status) === 'on' ? 'on' : 'off';
        }

        return response()->json([
            'pump_status' => $status,
        ]);
    }

    public function getLatestData(): JsonResponse
    {
        $latestData = SensorData::latest('created_at')->first();
        $settings = Setting::first();

        if (!$settings) {
            $settings = Setting::create([
                'mode' => 'manual',
                'ppm_min' => 800,
                'pump_delay' => 5,
            ]);
        }

        return response()->json([
            'latest_data' => $latestData ? [
                'temperature' => $latestData->temperature,
                'ppm' => $latestData->ppm,
                'created_at' => $latestData->created_at?->toDateTimeString(),
                'recorded_at' => $latestData->created_at?->toDateTimeString(),
            ] : null,
            'settings' => [
                'mode' => $settings->mode,
                'ppm_min' => $settings->ppm_min,
                'pump_delay' => $settings->pump_delay,
            ],
        ]);
    }
}