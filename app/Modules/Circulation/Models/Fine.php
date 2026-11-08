<?php

namespace Modules\Circulation\Models;

use Illuminate\Database\Eloquent\Model;

class Fine extends Model
{
    protected $fillable = ['loan_id', 'days_late', 'amount'];

    protected $casts = ['amount' => 'decimal:2'];

    public function loan()
    {
        return $this->belongsTo(Loan::class);
    }
}