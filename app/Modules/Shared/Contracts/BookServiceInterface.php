<?php

namespace Modules\Shared\Contracts;

interface BookServiceInterface
{
    public function getBookForLoan(int $bookId): ?array;

    public function isStockAvailable(int $bookId, int $quantity): bool;

    public function reduceStock(int $bookId, int $quantity): bool;

    public function increaseStock(int $bookId, int $quantity): void;
}