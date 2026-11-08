<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->string('loan_number')->unique();
            $table->timestamp('borrowed_at')->useCurrent();
            $table->timestamp('due_at')->nullable();
            $table->timestamp('returned_at')->nullable();
            $table->string('status')->default('borrowed');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loans');
    }
};