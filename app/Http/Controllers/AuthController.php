<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Handle user login & generate Sanctum Token
     */
    public function login(Request $request)
    {
        // 1. Validasi inputan
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // 2. Cari user berdasarkan email
        $user = User::where('email', $request->email)->first();

        // 3. Cek apakah user ada dan passwordnya cocok
        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Kredensial salah atau tidak ditemukan.'
            ], 401);
        }

        // 4. Buat token Sanctum
        $token = $user->createToken('hydro-iot-token')->plainTextToken;

        // 5. Kembalikan respons beserta tokennya
        return response()->json([
            'message' => 'Login berhasil',
            'user' => $user,
            'token' => $token,
        ]);
    }

    /**
     * Handle user logout & revoke token
     */
    public function logout(Request $request)
    {
        // Hapus token yang sedang dipakai untuk request ini
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout berhasil, token telah dihapus.'
        ]);
    }
}