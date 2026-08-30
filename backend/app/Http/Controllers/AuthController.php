<?php

namespace App\Http\Controllers;

use App\Http\Requests\RegisterRequest;
use App\Http\Requests\LoginRequest;
use App\Models\MitraProfile;
use App\Models\User;
use App\Models\WargaProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'password' => Hash::make($validated['password']),
                'role' => $validated['role'],
                'kota' => $validated['city'],
                'kecamatan' => $validated['district'],
                'kelurahan' => $validated['sub_district'],
                'rt' => $validated['rt'],
                'rw' => $validated['rw'],
            ]);

            if ($validated['role'] === 'mitra') {
                MitraProfile::create([
                    'user_id' => $user->id,
                    'nama_usaha' => $validated['nama_usaha'] ?? $validated['name'] . ' Usaha',
                    'jenis_usaha' => $validated['jenis_usaha'] ?? 'UMKM',
                    'alamat_usaha' => $validated['alamat_usaha'] ?? $validated['kota'] . ', ' . $validated['district'],
                    'nama_bank' => $validated['nama_bank'] ?? null,
                    'nomor_rekening' => $validated['nomor_rekening'] ?? null,
                    'nama_pemilik_rekening' => $validated['nama_pemilik_rekening'] ?? $validated['name'],
                    'status_verifikasi' => 'pending',
                    'is_active' => false,
                    'balance' => 0,
                ]);
            } else {
                $user->wargaProfile()->create([
                    'level' => 'Earth Newbie',
                    'xp' => 0,
                    'eco_points' => 0,
                    'streak_days' => 0,
                ]);
            }

            return $user;
        });

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'phone' => $user->phone,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'token' => $token,
            ],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $credential = filter_var($validated['phone_or_email'], FILTER_VALIDATE_EMAIL)
            ? ['email' => $validated['phone_or_email']]
            : ['phone' => $validated['phone_or_email']];

        $credential['password'] = $validated['password'];

        if (!Auth::attempt($credential, false)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials.',
            ], 401);
        }

        $user = Auth::user();

        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Account is deactivated. Please contact support.',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'role' => $user->role,
                ],
                'token' => $token,
            ],
        ]);
    }

    public function logout(): JsonResponse
    {
        Auth::user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }
}