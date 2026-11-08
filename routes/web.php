<?php

use Illuminate\Support\Facades\Route;
use Modules\Catalog\Http\Controllers\BookController;
use Modules\Circulation\Http\Controllers\LoanController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/books', [BookController::class, 'index']);
Route::get('/loans', [LoanController::class, 'index']);