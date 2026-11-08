<?php

namespace Modules\Circulation\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Loan extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'member_id', 'loan_number', 'borrowed_at',
        'due_at', 'returned_at', 'status',
    ];

    protected $casts = [
        'borrowed_at' => 'datetime',
        'due_at' => 'datetime',
        'returned_at' => 'datetime',
    ];

    public function details()
    {
        return $this->hasMany(LoanDetail::class);
    }

    public function fines()
    {
        return $this->hasMany(Fine::class);
    }
}