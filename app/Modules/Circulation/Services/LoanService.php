<?php

namespace Modules\Circulation\Services;

use Illuminate\Support\Facades\DB;
use Modules\Circulation\Events\BookBorrowed;
use Modules\Circulation\Models\Fine;
use Modules\Circulation\Models\Loan;
use Modules\Circulation\Models\LoanDetail;
use Modules\Shared\Contracts\BookServiceInterface;
use Modules\Shared\Contracts\MemberServiceInterface;
use Modules\Shared\Exceptions\InsufficientStockException;
use Modules\Shared\ValueObjects\Denda;

class LoanService
{
    public function __construct(
        private BookServiceInterface $bookService,
        private MemberServiceInterface $memberService
    ) {}

    public function borrow(int $memberId, array $items, int $days = 7): Loan
    {
        return DB::transaction(function () use ($memberId, $items, $days) {
            if (!$this->memberService->canBorrow($memberId)) {
                throw new \Exception("Anggota tidak ditemukan atau tidak aktif: {$memberId}");
            }

            $loan = Loan::create([
                'member_id' => $memberId,
                'loan_number' => 'LN-' . strtoupper(uniqid()),
                'borrowed_at' => now(),
                'due_at' => now()->addDays($days),
                'status' => 'borrowed',
            ]);

            foreach ($items as $item) {
                $book = $this->bookService->getBookForLoan($item['book_id']);

                if (!$book) {
                    throw new \Exception("Buku tidak ditemukan: {$item['book_id']}");
                }

                if (!$this->bookService->isStockAvailable($item['book_id'], $item['quantity'])) {
                    throw new InsufficientStockException($book['title'], $book['stock'], $item['quantity']);
                }

                LoanDetail::create([
                    'loan_id' => $loan->id,
                    'book_id' => $book['id'],
                    'book_title' => $book['title'],
                    'book_isbn' => $book['isbn'],
                    'quantity' => $item['quantity'],
                ]);

                $this->bookService->reduceStock($item['book_id'], $item['quantity']);
            }

            $this->memberService->markBorrowing($memberId);

            event(new BookBorrowed($loan->load('details')));

            return $loan->load('details');
        });
    }

    public function returnLoan(Loan $loan, ?\DateTimeInterface $returnedAt = null): Loan
    {
        return DB::transaction(function () use ($loan, $returnedAt) {
            $returnedAt = $returnedAt ?? now();
            $denda = Denda::fromDates($loan->due_at, $returnedAt);

            foreach ($loan->details as $detail) {
                $this->bookService->increaseStock($detail->book_id, $detail->quantity);
            }

            $loan->update(['returned_at' => $returnedAt, 'status' => 'returned']);

            if ($denda->getAmount() > 0) {
                Fine::create([
                    'loan_id' => $loan->id,
                    'days_late' => $denda->getDaysLate(),
                    'amount' => $denda->getAmount(),
                ]);
            }

            $stillBorrowing = Loan::where('member_id', $loan->member_id)
                ->whereNull('returned_at')
                ->exists();

            if (!$stillBorrowing) {
                $this->memberService->markActive($loan->member_id);
            }

            return $loan->fresh(['details', 'fines']);
        });
    }
}