<?php

namespace Modules\Catalog\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Modules\Catalog\Models\Book;

class BookController extends Controller
{
    public function index(Request $request)
    {
        $books = Book::with(['author', 'publisher', 'categories'])
            ->available()
            ->when($request->query('q'), fn ($query, $keyword) => $query->search($keyword))
            ->when($request->query('category'), fn ($query, $id) => $query->inCategory((int) $id))
            ->get();

        return response()->json($books);
    }
}