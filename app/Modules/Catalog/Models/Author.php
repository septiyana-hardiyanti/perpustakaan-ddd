<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Model;

class Author extends Model
{
    protected $fillable = ['name'];

    public function books()
    {
        return $this->hasMany(Book::class);
    }
}