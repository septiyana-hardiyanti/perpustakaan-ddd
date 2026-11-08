<?php

namespace App\Providers;

use Illuminate\Support\Facades\Event;
use Illuminate\Support\ServiceProvider;
use Modules\Catalog\Services\BookService;
use Modules\Circulation\Events\BookBorrowed;
use Modules\Circulation\Listeners\LogBookBorrowed;
use Modules\Membership\Services\MemberService;
use Modules\Shared\Contracts\BookServiceInterface;
use Modules\Shared\Contracts\MemberServiceInterface;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(BookServiceInterface::class, BookService::class);
        $this->app->bind(MemberServiceInterface::class, MemberService::class);
    }

    public function boot(): void
    {
        $this->loadMigrationsFrom([
            base_path('app/Modules/Catalog/Migrations'),
            base_path('app/Modules/Membership/Migrations'),
            base_path('app/Modules/Circulation/Migrations'),
        ]);

        Event::listen(BookBorrowed::class, LogBookBorrowed::class);
    }
}