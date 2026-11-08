<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('book_category', function (Blueprint $table) {
            $table->foreignId('book_id')->constrained('books')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            $table->timestamp('added_at')->useCurrent();
            $table->primary(['book_id', 'category_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('book_category');
    }
};