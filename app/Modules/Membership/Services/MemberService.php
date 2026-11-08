<?php

namespace Modules\Membership\Services;

use Modules\Membership\Models\Member;
use Modules\Shared\Contracts\MemberServiceInterface;

class MemberService implements MemberServiceInterface
{
    public function canBorrow(int $memberId): bool
    {
        $member = Member::find($memberId);

        return $member && in_array($member->status, ['active', 'borrowing'], true);
    }

    public function markBorrowing(int $memberId): void
    {
        Member::where('id', $memberId)->update(['status' => 'borrowing']);
    }

    public function markActive(int $memberId): void
    {
        Member::where('id', $memberId)->update(['status' => 'active']);
    }
}