<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Book extends Model
{
    use SoftDeletes;

    protected $fillable = ['title', 'isbn', 'author_id', 'publisher_id', 'stock'];

    public function author(): BelongsTo
    {
        return $this->belongsTo(Author::class);
    }

    public function publisher(): BelongsTo
    {
        return $this->belongsTo(Publisher::class);
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'book_category')->withPivot('added_at');
    }

    public function scopeAvailable(Builder $query): Builder
    {
        return $query->where('stock', '>', 0);
    }

    public function scopeSearch(Builder $query, string $keyword): Builder
    {
        return $query->where(function ($q) use ($keyword) {
            $q->where('title', 'like', "%{$keyword}%")
                ->orWhere('isbn', 'like', "%{$keyword}%");
        });
    }

    public function scopeInCategory(Builder $query, int $categoryId): Builder
    {
        return $query->whereHas('categories', function ($q) use ($categoryId) {
            $q->where('categories.id', $categoryId);
        });
    }

    public function isInStock(int $quantity = 1): bool
    {
        return $this->stock >= $quantity;
    }
}