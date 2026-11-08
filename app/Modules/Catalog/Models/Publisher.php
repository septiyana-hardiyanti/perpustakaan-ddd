<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Model;

class Publisher extends Model
{
    protected $fillable = ['name'];

    public function books()
    {
        return $this->hasMany(Book::class);
    }
}