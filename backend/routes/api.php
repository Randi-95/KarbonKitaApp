<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\VoucherController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:5,1');
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::get('/user', function () {
        return response()->json([
            'success' => true,
            'data' => auth()->user(),
        ]);
    });

    // Dashboard
    Route::get('/user/dashboard', [DashboardController::class, 'index'])
        ->name('user.dashboard');

    // Leaderboard
    Route::get('/leaderboard', [LeaderboardController::class, 'index'])
        ->name('leaderboard.index');

    // Marketplace & Vouchers
    Route::get('/vouchers', [VoucherController::class, 'index'])
        ->name('vouchers.index');
    Route::post('/vouchers/claim', [VoucherController::class, 'claim'])
        ->name('vouchers.claim');
    Route::get('/user/my-vouchers', [VoucherController::class, 'myVouchers'])
        ->name('user.my-vouchers');
});