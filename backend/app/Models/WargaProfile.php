<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WargaProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'level',
        'xp',
        'eco_points',
        'streak_days',
        'last_mission_at',
    ];

    protected function casts(): array
    {
        return [
            'last_mission_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}