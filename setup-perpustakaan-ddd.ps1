# =====================================================================
# setup-perpustakaan-ddd.ps1
# Menulis SEMUA file kode tugas "perpustakaan-ddd" secara otomatis.
# Jalankan di PowerShell, DI DALAM folder proyek (yang ada file "artisan").
# Aman dijalankan ulang (file ditimpa, migration tidak dibuat dobel).
# =====================================================================
$ErrorActionPreference = 'Stop'

if (-not (Test-Path 'artisan')) {
    Write-Host 'ERROR: file "artisan" tidak ditemukan. cd dulu ke folder proyek perpustakaan-ddd.' -ForegroundColor Red
    exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding($false)   # UTF-8 tanpa BOM (penting untuk PHP)
function Write-Code([string]$Path, [string]$Content) {
    $full = Join-Path (Get-Location).Path $Path
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllText($full, $Content, $utf8)
    Write-Host "  OK  $Path"
}

function Write-Migration([string]$Name, [string]$Dir, [string]$Content) {
    $found = Get-ChildItem $Dir -Filter "*_$Name.php" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
    if (-not $found) {
        php artisan make:migration $Name --path=$Dir | Out-Null
        Start-Sleep -Seconds 1     # supaya timestamp tiap migration berbeda dan urutannya benar
        $found = Get-ChildItem $Dir -Filter "*_$Name.php" | Sort-Object Name | Select-Object -First 1
    }
    [System.IO.File]::WriteAllText($found.FullName, $Content, $utf8)
    Write-Host "  OK  $Dir/$($found.Name)"
}

Write-Host "`n[1/5] Membuat folder modul..." -ForegroundColor Cyan
"Models","Migrations","Services","Events","Listeners","Http/Controllers" | ForEach-Object { New-Item -ItemType Directory -Force "app/Modules/Catalog/$_" | Out-Null }
"Models","Migrations","Services" | ForEach-Object { New-Item -ItemType Directory -Force "app/Modules/Membership/$_" | Out-Null }
"Models","Migrations","Services","Events","Listeners","Http/Controllers" | ForEach-Object { New-Item -ItemType Directory -Force "app/Modules/Circulation/$_" | Out-Null }
"Contracts","ValueObjects","Exceptions" | ForEach-Object { New-Item -ItemType Directory -Force "app/Modules/Shared/$_" | Out-Null }
Write-Host '  OK  folder modul siap'

Write-Host "`n[2/5] Menambahkan autoload Modules\ ke composer.json..." -ForegroundColor Cyan
$cj = [System.IO.File]::ReadAllText((Join-Path (Get-Location).Path 'composer.json'))
if ($cj.Contains('"Modules\\"')) {
    Write-Host '  OK  sudah ada, dilewati'
} else {
    $new = $cj.Replace('"App\\": "app/",', '"App\\": "app/",' + "`n            " + '"Modules\\": "app/Modules/",')
    if ($new -eq $cj) {
        Write-Host '  !!  GAGAL otomatis. Tambahkan manual di composer.json > autoload > psr-4:  "Modules\\": "app/Modules/",' -ForegroundColor Yellow
    } else {
        [System.IO.File]::WriteAllText((Join-Path (Get-Location).Path 'composer.json'), $new, $utf8)
        Write-Host '  OK  composer.json diperbarui'
    }
}

Write-Host "`n[3/5] Membuat 11 migration (berurutan)..." -ForegroundColor Cyan
Write-Migration 'create_authors_table' 'app/Modules/Catalog/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('authors', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('authors');
    }
};
'@
Write-Migration 'create_publishers_table' 'app/Modules/Catalog/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('publishers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('publishers');
    }
};
'@
Write-Migration 'create_categories_table' 'app/Modules/Catalog/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->foreignId('parent_id')->nullable()->constrained('categories')->onDelete('set null');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
'@
Write-Migration 'create_books_table' 'app/Modules/Catalog/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('books', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('isbn', 13)->unique();
            $table->foreignId('author_id')->constrained('authors')->onDelete('cascade');
            $table->foreignId('publisher_id')->constrained('publishers')->onDelete('cascade');
            $table->integer('stock')->default(0);
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('books');
    }
};
'@
Write-Migration 'create_book_category_table' 'app/Modules/Catalog/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('book_category', function (Blueprint $table) {
            $table->foreignId('book_id')->constrained('books')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            $table->timestamp('added_at')->useCurrent();
            $table->primary(['book_id', 'category_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('book_category');
    }
};
'@
Write-Migration 'create_roles_table' 'app/Modules/Membership/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('slug')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};
'@
Write-Migration 'create_members_table' 'app/Modules/Membership/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('members', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('status')->default('active');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('members');
    }
};
'@
Write-Migration 'create_member_role_table' 'app/Modules/Membership/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_role', function (Blueprint $table) {
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->foreignId('role_id')->constrained('roles')->onDelete('cascade');
            $table->primary(['member_id', 'role_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_role');
    }
};
'@
Write-Migration 'create_loans_table' 'app/Modules/Circulation/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->string('loan_number')->unique();
            $table->timestamp('borrowed_at')->useCurrent();
            $table->timestamp('due_at')->nullable();
            $table->timestamp('returned_at')->nullable();
            $table->string('status')->default('borrowed');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loans');
    }
};
'@
Write-Migration 'create_loan_details_table' 'app/Modules/Circulation/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loan_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')->constrained('loans')->onDelete('cascade');
            $table->foreignId('book_id')->constrained('books')->onDelete('cascade');
            $table->string('book_title');
            $table->string('book_isbn', 13);
            $table->integer('quantity');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loan_details');
    }
};
'@
Write-Migration 'create_fines_table' 'app/Modules/Circulation/Migrations' @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')->constrained('loans')->onDelete('cascade');
            $table->integer('days_late');
            $table->decimal('amount', 12, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fines');
    }
};
'@

Write-Host "`n[4/5] Menulis kode (value object, model, service, event, controller, route, seeder)..." -ForegroundColor Cyan
Write-Code 'app/Modules/Shared/ValueObjects/Isbn.php' @'
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
'@
Write-Code 'app/Modules/Shared/ValueObjects/Denda.php' @'
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
'@
Write-Code 'app/Modules/Shared/Exceptions/InsufficientStockException.php' @'
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
'@
Write-Code 'app/Modules/Shared/Contracts/BookServiceInterface.php' @'
<?php

namespace Modules\Shared\Contracts;

interface BookServiceInterface
{
    public function getBookForLoan(int $bookId): ?array;

    public function isStockAvailable(int $bookId, int $quantity): bool;

    public function reduceStock(int $bookId, int $quantity): bool;

    public function increaseStock(int $bookId, int $quantity): void;
}
'@
Write-Code 'app/Modules/Shared/Contracts/MemberServiceInterface.php' @'
<?php

namespace Modules\Shared\Contracts;

interface MemberServiceInterface
{
    public function canBorrow(int $memberId): bool;

    public function markBorrowing(int $memberId): void;

    public function markActive(int $memberId): void;
}
'@
Write-Code 'app/Modules/Catalog/Models/Author.php' @'
<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Model;

class Author extends Model
{
    protected $fillable = ['name'];

    public function books()
    {
        return $this->hasMany(Book::class);
    }
}
'@
Write-Code 'app/Modules/Catalog/Models/Publisher.php' @'
<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Model;

class Publisher extends Model
{
    protected $fillable = ['name'];

    public function books()
    {
        return $this->hasMany(Book::class);
    }
}
'@
Write-Code 'app/Modules/Catalog/Models/Category.php' @'
<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    protected $fillable = ['name', 'slug', 'parent_id'];

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(Category::class, 'parent_id');
    }

    public function books(): BelongsToMany
    {
        return $this->belongsToMany(Book::class, 'book_category')->withPivot('added_at');
    }
}
'@
Write-Code 'app/Modules/Catalog/Models/Book.php' @'
<?php

namespace Modules\Catalog\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Book extends Model
{
    use SoftDeletes;

    protected $fillable = ['title', 'isbn', 'author_id', 'publisher_id', 'stock'];

    public function author(): BelongsTo
    {
        return $this->belongsTo(Author::class);
    }

    public function publisher(): BelongsTo
    {
        return $this->belongsTo(Publisher::class);
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'book_category')->withPivot('added_at');
    }

    public function scopeAvailable(Builder $query): Builder
    {
        return $query->where('stock', '>', 0);
    }

    public function scopeSearch(Builder $query, string $keyword): Builder
    {
        return $query->where(function ($q) use ($keyword) {
            $q->where('title', 'like', "%{$keyword}%")
                ->orWhere('isbn', 'like', "%{$keyword}%");
        });
    }

    public function scopeInCategory(Builder $query, int $categoryId): Builder
    {
        return $query->whereHas('categories', function ($q) use ($categoryId) {
            $q->where('categories.id', $categoryId);
        });
    }

    public function isInStock(int $quantity = 1): bool
    {
        return $this->stock >= $quantity;
    }
}
'@
Write-Code 'app/Modules/Membership/Models/Role.php' @'
<?php

namespace Modules\Membership\Models;

use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    protected $fillable = ['name', 'slug'];

    public function members()
    {
        return $this->belongsToMany(Member::class, 'member_role');
    }
}
'@
Write-Code 'app/Modules/Membership/Models/Member.php' @'
<?php

namespace Modules\Membership\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Member extends Model
{
    use SoftDeletes;

    protected $fillable = ['name', 'email', 'status'];

    public function roles()
    {
        return $this->belongsToMany(Role::class, 'member_role');
    }
}
'@
Write-Code 'app/Modules/Circulation/Models/Loan.php' @'
<?php

namespace Modules\Circulation\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Loan extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'member_id', 'loan_number', 'borrowed_at',
        'due_at', 'returned_at', 'status',
    ];

    protected $casts = [
        'borrowed_at' => 'datetime',
        'due_at' => 'datetime',
        'returned_at' => 'datetime',
    ];

    public function details()
    {
        return $this->hasMany(LoanDetail::class);
    }

    public function fines()
    {
        return $this->hasMany(Fine::class);
    }
}
'@
Write-Code 'app/Modules/Circulation/Models/LoanDetail.php' @'
<?php

namespace Modules\Circulation\Models;

use Illuminate\Database\Eloquent\Model;

class LoanDetail extends Model
{
    protected $fillable = ['loan_id', 'book_id', 'book_title', 'book_isbn', 'quantity'];

    public function loan()
    {
        return $this->belongsTo(Loan::class);
    }
}
'@
Write-Code 'app/Modules/Circulation/Models/Fine.php' @'
<?php

namespace Modules\Circulation\Models;

use Illuminate\Database\Eloquent\Model;

class Fine extends Model
{
    protected $fillable = ['loan_id', 'days_late', 'amount'];

    protected $casts = ['amount' => 'decimal:2'];

    public function loan()
    {
        return $this->belongsTo(Loan::class);
    }
}
'@
Write-Code 'app/Modules/Catalog/Services/BookService.php' @'
<?php

namespace Modules\Catalog\Services;

use Modules\Catalog\Models\Book;
use Modules\Shared\Contracts\BookServiceInterface;

class BookService implements BookServiceInterface
{
    public function getBookForLoan(int $bookId): ?array
    {
        $book = Book::find($bookId);

        if (!$book) {
            return null;
        }

        return [
            'id' => $book->id,
            'title' => $book->title,
            'isbn' => $book->isbn,
            'stock' => $book->stock,
        ];
    }

    public function isStockAvailable(int $bookId, int $quantity): bool
    {
        $book = Book::find($bookId);

        return $book && $book->isInStock($quantity);
    }

    public function reduceStock(int $bookId, int $quantity): bool
    {
        $book = Book::lockForUpdate()->find($bookId);

        if (!$book || !$book->isInStock($quantity)) {
            return false;
        }

        $book->decrement('stock', $quantity);

        return true;
    }

    public function increaseStock(int $bookId, int $quantity): void
    {
        Book::withTrashed()->where('id', $bookId)->increment('stock', $quantity);
    }
}
'@
Write-Code 'app/Modules/Membership/Services/MemberService.php' @'
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
'@
Write-Code 'app/Modules/Circulation/Events/BookBorrowed.php' @'
<?php

namespace Modules\Circulation\Events;

use Modules\Circulation\Models\Loan;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class BookBorrowed
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public Loan $loan
    ) {}
}
'@
Write-Code 'app/Modules/Circulation/Listeners/LogBookBorrowed.php' @'
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
'@
Write-Code 'app/Modules/Circulation/Services/LoanService.php' @'
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
'@
Write-Code 'app/Providers/AppServiceProvider.php' @'
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
'@
Write-Code 'database/seeders/DatabaseSeeder.php' @'
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Modules\Catalog\Models\Author;
use Modules\Catalog\Models\Book;
use Modules\Catalog\Models\Category;
use Modules\Catalog\Models\Publisher;
use Modules\Membership\Models\Member;
use Modules\Membership\Models\Role;
use Modules\Shared\ValueObjects\Isbn;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Role dan anggota
        Role::create(['name' => 'Administrator', 'slug' => 'admin']);
        $anggotaRole = Role::create(['name' => 'Anggota', 'slug' => 'anggota']);

        foreach ([1, 2] as $i) {
            $member = Member::create([
                'name' => "Anggota Contoh {$i}",
                'email' => "anggota{$i}@example.com",
            ]);
            $member->roles()->attach($anggotaRole);
        }

        // Kategori (Pemrograman adalah sub-kategori Teknologi)
        $teknologi = Category::create(['name' => 'Teknologi', 'slug' => 'teknologi']);
        $pemrograman = Category::create(['name' => 'Pemrograman', 'slug' => 'pemrograman', 'parent_id' => $teknologi->id]);
        $sains = Category::create(['name' => 'Sains', 'slug' => 'sains']);

        $penulis1 = Author::create(['name' => 'Penulis Contoh A']);
        $penulis2 = Author::create(['name' => 'Penulis Contoh B']);
        $penerbit1 = Publisher::create(['name' => 'Penerbit Contoh 1']);
        $penerbit2 = Publisher::create(['name' => 'Penerbit Contoh 2']);

        // 5 buku, ISBN-13 valid, stok 10 semua
        $data = [
            ['9780306406157', $penulis1, $penerbit1, [$teknologi, $pemrograman]],
            ['9780134685991', $penulis1, $penerbit1, [$pemrograman]],
            ['9780596007126', $penulis2, $penerbit2, [$pemrograman]],
            ['9780321125217', $penulis2, $penerbit2, [$teknologi]],
            ['9780201633610', $penulis1, $penerbit1, [$sains]],
        ];

        foreach ($data as $n => [$isbn, $author, $publisher, $cats]) {
            $book = Book::create([
                'title' => 'Contoh Buku ' . ($n + 1),
                'isbn' => (new Isbn($isbn))->getValue(),
                'author_id' => $author->id,
                'publisher_id' => $publisher->id,
                'stock' => 10,
            ]);

            $book->categories()->attach(
                collect($cats)->pluck('id')->toArray(),
                ['added_at' => now()]
            );
        }
    }
}
'@
Write-Code 'app/Modules/Catalog/Http/Controllers/BookController.php' @'
<?php

namespace Modules\Catalog\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Modules\Catalog\Models\Book;

class BookController extends Controller
{
    public function index(Request $request)
    {
        $books = Book::with(['author', 'publisher', 'categories'])
            ->available()
            ->when($request->query('q'), fn ($query, $keyword) => $query->search($keyword))
            ->when($request->query('category'), fn ($query, $id) => $query->inCategory((int) $id))
            ->get();

        return response()->json($books);
    }
}
'@
Write-Code 'app/Modules/Circulation/Http/Controllers/LoanController.php' @'
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
'@
Write-Code 'routes/web.php' @'
<?php

use Illuminate\Support\Facades\Route;
use Modules\Catalog\Http\Controllers\BookController;
use Modules\Circulation\Http\Controllers\LoanController;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/books', [BookController::class, 'index']);
Route::get('/loans', [LoanController::class, 'index']);
'@

Write-Host "`n[5/5] Cek sintaks semua file PHP modul..." -ForegroundColor Cyan
$bad = 0
Get-ChildItem app/Modules -Recurse -Filter *.php | ForEach-Object {
    $out = php -l $_.FullName 2>&1
    if ($LASTEXITCODE -ne 0) { $bad++; Write-Host "  GAGAL: $($_.FullName)" -ForegroundColor Red; Write-Host $out }
}
if ($bad -eq 0) { Write-Host '  OK  semua file lolos cek sintaks' -ForegroundColor Green }

Write-Host "`nSELESAI. Lanjutkan dengan perintah ini, satu per satu:" -ForegroundColor Green
Write-Host '  composer dump-autoload'
Write-Host '  php artisan migrate'
Write-Host '  php artisan db:seed'
Write-Host '  php artisan route:clear'
Write-Host '  php artisan serve'
