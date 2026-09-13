<?php

namespace App\Http\Controllers;

use App\Http\Requests\QuizAnswerRequest;
use App\Http\Resources\QuizResource;
use App\Models\Quiz;
use App\Models\UserMission;
use App\Models\WargaProfile;
use App\Services\LevelService;
use App\Services\StreakService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class SagaController extends Controller
{
    /**
     * GET /api/saga/quizzes — 1 random quiz per hari (WIB).
     * Jika sudah verified hari ini, tetap return quiz hari itu dengan flag completed.
     */
    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();
        $todayWib = Carbon::now(StreakService::TZ)->toDateString();

        // Find today's verified mission (exact quiz)
        $verifiedMission = UserMission::where('user_id', $user->id)
            ->where('status', 'verified')
            ->whereDate('created_at', $todayWib)
            ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
            ->latest('id')
            ->first();

        if ($verifiedMission) {
            $quizId = $verifiedMission->ai_gemini_response['quiz_id'] ?? null;
            $quiz = $quizId ? Quiz::with('mission')->find($quizId) : null;
            if (! $quiz) {
                $quiz = Quiz::with('mission')->where('mission_id', $verifiedMission->mission_id)->first();
            }
        } else {
            // Check if there's a rejected attempt today — stick to same quiz
            $lastAttempt = UserMission::where('user_id', $user->id)
                ->whereDate('created_at', $todayWib)
                ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
                ->latest('id')
                ->first();

            if ($lastAttempt) {
                $quizId = $lastAttempt->ai_gemini_response['quiz_id'] ?? null;
                $quiz = $quizId ? Quiz::with('mission')->find($quizId) : null;
                if (! $quiz) {
                    $quiz = Quiz::with('mission')->where('mission_id', $lastAttempt->mission_id)->first();
                }
            } else {
                // No attempt today — deterministic 1 random per day (stable)
                $total = Quiz::whereHas('mission', fn ($q) => $q->where('is_active', true))->count();
                if ($total > 0) {
                    $seed = abs(crc32($user->id.'|'.$todayWib));
                    $offset = $seed % $total;
                    $quiz = Quiz::with('mission')
                        ->whereHas('mission', fn ($q) => $q->where('is_active', true))
                        ->orderBy('id')
                        ->offset($offset)
                        ->first();
                } else {
                    $quiz = null;
                }
            }
        }

        if (! $quiz) {
            return response()->json([
                'success' => false,
                'message' => 'No quizzes available.',
            ], 404);
        }

        $isCompletedToday = $verifiedMission !== null;

        // If completed, show_answer true; otherwise hide
        $resource = new QuizResource([
            'quiz' => $quiz,
            'is_completed_today' => $isCompletedToday,
            'show_answer' => $isCompletedToday,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Quizzes retrieved successfully.',
            'data' => $resource->resolve(),
        ]);
    }

    /**
     * POST /api/saga/answer — {quiz_id, answer: A/B/C/D}
     * Boleh retry sampai benar. Setelah verified hari ini, 409.
     * Hanya XP, tanpa eco_points.
     */
    public function answer(QuizAnswerRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $user = Auth::user();
        $todayWib = Carbon::now(StreakService::TZ)->toDateString();

        $quiz = Quiz::with('mission')->find($validated['quiz_id']);

        // Check if already verified today (any quiz)
        $alreadyVerified = UserMission::where('user_id', $user->id)
            ->where('status', 'verified')
            ->whereDate('created_at', $todayWib)
            ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
            ->exists();

        if ($alreadyVerified) {
            return response()->json([
                'success' => false,
                'message' => 'You have already completed today\'s quiz correctly.',
            ], 409);
        }

        $isCorrect = strtoupper($validated['answer']) === strtoupper($quiz->correct_answer);

        $result = DB::transaction(function () use ($user, $quiz, $isCorrect, $todayWib) {
            $profile = WargaProfile::where('user_id', $user->id)->lockForUpdate()->first();

            if (! $profile) {
                throw new \Exception('User profile not found.');
            }

            $status = $isCorrect ? 'verified' : 'rejected';

            $userMission = UserMission::create([
                'user_id' => $user->id,
                'mission_id' => $quiz->mission_id,
                'status' => $status,
                'confidence_score' => $isCorrect ? 100 : 0,
                'ai_gemini_response' => ['quiz_id' => $quiz->id, 'answer' => $isCorrect ? 'correct' : 'incorrect'],
            ]);

            if ($isCorrect) {
                $xpReward = $quiz->mission->xp_reward ?? 50;

                $newXp = $profile->xp + $xpReward;
                $newStreak = StreakService::nextStreak($profile->last_mission_at, $profile->streak_days);
                $newLevel = LevelService::resolveLevel($newXp);

                $profile->update([
                    'xp' => $newXp,
                    'level' => $newLevel,
                    'streak_days' => $newStreak,
                    'last_mission_at' => now(),
                ]);

                return [
                    'is_correct' => true,
                    'xp_earned' => $xpReward,
                    'new_xp' => $newXp,
                    'new_level' => $newLevel,
                    'streak_days' => $newStreak,
                    'user_mission_id' => $userMission->id,
                ];
            }

            // Wrong answer — do not leak correct_answer/explanation (anti-cheat).
            // Client must retry; correct answer only visible after verified via GET.
            return [
                'is_correct' => false,
                'xp_earned' => 0,
                'attempts_today' => UserMission::where('user_id', $user->id)
                    ->whereDate('created_at', $todayWib)
                    ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
                    ->count(),
                'user_mission_id' => $userMission->id,
            ];
        });

        if ($result['is_correct']) {
            return response()->json([
                'success' => true,
                'message' => 'Correct! +'.$result['xp_earned'].' XP earned.',
                'data' => $result,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Incorrect answer. Try again!',
            'data' => $result,
        ]);
    }
}
