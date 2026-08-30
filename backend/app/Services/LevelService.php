<?php

namespace App\Services;

class LevelService
{
    private const THRESHOLDS = [
        1 => 100, 2 => 250, 3 => 500, 4 => 800, 5 => 1200,
        6 => 1700, 7 => 2300, 8 => 3000, 9 => 3800, 10 => 4700,
        11 => 5700, 12 => 6800, 13 => 8000, 14 => 9300, 15 => 10700,
    ];

    public static function getXpMaxForLevel(string $level): int
    {
        $levelNumber = (int) filter_var($level, FILTER_SANITIZE_NUMBER_INT) ?: 1;

        return self::THRESHOLDS[$levelNumber] ?? 10700 + (($levelNumber - 15) * 1500);
    }

    public static function calculateXpPercentage(int $currentXp, string $level): float
    {
        $levelNumber = (int) filter_var($level, FILTER_SANITIZE_NUMBER_INT) ?: 1;

        $prevThresholds = [
            1 => 0, 2 => 100, 3 => 250, 4 => 500, 5 => 800,
            6 => 1200, 7 => 1700, 8 => 2300, 9 => 3000, 10 => 3800,
            11 => 4700, 12 => 5700, 13 => 6800, 14 => 8000, 15 => 9300,
        ];

        $currentLevelXp = $prevThresholds[$levelNumber] ?? 10700 + (($levelNumber - 16) * 1500);
        $nextLevelXp = self::getXpMaxForLevel($level);

        $xpInLevel = $currentXp - $currentLevelXp;
        $xpNeeded = $nextLevelXp - $currentLevelXp;

        if ($xpNeeded <= 0) {
            return 100.0;
        }

        return round(($xpInLevel / $xpNeeded) * 100, 2);
    }

    public static function resolveLevel(int $xp): string
    {
        $level = 1;
        foreach (self::THRESHOLDS as $lvl => $max) {
            if ($xp >= $max) {
                $level = $lvl + 1;
            } else {
                break;
            }
        }

        // Cap preview mapping — return label like "Earth Warrior 7"
        if ($level <= 3) {
            return 'Earth Newbie';
        }
        if ($level <= 6) {
            return 'Earth Keeper ' . $level;
        }

        return 'Earth Warrior ' . $level;
    }
}
