<?php

namespace Modules\Shared\Contracts;

interface MemberServiceInterface
{
    public function canBorrow(int $memberId): bool;

    public function markBorrowing(int $memberId): void;

    public function markActive(int $memberId): void;
}