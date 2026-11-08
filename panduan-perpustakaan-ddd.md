# Panduan Tugas: perpustakaan-ddd (Laravel + DDD modular)

Semua perintah dijalankan di **PowerShell**, kecuali blok berlabel **Tinker**.
Kode semua file (35 file) ditulis otomatis oleh `setup-perpustakaan-ddd.ps1`, jadi kamu tidak perlu menyalin kode satu per satu.

---
## LANGKAH 1 — Buat proyek Laravel baru

```powershell
cd D:\Backend-Development
composer create-project laravel/laravel perpustakaan-ddd
cd perpustakaan-ddd
```
Pastikan `php -v` sudah 8.4.1 atau lebih baru (PHP 8.5 yang kamu pakai sudah benar).

Cek file database ada:
```powershell
Test-Path database/database.sqlite
```
Kalau hasilnya `False`:
```powershell
New-Item -ItemType File -Force database/database.sqlite
```

## LANGKAH 2 — Taruh skrip di folder proyek, lalu jalankan

1. Salin file `setup-perpustakaan-ddd.ps1` ke dalam folder `D:\Backend-Development\perpustakaan-ddd` (sejajar dengan file `artisan`).
2. Jalankan:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup-perpustakaan-ddd.ps1
```
Hasil yang benar: lima tahap `[1/5]` sampai `[5/5]`, semua baris `OK`, dan di akhir `semua file lolos cek sintaks`.

Skrip ini melakukan:
- membuat folder modul Catalog, Membership, Circulation, Shared
- menambahkan autoload `Modules\` di `composer.json`
- membuat 11 migration dengan urutan yang benar, lalu mengisi kodenya
- menulis semua kode: Isbn, Denda, exception, kontrak, model, service, event, listener, controller, route, `AppServiceProvider`, dan seeder

## LANGKAH 3 — Migrate dan seed

```powershell
composer dump-autoload
php artisan migrate
php artisan db:seed
```
- `migrate`: 11 migration baru muncul `DONE` (authors, publishers, categories, books, book_category, roles, members, member_role, loans, loan_details, fines).
- `db:seed`: muncul `INFO Seeding database.` tanpa error.

Kalau `db:seed` error "UNIQUE constraint failed" (karena sudah pernah di-seed):
```powershell
php artisan migrate:fresh --seed
```

## LANGKAH 4 — Jalankan server dan cek di browser

```powershell
php artisan route:clear
php artisan serve
```
Buka di browser (biarkan terminal tetap berjalan):
- `http://127.0.0.1:8000/books` → daftar 5 buku (JSON)
- `http://127.0.0.1:8000/books?q=Contoh` → pencarian
- `http://127.0.0.1:8000/books?category=2` → buku di kategori 2
- `http://127.0.0.1:8000/loans` → daftar peminjaman (awalnya kosong `[]`)

Hentikan server dengan `Ctrl+C`.

## LANGKAH 5 — Uji lewat Tinker

```powershell
php artisan tinker
```
Ketik satu baris per Enter.

**5a. Value Object**
```php
use Modules\Shared\ValueObjects\Isbn;
use Modules\Shared\ValueObjects\Denda;
(string) new Isbn('9780306406157');
(string) new Isbn('978-0-306-40615-7');
new Isbn('1234567890123');
new Isbn('123');
(new Denda(5))->getAmount();
(string) new Denda(5);
new Denda(-1);
Denda::fromDates(now()->subDays(3), now())->getAmount();
```
Hasil: `"9780306406157"` dua kali, dua `InvalidArgumentException` untuk ISBN salah, `5000`, `"Rp 5.000"`, error `Hari terlambat tidak boleh negatif`, dan `3000`.

**5b. Relasi dan scope**
```php
use Modules\Catalog\Models\Book;
use Modules\Catalog\Models\Category;
Book::with('categories')->find(1)->categories->pluck('name');
Category::find(2)->parent->name;
Category::find(1)->children->pluck('name');
Book::available()->count();
Book::search('Contoh')->count();
Book::inCategory(2)->count();
```
Hasil: `["Teknologi","Pemrograman"]`, `"Teknologi"`, `["Pemrograman"]`, `5`, `5`, `3`.

**5c. Cek N+1 (eager loading)**
```php
DB::enableQueryLog();
$books = Book::all();
foreach ($books as $b) { $b->author; $b->publisher; $b->categories; }
echo count(DB::getQueryLog());
DB::flushQueryLog();
$books = Book::with(['author', 'publisher', 'categories'])->get();
foreach ($books as $b) { $b->author; $b->publisher; $b->categories; }
echo count(DB::getQueryLog());
```
Angka pertama besar (sekitar 16), angka kedua kecil (sekitar 4).

**5d. Peminjaman**
```php
use Modules\Circulation\Models\Loan;
use Modules\Circulation\Models\LoanDetail;
use Modules\Membership\Models\Member;
$svc = app(\Modules\Circulation\Services\LoanService::class);
$loan = $svc->borrow(1, [['book_id' => 1, 'quantity' => 2], ['book_id' => 2, 'quantity' => 1]]);
Loan::count();
$loan->details->count();
Book::find(1)->stock;
Book::find(2)->stock;
Member::find(1)->status;
LoanDetail::first()->book_title;
LoanDetail::first()->book_isbn;
```
Hasil: `1`, `2`, `8`, `9`, `"borrowing"`, `"Contoh Buku 1"`, `"9780306406157"`.

**5e. Uji gagal: stok tidak cukup (transaction harus rollback)**
```php
try { $svc->borrow(2, [['book_id' => 3, 'quantity' => 1], ['book_id' => 5, 'quantity' => 99]]); } catch (\Throwable $e) { echo get_class($e) . ': ' . $e->getMessage(); }
Loan::count();
Book::find(3)->stock;
Member::find(2)->status;
```
Hasil: pesan `InsufficientStockException: Stok Contoh Buku 5 tidak mencukupi. Tersedia: 10, diminta: 99`, lalu `1`, `10`, `"active"`.

**5f. Pengembalian terlambat dan denda**
```php
$loan = Loan::first();
$loan->update(['due_at' => now()->subDays(5)]);
$r = $svc->returnLoan($loan->fresh());
$r->status;
$r->fines->first()->days_late;
$r->fines->first()->amount;
Book::find(1)->stock;
Book::find(2)->stock;
Member::find(1)->status;
```
Hasil: `"returned"`, `5`, `"5000.00"`, `10`, `10`, `"active"`.

**5g. Soft delete**
```php
Book::count();
Book::find(1)->delete();
Book::count();
Book::withTrashed()->count();
Book::onlyTrashed()->first()->restore();
Book::count();
Member::find(2)->delete(); Member::count();
Member::withTrashed()->count();
Member::onlyTrashed()->first()->restore(); Member::count();
Loan::first()->delete(); Loan::count();
Loan::withTrashed()->count();
Loan::onlyTrashed()->first()->restore(); Loan::count();
exit
```
Hasil: `5`, `4`, `5`, `5`; lalu `1`, `2`, `2`; lalu `0`, `1`, `1`.

**5h. Cek log event**
```powershell
Get-Content storage/logs/laravel.log -Tail 5
```
Harus ada baris `Buku dipinjam` dengan `loan_number`, `member_id`, dan `jumlah_item`.

## LANGKAH 6 — Git dan push ke GitHub

1. Di browser, buat repo kosong `perpustakaan-ddd` di akun `septiyana-hardiyanti` (tanpa README, `.gitignore`, atau license).
2. Di PowerShell (ganti `EMAIL_GITHUB_KAMU` dengan email akun GitHub-mu):
```powershell
git init
git branch -M main
git config user.name "Septiyana Hardiyanti"
git config user.email "EMAIL_GITHUB_KAMU"
git remote add origin https://github.com/septiyana-hardiyanti/perpustakaan-ddd.git
git add .
git status
git commit -m "feat: sistem perpustakaan modular dengan DDD, transaction, soft deletes, event, dan value object"
git push -u origin main
```
Untuk proyek ini dokumen memakai `git add .`, dan itu aman karena `.env` serta `database.sqlite` sudah diabaikan oleh `.gitignore` bawaan Laravel. Cek `git status` sebelum commit: file `.env` tidak boleh muncul.

---
## Kalau ada masalah

| Gejala | Penyebab dan solusi |
|---|---|
| `Class "Modules\..." not found` | Jalankan `composer dump-autoload`. Cek `composer.json` punya `"Modules\\": "app/Modules/"` di bagian `psr-4`. |
| `Nothing to migrate` padahal migration baru | `AppServiceProvider` belum terbaca. Jalankan ulang skrip, lalu `php artisan config:clear`. |
| `table ... already exists` | Jalankan `php artisan migrate:fresh --seed`. |
| Route `/books` 404 | Jalankan `php artisan route:clear`, lalu cek `routes/web.php` berisi route `books` dan `loans`. |
| Skrip menolak jalan ("execution policy") | Pakai perintah `powershell -ExecutionPolicy Bypass -File .\setup-perpustakaan-ddd.ps1`. |
