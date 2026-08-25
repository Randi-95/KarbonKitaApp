# Panduan Implementasi Backend Laravel (Step-by-Step)
**Proyek: KarbonKita (Laravel 12)**

Dokumen ini adalah panduan implementasi langkah-demi-langkah bagi Backend Laravel Engineer.

---

## 1. Alur Kerja Pengembangan (Milestones)

```
[Fase 1: Setup & Migrasi] ➔ [Fase 2: Auth Sanctum] ➔ [Fase 3: Misi, Saga, & Gemini AI] ➔ [Fase 4: Voucher & Xendit]
```

---

## FASE 1: DATABASE & MIGRATIONS SETUP
Membuat semua tabel database beserta relasinya.

### Langkah-langkah:
1. Jalankan `php artisan make:model <ModelName> -m` untuk semua tabel.
2. Definisikan migrasi sesuai `Database_Schema_KarbonKita.md`.
3. Definisikan relasi Eloquent di Model:
   - `User.php` ➔ `hasOne(WargaProfile::class)`, `hasOne(MitraProfile::class)`
   - `WargaProfile.php` ➔ `belongsTo(User::class)`
   - `MitraProfile.php` ➔ `belongsTo(User::class)`, `hasMany(Voucher::class)`
   - `Mission.php` ➔ `hasMany(UserMission::class)`
4. Buat Seeder untuk data misi dan kategori (Pilah Sampah, Mobilitas, Quiz).

---

## FASE 2: AUTENTIKASI (LARAVEL SANCTUM)
Membuat user bisa mendaftar (Register) dan masuk (Login).

### Logika:
1. **Setup**: Jalankan `php artisan install:api`.
2. **Register (`POST /api/auth/register`)**: 
   - Gunakan `DB::transaction()` untuk membuat `User` + `Profile` (Warga/Mitra).
   - Simpan lokasi (Kota, Distrik, RT/RW).
3. **Login (`POST /api/auth/login`)**:
   - Return `$user->createToken('auth_token')->plainTextToken`.

---

## FASE 3: MISI AKTIVITAS & SAGA MAP (QUIZ)
Implementasi misi berbasis aktivitas fisik dan kuis harian.

### Logika Internal:

#### A. Misi Aktivitas (Activity Missions)
1. **Get Active Missions (`GET /api/missions/active`)**:
   - Query tabel `missions` dengan `category IN ('mobility', 'waste')` dan `is_active = true`.
   - Return daftar misi yang tersedia untuk dikerjakan.
2. **AI Verification (`POST /api/missions/verify-waste`)**:
   - `GeminiService` mengirim gambar ke API Vision.
   - **Anti-Fraud**: Cek EXIF metadata (koordinat & waktu). Jika lokasi foto jauh dari koordinat user saat ini, batalkan.
   - Berikan poin jika `confidence_score` > 85%.
3. **Mobility Sync (`POST /api/missions/mobility-sync`)**:
   - Terima data GPS, hitung jarak dan estimasi CO2 saved.
   - Berikan XP reward berdasarkan jarak tempuh.

#### B. Saga Map (Quiz Missions)
1. **Get Quizzes (`GET /api/saga/quizzes`)**:
   - Query tabel `missions` dengan `category = 'quiz'`.
   - Tampilkan status: belum dikerjakan / sudah selesai hari ini.
2. **Submit Answer (`POST /api/saga/answer`)**:
   - Validasi jawaban terhadap `quizzes.correct_answer`.
   - Berikan XP reward jika benar.
   - Update streak user.

---

## FASE 4: VOUCHER & DISBURSEMENT XENDIT
Menangani ekonomi sirkular.

### Logika Internal (`POST /api/vouchers/redeem`):
1. Mitra scan `unique_code` dari tabel `voucher_claims`.
2. **Database Transaction**:
   - Ubah status voucher ke `used`.
   - **Xendit API**: Panggil `Payouts::create` (disbursement).
   - Jika Xendit sukses: Simpan ID disbursement ke tabel `disbursements`, update saldo Mitra.
   - Jika Xendit gagal: `DB::rollBack()` status voucher kembali ke `unused`.

---

## 📝 Prompt untuk AI Agent (Untuk Seluruh Fase)

> "Saya sedang membangun backend Laravel 12 untuk KarbonKita. Gunakan struktur Laravel 12 minimalis (konfigurasi di bootstrap/app.php).
> 
> Tugas Anda: 
> 1. Gunakan Laravel Sanctum untuk Auth.
> 2. Implementasikan API menggunakan Laravel Resources.
> 3. Gunakan DB::transaction() untuk endpoint finansial (Voucher/Payout).
> 4. Buat service layer untuk integrasi Gemini AI (Vision) dan Xendit (Disbursement).
> 5. Patuhi API Contract di D:\KarbonKita Docs\API_Contract_KarbonKita.md.
> 
> Mulai dengan langkah: [Sebutkan Fase yang ingin dikerjakan, misal: Fase 1]"

---

## 2. Testing API (HTTP Client)
Gunakan file `api_test.http` di root proyek Anda:

```http
### Get Leaderboard
GET http://localhost:8000/api/leaderboard?scope=rt&timeframe=weekly
Authorization: Bearer 1|token_string_here

### Verify Waste (Fase 3)
POST http://localhost:8000/api/missions/verify-waste
Authorization: Bearer 1|token_string_here
Content-Type: multipart/form-data

< image_file_path >
```
