<?php

namespace App\Http\Controllers;

use App\Http\Requests\QuizAnswerRequest;
use App\Http\Resources\QuizResource;
use App\Http\Resources\SagaNodeResource;
use App\Models\Mission;
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
     * Jumlah soal per sesi node (fixed). Pastikan xp_reward misi quiz
     * habis dibagi angka ini agar XP bagi-rata bulat.
     */
    public const SESSION_SIZE = 5;

    /**
     * POST /api/saga/answer — {quiz_id, answer: A/B/C/D}
     * Aturan sesi: benar = +xp_reward/SESSION_SIZE; salah = hangus
     * (soal terkunci hari ini, 409 bila diulang). Node selesai saat
     * semua soal sesi terjawab. Hanya XP, tanpa eco_points.
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
        $mission = $quiz->mission;

        if (! $mission || $mission->category !== 'quiz' || ! $mission->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Quiz not available.',
            ], 422);
        }

        $playableMissionId = $this->resolveTodayQuiz($user->id, $todayWib)?->mission_id;

        if ($playableMissionId === null || $mission->id !== $playableMissionId) {
            return response()->json([
                'success' => false,
                'message' => 'Quiz is not playable today.',
            ], 422);
        }

        $sessionIds = $this->sessionQuizIds($user->id, $mission->id, $todayWib);

        if (! in_array($quiz->id, $sessionIds, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Quiz is not part of today\'s session.',
            ], 422);
        }

        // Sudah dijawab hari ini (benar maupun salah) → hangus, tidak bisa diulang.
        if ($this->isQuizAnsweredToday($user->id, $mission->id, $quiz->id, $todayWib)) {
            return response()->json([
                'success' => false,
                'message' => 'You have already answered this question today.',
            ], 409);
        }

        $isCorrect = strtoupper($validated['answer']) === strtoupper($quiz->correct_answer);
        $xpPerQuestion = intdiv($mission->xp_reward ?? 0, max(count($sessionIds), 1));

        $result = DB::transaction(function () use ($user, $quiz, $mission, $isCorrect, $xpPerQuestion, $todayWib) {
            // Cek ulang dalam transaksi (anti race condition submit ganda).
            if ($this->isQuizAnsweredToday($user->id, $mission->id, $quiz->id, $todayWib)) {
                return ['duplicate' => true];
            }

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
                $newXp = $profile->xp + $xpPerQuestion;
                $newStreak = StreakService::nextStreak($profile->last_mission_at, $profile->streak_days);
                $newLevel = LevelService::resolveLevel($newXp);

                $profile->update([
                    'xp' => $newXp,
                    'level' => $newLevel,
                    'streak_days' => $newStreak,
                    'last_mission_at' => now(),
                ]);

                return [
                    'duplicate' => false,
                    'is_correct' => true,
                    'xp_earned' => $xpPerQuestion,
                    'new_xp' => $newXp,
                    'new_level' => $newLevel,
                    'streak_days' => $newStreak,
                    'user_mission_id' => $userMission->id,
                ];
            }

            // Wrong answer — hangus: tidak ada XP dan tidak bocor kunci jawaban.
            // Client lanjut ke soal berikut; soal ini terkunci hari ini.
            return [
                'duplicate' => false,
                'is_correct' => false,
                'xp_earned' => 0,
                'user_mission_id' => $userMission->id,
            ];
        });

        if (($result['duplicate'] ?? false) === true) {
            return response()->json([
                'success' => false,
                'message' => 'You have already answered this question today.',
            ], 409);
        }

        $progress = $this->sessionProgress($user->id, $mission->id, $sessionIds, $xpPerQuestion, $todayWib);
        $result = array_merge($result, $progress);

        if ($result['is_correct']) {
            return response()->json([
                'success' => true,
                'message' => 'Correct! +'.$result['xp_earned'].' XP earned.',
                'data' => $result,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Incorrect. This question is forfeited, moving to the next one!',
            'data' => $result,
        ]);
    }

    /**
     * GET /api/saga/nodes/{id}/questions — soal sesi hari ini untuk 1 node.
     * Hanya untuk node playable hari ini (403 bila terkunci).
     * correct_answer/explanation hanya dibuka untuk soal yang sudah dijawab.
     */
    public function questions(int $id): JsonResponse
    {
        $user = Auth::user();
        $todayWib = Carbon::now(StreakService::TZ)->toDateString();

        $mission = Mission::where('category', 'quiz')
            ->where('is_active', true)
            ->find($id);

        if (! $mission) {
            return response()->json([
                'success' => false,
                'message' => 'Quiz node not found.',
            ], 404);
        }

        $playableMissionId = $this->resolveTodayQuiz($user->id, $todayWib)?->mission_id;

        if ($playableMissionId === null || $mission->id !== $playableMissionId) {
            return response()->json([
                'success' => false,
                'message' => 'This node is locked today.',
            ], 403);
        }

        $sessionIds = $this->sessionQuizIds($user->id, $mission->id, $todayWib);

        $quizzes = Quiz::whereIn('id', $sessionIds)->get()
            ->sortBy(fn ($q) => array_search($q->id, $sessionIds, true))
            ->values();

        $attempts = $this->todayAttemptsByQuiz($user->id, $mission->id, $todayWib);

        $items = [];
        foreach ($quizzes as $quiz) {
            $attempt = $attempts[$quiz->id] ?? null;
            $item = [
                'id' => $quiz->id,
                'mission_id' => $quiz->mission_id,
                'question' => $quiz->question,
                'options' => $quiz->options,
                'order' => $quiz->order,
                'is_answered_today' => $attempt !== null,
                'was_correct' => $attempt ? $attempt['status'] === 'verified' : null,
            ];
            if ($attempt) {
                $item['correct_answer'] = $quiz->correct_answer;
                $item['explanation'] = $quiz->explanation;
            }
            $items[] = $item;
        }

        return response()->json([
            'success' => true,
            'message' => 'Node questions retrieved successfully.',
            'data' => [
                'mission_id' => $mission->id,
                'mission_title' => $mission->title,
                'session_date' => $todayWib,
                'total' => count($items),
                'xp_per_question' => intdiv($mission->xp_reward ?? 0, max(count($sessionIds), 1)),
                'questions' => $items,
            ],
        ]);
    }

    /**
     * GET /api/saga/nodes — daftar node peta Saga (1 node = 1 misi quiz).
     * Tepat 1 node playable per hari (pemegang sesi hari ini), sisanya locked.
     * today_quiz_id = soal sesi pertama yang belum dijawab (kompatibilitas).
     */
    public function nodes(): JsonResponse
    {
        $user = Auth::user();
        $todayWib = Carbon::now(StreakService::TZ)->toDateString();

        $todayQuiz = $this->resolveTodayQuiz($user->id, $todayWib);
        $playableMissionId = $todayQuiz?->mission_id;

        $missions = Mission::where('category', 'quiz')
            ->where('is_active', true)
            ->orderBy('id')
            ->withCount('quizzes')
            ->get();

        $nodes = [];
        $position = 1;
        foreach ($missions as $mission) {
            $isPlayable = $playableMissionId !== null && $mission->id === $playableMissionId;
            $sessionIds = $this->sessionQuizIds($user->id, $mission->id, $todayWib);
            $attempts = $this->todayAttemptsByQuiz($user->id, $mission->id, $todayWib);
            $answered = 0;
            foreach ($sessionIds as $qid) {
                if (isset($attempts[$qid])) {
                    $answered++;
                }
            }
            $total = count($sessionIds);
            $firstUnanswered = null;
            foreach ($sessionIds as $qid) {
                if (! isset($attempts[$qid])) {
                    $firstUnanswered = $qid;
                    break;
                }
            }
            $nodes[] = (new SagaNodeResource([
                'mission' => $mission,
                'position' => $position++,
                'quizzes_count' => $mission->quizzes_count ?? 0,
                'is_completed_today' => $total > 0 && $answered >= $total,
                'is_playable_today' => $isPlayable,
                'today_quiz_id' => $isPlayable ? $firstUnanswered : null,
                'total_questions' => $total,
                'answered_today' => $answered,
            ]))->resolve();
        }

        return response()->json([
            'success' => true,
            'message' => 'Saga nodes retrieved successfully.',
            'data' => $nodes,
        ]);
    }

    /**
     * ID soal sesi hari ini untuk 1 misi: fixed SESSION_SIZE, deterministik
     * per user+misi+tanggal (rotasi stabil agar retry/resume soal sama).
     *
     * @return list<int>
     */
    private function sessionQuizIds(int $userId, int $missionId, string $todayWib): array
    {
        $ids = Quiz::where('mission_id', $missionId)->orderBy('id')->pluck('id')->all();

        if (count($ids) <= self::SESSION_SIZE) {
            return $ids;
        }

        $seed = abs(crc32($userId.'|'.$missionId.'|'.$todayWib));
        $offset = $seed % count($ids);
        $rotated = array_merge(array_slice($ids, $offset), array_slice($ids, 0, $offset));

        return array_slice($rotated, 0, self::SESSION_SIZE);
    }

    /**
     * Attempt terakhir hari ini per quiz (verified maupun rejected),
     * diindeks quiz_id. Filter PHP agar konsisten MySQL maupun SQLite.
     *
     * @return array<int, array{status: string}>
     */
    private function todayAttemptsByQuiz(int $userId, int $missionId, string $todayWib): array
    {
        $missions = UserMission::where('user_id', $userId)
            ->where('mission_id', $missionId)
            ->whereDate('created_at', $todayWib)
            ->orderBy('id')
            ->get();

        $attempts = [];
        foreach ($missions as $m) {
            $quizId = $m->ai_gemini_response['quiz_id'] ?? null;
            if ($quizId !== null) {
                $attempts[(int) $quizId] = ['status' => $m->status];
            }
        }

        return $attempts;
    }

    private function isQuizAnsweredToday(int $userId, int $missionId, int $quizId, string $todayWib): bool
    {
        $attempts = $this->todayAttemptsByQuiz($userId, $missionId, $todayWib);

        return isset($attempts[$quizId]);
    }

    /**
     * Progres sesi hari ini: terjawab, benar, sisa, XP sesi, dan flag selesai.
     *
     * @param  list<int>  $sessionIds
     */
    private function sessionProgress(int $userId, int $missionId, array $sessionIds, int $xpPerQuestion, string $todayWib): array
    {
        $attempts = $this->todayAttemptsByQuiz($userId, $missionId, $todayWib);

        $answered = 0;
        $correct = 0;
        foreach ($sessionIds as $qid) {
            if (isset($attempts[$qid])) {
                $answered++;
                if ($attempts[$qid]['status'] === 'verified') {
                    $correct++;
                }
            }
        }

        $total = count($sessionIds);

        return [
            'node_completed' => $total > 0 && $answered >= $total,
            'remaining' => max($total - $answered, 0),
            'session_correct' => $correct,
            'session_xp' => $correct * $xpPerQuestion,
        ];
    }

    /**
     * Tentukan soal hari ini untuk user (logika sama dengan index()).
     * Prioritas: verified hari ini > attempt terakhir hari ini > acak deterministik.
     */
    private function resolveTodayQuiz(int $userId, string $todayWib): ?Quiz
    {
        $verifiedMission = UserMission::where('user_id', $userId)
            ->where('status', 'verified')
            ->whereDate('created_at', $todayWib)
            ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
            ->latest('id')
            ->first();

        if ($verifiedMission) {
            $quizId = $verifiedMission->ai_gemini_response['quiz_id'] ?? null;
            $quiz = $quizId ? Quiz::with('mission')->find($quizId) : null;
            if ($quiz) {
                return $quiz;
            }

            return Quiz::with('mission')->where('mission_id', $verifiedMission->mission_id)->first();
        }

        $lastAttempt = UserMission::where('user_id', $userId)
            ->whereDate('created_at', $todayWib)
            ->whereHas('mission', fn ($q) => $q->where('category', 'quiz'))
            ->latest('id')
            ->first();

        if ($lastAttempt) {
            $quizId = $lastAttempt->ai_gemini_response['quiz_id'] ?? null;
            $quiz = $quizId ? Quiz::with('mission')->find($quizId) : null;
            if ($quiz) {
                return $quiz;
            }

            return Quiz::with('mission')->where('mission_id', $lastAttempt->mission_id)->first();
        }

        $total = Quiz::whereHas('mission', fn ($q) => $q->where('is_active', true))->count();
        if ($total === 0) {
            return null;
        }

        $seed = abs(crc32($userId.'|'.$todayWib));
        $offset = $seed % $total;

        return Quiz::with('mission')
            ->whereHas('mission', fn ($q) => $q->where('is_active', true))
            ->orderBy('id')
            ->offset($offset)
            ->first();
    }
}
