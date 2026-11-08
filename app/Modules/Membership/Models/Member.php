<?php

namespace Modules\Membership\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Member extends Model
{
    use SoftDeletes;

    protected $fillable = ['name', 'email', 'status'];

    public function roles()
    {
        return $this->belongsToMany(Role::class, 'member_role');
    }
}