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