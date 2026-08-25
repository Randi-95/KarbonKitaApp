<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Mission extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'category',
        'xp_reward',
        'points_reward',
        'icon',
        'max_participants',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function userMissions(): HasMany
    {
        return $this->hasMany(UserMission::class);
    }

    public function quizzes(): HasMany
    {
        return $this->hasMany(Quiz::class);
    }
}