<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;

class IoTController extends Controller
{
    private string $esp32Ip = "192.168.1.7";

    public function getData()
    {
        try {
            $response = Http::timeout(3)
                ->get("http://{$this->esp32Ip}/status");

            if ($response->successful()) {
                $data = $response->json();

                return response()->json([
                    'success' => true,
                    'temperature' => $data['temperature'] ?? 0,
                    'tds' => $data['tds'] ?? 0,
                    'pump' => $data['pump'] ?? 'OFF',
                    'online' => true
                ]);
            }

            return response()->json([
                'success' => false,
                'online' => false
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'online' => false,
                'error' => $e->getMessage()
            ]);
        }
    }

    public function pumpOn()
    {
        try {
            $response = Http::timeout(3)
                ->get("http://{$this->esp32Ip}/pump/on");

            return response()->json([
                'success' => $response->successful(),
                'pump' => 'ON'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'pump' => 'OFF',
                'error' => $e->getMessage()
            ]);
        }
    }

    public function pumpOff()
    {
        try {
            $response = Http::timeout(3)
                ->get("http://{$this->esp32Ip}/pump/off");

            return response()->json([
                'success' => $response->successful(),
                'pump' => 'OFF'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'pump' => 'OFF',
                'error' => $e->getMessage()
            ]);
        }
    }
}