<?php

namespace Modules\Shared\Exceptions;

use Exception;

class InsufficientStockException extends Exception
{
    public function __construct(string $itemName, int $available, int $requested)
    {
        parent::__construct(
            "Stok {$itemName} tidak mencukupi. Tersedia: {$available}, diminta: {$requested}"
        );
    }
}