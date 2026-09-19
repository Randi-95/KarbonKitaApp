<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\Quiz;
use App\Models\User;
use App\Models\UserMission;
use App\Models\WargaProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SagaNodesTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('auth_token')->plainTextToken];
    }

    private function makeUser(): User
    {
        $user = User::factory()->create();
        WargaProfile::create([
            'user_id' => $user->id,
            'xp' => 0,
            'level' => 'Earth Warrior',
            'eco_points' => 0,
            'streak_days' => 0,
        ]);

        return $user;
    }

    private function makeQuizMission(array $overrides = []): Mission
    {
        return Mission::create(array_merge([
            'title' => 'Quiz Mission',
            'description' => 'Quiz description',
            'category' => 'quiz',
            'xp_reward' => 50,
            'points_reward' => 0,
            'icon' => 'quiz',
            'max_participants' => null,
            'is_active' => true,
        ], $overrides));
    }

    private function makeQuiz(Mission $mission, array $overrides = []): Quiz
    {
        return Quiz::create(array_merge([
            'mission_id' => $mission->id,
            'question' => 'Test question?',
            'options' => ['A' => 'Opt A', 'B' => 'Opt B', 'C' => 'Opt C', 'D' => 'Opt D'],
            'correct_answer' => 'B',
            'explanation' => 'Because B.',
            'order' => 1,
        ], $overrides));
    }

    public function test_unauthenticated_returns_401(): void
    {
        $this->getJson('/api/saga/nodes')->assertStatus(401);
    }

    public function test_returns_envelope_with_node_list(): void
    {
        $user = $this->makeUser();
        $mission = $this->makeQuizMission(['title' => 'Kuis Hijau Harian']);
        $this->makeQuiz($mission);

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => [
                        'id', 'title', 'description', 'icon', 'xp_reward',
                        'position', 'quizzes_count', 'total_questions',
                        'answered_today',
                        'is_completed_today', 'is_playable_today',
                    ],
                ],
            ])
            ->assertJsonPath('success', true);
        $this->assertCount(1, $response->json('data'));
    }

    public function test_exactly_one_playable_node_per_day(): void
    {
        $user = $this->makeUser();
        foreach (range(1, 3) as $i) {
            $mission = $this->makeQuizMission(['title' => "Quiz {$i}"]);
            $this->makeQuiz($mission, ['question' => "Q{$i}?"]);
        }

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        $playable = collect($response->json('data'))->where('is_playable_today', true)->all();
        $this->assertCount(1, $playable);
    }

    public function test_playable_node_exposes_today_quiz_id_others_do_not(): void
    {
        $user = $this->makeUser();
        foreach (range(1, 3) as $i) {
            $mission = $this->makeQuizMission(['title' => "Quiz {$i}"]);
            $this->makeQuiz($mission, ['question' => "Q{$i}?"]);
        }

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        foreach ($response->json('data') as $node) {
            if ($node['is_playable_today']) {
                $this->assertArrayHasKey('today_quiz_id', $node);
                $this->assertNotNull($node['today_quiz_id']);
            } else {
                $this->assertArrayNotHasKey('today_quiz_id', $node);
            }
        }
    }

    public function test_nodes_ordered_by_position_and_mission_id(): void
    {
        $user = $this->makeUser();
        $first = $this->makeQuizMission(['title' => 'First']);
        $second = $this->makeQuizMission(['title' => 'Second']);
        $this->makeQuiz($first);
        $this->makeQuiz($second);

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        $data = $response->json('data');
        $this->assertEquals([$first->id, $second->id], array_column($data, 'id'));
        $this->assertEquals([1, 2], array_column($data, 'position'));
    }

    public function test_excludes_inactive_and_non_quiz_missions(): void
    {
        $user = $this->makeUser();
        $active = $this->makeQuizMission(['title' => 'Active quiz']);
        $this->makeQuiz($active);
        $inactive = $this->makeQuizMission(['title' => 'Inactive quiz', 'is_active' => false]);
        $this->makeQuiz($inactive);
        Mission::create([
            'title' => 'Mobility', 'description' => 'M', 'category' => 'mobility',
            'xp_reward' => 100, 'points_reward' => 50, 'is_active' => true,
        ]);

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        $ids = array_column($response->json('data'), 'id');
        $this->assertEquals([$active->id], $ids);
    }

    public function test_completed_flag_after_correct_answer(): void
    {
        $user = $this->makeUser();
        $mission = $this->makeQuizMission();
        $quiz = $this->makeQuiz($mission);

        // Jawab dengan benar via endpoint answer.
        $answer = $this->postJson('/api/saga/answer', [
            'quiz_id' => $quiz->id,
            'answer' => 'B',
        ], $this->authHeader($user));
        $answer->assertOk();

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        $node = collect($response->json('data'))->firstWhere('id', $mission->id);
        $this->assertNotNull($node);
        $this->assertTrue($node['is_completed_today']);
        $this->assertTrue($node['is_playable_today']);
    }

    public function test_quizzes_count_reflects_questions_per_mission(): void
    {
        $user = $this->makeUser();
        $mission = $this->makeQuizMission();
        $this->makeQuiz($mission, ['question' => 'Q1?']);
        $this->makeQuiz($mission, ['question' => 'Q2?', 'order' => 2]);

        $response = $this->getJson('/api/saga/nodes', $this->authHeader($user));

        $response->assertOk();
        $this->assertEquals(2, $response->json('data.0.quizzes_count'));
    }

    public function test_route_name_resolves(): void
    {
        $this->assertEquals('/api/saga/nodes', route('saga.nodes', [], false));
    }

    public function test_sticky_playable_after_wrong_attempt(): void
    {
        $user = $this->makeUser();
        $missionA = $this->makeQuizMission(['title' => 'A']);
        $quizA = $this->makeQuiz($missionA, ['question' => 'QA?']);
        $missionB = $this->makeQuizMission(['title' => 'B']);
        $this->makeQuiz($missionB, ['question' => 'QB?']);

        // Cari node playable hari ini, jawab salah di quiz-nya.
        $nodes = $this->getJson('/api/saga/nodes', $this->authHeader($user))->json('data');
        $playable = collect($nodes)->firstWhere('is_playable_today', true);
        $this->assertNotNull($playable);

        $wrongQuiz = Quiz::find($playable['today_quiz_id']);
        $wrongAnswer = $wrongQuiz->correct_answer === 'A' ? 'B' : 'A';
        $this->postJson('/api/saga/answer', [
            'quiz_id' => $wrongQuiz->id,
            'answer' => $wrongAnswer,
        ], $this->authHeader($user))->assertOk();

        // Node playable harus tetap sama (sticky). Sesi 1 soal yang
        // terjawab-salah dianggap selesai (semua soal sudah terjawab).
        $again = $this->getJson('/api/saga/nodes', $this->authHeader($user))->json('data');
        $playableAgain = collect($again)->firstWhere('is_playable_today', true);
        $this->assertEquals($playable['id'], $playableAgain['id']);
        $this->assertTrue($playableAgain['is_completed_today']);
        $this->assertEquals(1, $playableAgain['answered_today']);
        $this->assertTrue(UserMission::where('user_id', $user->id)->where('status', 'rejected')->exists());
        $this->assertNotNull($quizA);
    }
}
