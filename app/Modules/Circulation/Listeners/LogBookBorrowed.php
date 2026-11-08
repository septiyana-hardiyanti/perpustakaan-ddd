<?php

namespace Modules\Circulation\Listeners;

use Illuminate\Support\Facades\Log;
use Modules\Circulation\Events\BookBorrowed;

class LogBookBorrowed
{
    public function handle(BookBorrowed $event): void
    {
        Log::info('Buku dipinjam', [
            'loan_number' => $event->loan->loan_number,
            'member_id' => $event->loan->member_id,
            'jumlah_item' => $event->loan->details->count(),
        ]);
    }
}