<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Disbursement extends Model
{
    use HasFactory;

    protected $fillable = [
        'mitra_profile_id',
        'voucher_claim_id',
        'xendit_disbursement_id',
        'amount',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'status',
        'response_log',
        'failure_reason',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'response_log' => 'array',
        ];
    }

    public function mitraProfile(): BelongsTo
    {
        return $this->belongsTo(MitraProfile::class);
    }

    public function voucherClaim(): BelongsTo
    {
        return $this->belongsTo(VoucherClaim::class);
    }
}