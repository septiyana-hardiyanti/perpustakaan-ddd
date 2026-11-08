<?php

namespace Modules\Circulation\Http\Controllers;

use App\Http\Controllers\Controller;
use Modules\Circulation\Models\Loan;

class LoanController extends Controller
{
    public function index()
    {
        return response()->json(Loan::with(['details', 'fines'])->get());
    }
}