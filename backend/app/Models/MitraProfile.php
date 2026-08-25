<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MitraProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'nama_usaha',
        'jenis_usaha',
        'alamat_usaha',
        'nomor_ktp',
        'nomor_nib',
        'foto_ktp',
        'foto_nib',
        'foto_toko',
        'nama_bank',
        'nomor_rekening',
        'nama_pemilik_rekening',
        'status_verifikasi',
        'is_active',
        'balance',
    ];

    protected function casts(): array
    {
        return [
            'balance' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function vouchers(): HasMany
    {
        return $this->hasMany(Voucher::class);
    }

    public function disbursements(): HasMany
    {
        return $this->hasMany(Disbursement::class);
    }
}