<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $profile = $this->resource['profile'];
        $dailyMissions = $this->resource['daily_missions'];
        $leaderboardPreview = $this->resource['leaderboard_preview'];

        return [
            'user' => [
                'name' => $this->resource['name'],
                'level' => $profile->level,
                'xp' => $profile->xp,
                'xp_max' => $this->getXpMaxForLevel($profile->level),
                'xp_percentage' => $this->calculateXpPercentage($profile->xp, $profile->level),
                'eco_points' => $profile->eco_points,
                'streak_days' => $profile->streak_days,
                'rank_percentage' => $this->resource['rank_percentage'] ?? 0,
                'total_distance_km' => $profile->total_distance_km,
                'total_waste_kg' => $profile->total_waste_kg,
                'total_carbon_saved_kg' => $profile->total_carbon_saved_kg,
            ],
            'daily_missions' => MissionResource::collection($dailyMissions),
            'leaderboard_preview' => LeaderboardEntryResource::collection($leaderboardPreview),
        ];
    }

    private function getXpMaxForLevel(string $level): int
    {
        $levelNumber = (int) filter_var($level, FILTER_SANITIZE_NUMBER_INT) ?: 1;

        $thresholds = [
            1 => 100, 2 => 250, 3 => 500, 4 => 800, 5 => 1200,
            6 => 1700, 7 => 2300, 8 => 3000, 9 => 3800, 10 => 4700,
            11 => 5700, 12 => 6800, 13 => 8000, 14 => 9300, 15 => 10700,
        ];

        return $thresholds[$levelNumber] ?? 10700 + (($levelNumber - 15) * 1500);
    }

    private function calculateXpPercentage(int $currentXp, string $level): float
    {
        $levelNumber = (int) filter_var($level, FILTER_SANITIZE_NUMBER_INT) ?: 1;

        $prevThresholds = [
            1 => 0, 2 => 100, 3 => 250, 4 => 500, 5 => 800,
            6 => 1200, 7 => 1700, 8 => 2300, 9 => 3000, 10 => 3800,
            11 => 4700, 12 => 5700, 13 => 6800, 14 => 8000, 15 => 9300,
        ];

        $currentLevelXp = $prevThresholds[$levelNumber] ?? 10700 + (($levelNumber - 16) * 1500);
        $nextLevelXp = $this->getXpMaxForLevel($level);

        $xpInLevel = $currentXp - $currentLevelXp;
        $xpNeeded = $nextLevelXp - $currentLevelXp;

        if ($xpNeeded <= 0) return 100.0;

        return round(($xpInLevel / $xpNeeded) * 100, 2);
    }
}
