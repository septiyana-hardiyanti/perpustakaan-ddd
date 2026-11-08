<?php

namespace Modules\Membership\Models;

use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    protected $fillable = ['name', 'slug'];

    public function members()
    {
        return $this->belongsToMany(Member::class, 'member_role');
    }
}