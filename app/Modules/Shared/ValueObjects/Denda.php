<?php

namespace Modules\Shared\ValueObjects;

use InvalidArgumentException;

class Denda
{
    public const RATE_PER_DAY = 1000;

    private int $daysLate;
    private int $amount;

    public function __construct(int $daysLate, int $ratePerDay = self::RATE_PER_DAY)
    {
        if ($daysLate < 0) {
            throw new InvalidArgumentException('Hari terlambat tidak boleh negatif');
        }

        $this->daysLate = $daysLate;
        $this->amount = $daysLate * $ratePerDay;
    }

    public static function fromDates(\DateTimeInterface $due, \DateTimeInterface $returned): self
    {
        $seconds = $returned->getTimestamp() - $due->getTimestamp();

        return new self($seconds > 0 ? intdiv($seconds, 86400) : 0);
    }

    public function getDaysLate(): int
    {
        return $this->daysLate;
    }

    public function getAmount(): int
    {
        return $this->amount;
    }

    public function __toString(): string
    {
        return 'Rp ' . number_format($this->amount, 0, ',', '.');
    }
}