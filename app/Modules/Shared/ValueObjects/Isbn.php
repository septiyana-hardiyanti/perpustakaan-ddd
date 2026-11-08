<?php

namespace Modules\Shared\ValueObjects;

use InvalidArgumentException;

class Isbn
{
    private string $value;

    public function __construct(string $value)
    {
        $digits = str_replace(['-', ' '], '', $value);

        if (!preg_match('/^\d{13}$/', $digits) || !self::checksumValid($digits)) {
            throw new InvalidArgumentException("ISBN tidak valid: {$value}");
        }

        $this->value = $digits;
    }

    private static function checksumValid(string $digits): bool
    {
        $sum = 0;
        for ($i = 0; $i < 12; $i++) {
            $sum += ((int) $digits[$i]) * ($i % 2 === 0 ? 1 : 3);
        }

        return ((10 - ($sum % 10)) % 10) === (int) $digits[12];
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function equals(Isbn $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}