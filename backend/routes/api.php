<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CarbonStatsController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\MissionController;
use App\Http\Controllers\SagaController;
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

    // Saga Map (Quiz) — throttle brute-force on answer
    Route::get('/saga/quizzes', [SagaController::class, 'index'])
        ->name('saga.quizzes');
    Route::post('/saga/answer', [SagaController::class, 'answer'])
        ->middleware('throttle:10,1')
        ->name('saga.answer');

    // Activity Missions (mobility & waste)
    Route::get('/missions/active', [MissionController::class, 'index'])
        ->name('missions.active');
    Route::post('/missions/verify-waste', [MissionController::class, 'verifyWaste'])
        ->middleware('throttle:10,1')
        ->name('missions.verify-waste');
    Route::post('/missions/mobility-sync', [MissionController::class, 'mobilitySync'])
        ->name('missions.mobility-sync');

    // Carbon Stats
    Route::get('/user/carbon-stats', [CarbonStatsController::class, 'index'])
        ->name('user.carbon-stats');

    // Marketplace & Vouchers
    Route::get('/vouchers', [VoucherController::class, 'index'])
        ->name('vouchers.index');
    Route::post('/vouchers/claim', [VoucherController::class, 'claim'])
        ->name('vouchers.claim');
    Route::get('/user/my-vouchers', [VoucherController::class, 'myVouchers'])
        ->name('user.my-vouchers');
});