# Roadmap Pengembangan KarbonKita — Missions / Gemini (Fase 3 Fisik)

> Status dokumen: **SELESAI 2026-09-05** — semua Langkah 0–5 dieksekusi dan hijau.
> Full suite akhir: **64 passed, 319 assertions** (naik dari 58 setelah tambahan
> prompt per misi, lihat `backend/test-reports/LANGKAH-6-mission-prompts.md`).
> Laporan per langkah di `backend/test-reports/LANGKAH-*.md`. Acuan otoritatif tetap:
> `PROJECT_CONTEXT.md`, `API_Contract_KarbonKita.md v1.2.0`,
> `Database_Schema_KarbonKita.md`, `BACKEND_IMPLEMENTATION_STEPS.md`,
> `KarbonKita_API.postman_collection.json`.

## 0. Ringkasan status (hasil audit)

Backend Laravel 12 + Sanctum. 10/17 endpoint kontrak sudah jadi:

- DONE: `POST auth/register`, `POST auth/login`, `GET user/dashboard`,
  `GET leaderboard`, `GET saga/quizzes`, `POST saga/answer`,
  `GET user/carbon-stats`, `GET vouchers`, `POST vouchers/claim`,
  `GET user/my-vouchers` + ekstra `POST auth/logout`, `GET user`.
- TODO (scope roadmap ini): `GET missions/active`,
  `POST missions/verify-waste`, `POST missions/mobility-sync`.
- TODO di luar scope: `GET merchant/dashboard`, `POST vouchers/redeem`
  (Xendit), `GET admin/merchants/pending`, `POST admin/merchants/{id}/verify`.
- Frontend Flutter: 0% (masih template counter, hanya deps di `pubspec.yaml`).

Pola yang wajib ditiru: `app/Http/Controllers/SagaController.php`
(transaction + `lockForUpdate` + `StreakService` + `LevelService` +
envelope `{success,message,data}`) dan
`app/Http/Controllers/VoucherController.php:41-104`
(transaksi finansial + `PointTransaction`).

Kolom DB untuk scope ini sudah siap, tidak perlu migrasi wajib:

- `missions` (`2024_01_02_000003`): `category mobility|waste|quiz`,
  `xp_reward`, `points_reward`, `is_active`.
- `user_missions` (`2024_01_02_000004`): `proof_image_url/hash`,
  `ai_gemini_response` JSON, `confidence_score`, `status`, `anti_fraud_flagged`.
- `mobility_logs` (`2024_01_02_000005`): `start_point/end_point/route_coordinates`
  JSON, `distance_km`, `co2_saved_grams`, `duration_minutes`,
  `transport_mode walking|cycling|public_transport`.
- `point_transactions` (`2024_01_02_000009`): ledger audit.
- Seeder: `database/seeders/MissionSeeder.php` (3 mobility, 3 waste, 2 quiz).

## 1. Target roadmap ini

1. `GET /api/missions/active` — daftar misi mobility & waste aktif.
2. `POST /api/missions/verify-waste` — upload foto sampah, validasi
   server-side via `GeminiService`, anti-fraud hash + EXIF, reward jika
   `confidence >= threshold`.
3. `POST /api/missions/mobility-sync` — sinkronisasi GPS, validasi
   kecepatan, hitung CO2, reward XP/poin.

Kriteria selesai (acceptance):

- [ ] 3 route terdaftar di `routes/api.php` dalam grup `auth:sanctum`,
      pakai envelope `{success,message,data}`.
- [ ] `GET active` hanya kembalikan `category IN (mobility,waste)` dan
      `is_active=true`, via `MissionResource`.
- [ ] `verify-waste` menolak MIME selain jpeg/png, menolak hash duplikat
      (409), menyimpan file di disk `public/proofs`, memanggil Gemini
      server-side (tidak pernah di Flutter), menulis `UserMission` +
      `PointTransaction credit` saat lolos threshold.
- [ ] `mobility-sync` memetakan kontrak ke skema DB (lihat §4),
      menolak kecepatan tak masuk akal, menulis `UserMission` +
      `MobilityLog` + `PointTransaction credit`, update
      `warga_profiles.total_distance_km/total_carbon_saved_kg/xp/level/streak`.
- [ ] `composer test` hijau, `vendor/bin/pint` bersih,
      koleksi Postman terupdate dan bisa jalan berurutan.

## 2. Keputusan default (ubah jika tidak setuju)

| # | Topik | Default |
|---|-------|---------|
| D1 | Kunci Gemini | Belum ada key → implementasi dengan `GEMINI_MOCK=true` agar bisa dev/test tanpa API asli. Key asli hanya via env `GEMINI_API_KEY`, tidak di-commit. |
| D2 | Mapping mobility | Terima field kontrak, map ke DB: `activity_type→transport_mode`, `duration_seconds→duration_minutes=ceil(/60)`, `gps_coordinates_path→start_point/end_point/route_coordinates`. DB tidak diubah. |
| D3 | Batas harian waste | Unlimited selama hash foto beda (tidak seperti quiz 409/hari). Duplikat hash tetap 409. |
| D4 | EXIF | Longgar: jika EXIF GPS kosong tetap lanjut ke Gemini (Flutter compress sering strip EXIF). Flag hanya jika ada bukti spoofing kuat. |
| D5 | Threshold AI | `GEMINI_MIN_CONFIDENCE=85` (sesuai `BACKEND_IMPLEMENTATION_STEPS.md` Fase 3). |
| D6 | Konstanta CO2 | `210 gram/km` (mobil bensin). Dokumentasikan di kode sebagai konstanta bernama. |

## 3. Prasyarat

```bash
cd backend
composer install
cp .env.example .env
# set DB_DATABASE=karbonkita (MySQL 3306) untuk dev;
# tests otomatis pakai SQLite memory via phpunit.xml, tidak perlu MySQL untuk test.
php artisan key:generate
php artisan migrate --force
php artisan storage:link
php artisan db:seed --class=MissionSeeder
```

Cek Guzzle (dibutuhkan `GeminiService`):

```bash
composer show guzzlehttp/guzzle
# jika tidak ada:
composer require guzzlehttp/guzzle
```

## 4. Spesifikasi endpoint (kontrak → implementasi)

### 4.1 `GET /api/missions/active`

- Auth: `auth:sanctum`.
- Query: `Mission::where('is_active', true)->whereIn('category', ['mobility','waste'])->orderBy('id')->get()`.
- Resource: `App\Http\Resources\MissionResource` (sudah ada, pakai ulang).
- Response: `200 {success:true, message, data: [...]}`.
- Test: 401 tanpa token; hanya mobility/waste; tidak ada quiz; tidak ada inactive.

### 4.2 `POST /api/missions/verify-waste`

- Auth + `throttle:10,1` (anti spam upload, sama seperti `saga/answer`).
- Content: `multipart/form-data` dengan `mission_id: integer|exists:missions,id` + validasi tambahan `category=waste, is_active=true`; `image: required|file|mimes:jpeg,png,jpg|max:5120`.
- Alur di `MissionController@verifyWaste`:
  1. Validasi MIME/size via `VerifyWasteRequest`.
  2. `sha256(file_get_contents)` → cek `user_missions.proof_image_hash` → jika ada: buat/tandai `anti_fraud_flagged=true, status=rejected` lalu `409 {success:false, message: duplicate}`.
  3. EXIF best-effort (`@exif_read_data` dalam try/catch). Jangan hard-fail jika kosong (D4).
  4. Simpan: `Storage::disk('public')->putFile("proofs/{userId}", $image)` → `proof_image_url`.
  5. Panggil `GeminiService::verifyWaste($path, $mime)` → `{is_valid, confidence, category, raw}`.
  6. `DB::transaction + WargaProfile::lockForUpdate()`:
     - Buat `UserMission {user_id, mission_id, proof_image_url/hash, ai_gemini_response: raw, confidence_score, status: verified|rejected|pending, rejection_reason?}`.
     - Jika `confidence >= env(GEMINI_MIN_CONFIDENCE, 85)`: `xp += mission.xp_reward`, `eco_points += mission.points_reward`, `total_waste_kg += estimasi (default 1.0 atau dari AI)`, `streak = StreakService::nextStreak(...)`, `level = LevelService::resolveLevel(newXp)`, `last_mission_at=now()`, tulis `PointTransaction {type: credit, amount: points_reward, balance_after, reference_type: UserMission::class, reference_id}`.
     - Jika di bawah threshold: `status=rejected`, tidak ubah poin.
     - Jika Gemini timeout/error: `status=pending`, `rejection_reason=AI timeout`, return `503` atau `200 pending` (pilih satu, konsisten).
- Jangan pernah terima hasil validasi dari client (guardrail `PROJECT_CONTEXT.md:66`).

### 4.3 `POST /api/missions/mobility-sync`

- Auth: `auth:sanctum`.
- Body JSON (terima kontrak, map ke DB):
  `mission_id?: integer|exists:missions,id (opsional, default misi mobility aktif pertama)`,
  `activity_type: required|in:cycling,walking`,
  `distance_km: required|numeric|min:0.1|max:500`,
  `duration_seconds: required|integer|min:60`,
  `gps_coordinates_path: required|array|min:2`, tiap titik `{lat: numeric, lng: numeric}`.
- Mapping: `transport_mode = activity_type` (`cycling→cycling`, `walking→walking`); `duration_minutes = (int) ceil(duration_seconds/60)`; `start_point = first`, `end_point = last`, `route_coordinates = full array`.
- Validasi anti-cheat: `avg muitos = distance / (duration_seconds/3600)`; jika `> 30 km/h` → `422/409 rejected` (tidak masuk akal untuk jalan/sepeda).
- Hitung: `co2_saved_grams = distance_km * 210`.
- `DB::transaction + lockForUpdate`: buat `UserMission verified (confidence 100, ai_gemini_response: {source: mobility-sync, ...})` + `MobilityLog {...}`; tambah XP/poin (pakai `mission.xp_reward/points_reward` atau fallback `distance*rate` — dokumentasikan pilihan di kode); update `total_distance_km`, `total_carbon_saved_kg`, streak/level; tulis `PointTransaction credit`.
- Response: `201 {user_mission_id, mobility_log_id, xp_earned, points_earned, co2_saved_grams, ...}`.

## 5. Daftar file

Baru (wajib):

```text
backend/app/Http/Controllers/MissionController.php
backend/app/Services/GeminiService.php
backend/app/Services/FakeGeminiService.php   (atau mock dalam GeminiService via GEMINI_MOCK)
backend/app/Http/Requests/VerifyWasteRequest.php
backend/app/Http/Requests/MobilitySyncRequest.php
backend/tests/Feature/MissionActiveTest.php
backend/tests/Feature/VerifyWasteTest.php
backend/tests/Feature/MobilitySyncTest.php
```

Edit:

```text
backend/routes/api.php                        (3 route baru)
backend/.env.example                           (GEMINI_* vars)
KarbonKita_API.postman_collection.json         (folder Missions)
```

Jangan sentuh kecuali perlu:

```text
database/migrations/*  (opsional: index proof_image_hash jika query lambat)
app/Http/Controllers/SagaController.php
app/Http/Controllers/VoucherController.php
```

## 6. Langkah implementasi berurutan

### Langkah 0 — Env & storage

1. Tambah ke `backend/.env.example`:
   `GEMINI_API_KEY=`, `GEMINI_MODEL=gemini-1.5-flash`,
   `GEMINI_MIN_CONFIDENCE=85`, `GEMINI_MOCK=true`, `WASTE_MAX_IMAGE_KB=5120`.
2. `php artisan storage:link`. Pastikan `config/filesystems.php` disk `public` aktif.

### Langkah 1 — `GET missions/active` (mulai di sini, tanpa dependensi eksternal)

1. Buat `MissionController@index` (query §4.1, return `MissionResource::collection` dalam envelope).
2. Daftarkan route:
   `Route::get('/missions/active', [MissionController::class, 'index'])->name('missions.active');`
3. Buat `MissionActiveTest`: 401, filter kategori, exclude inactive.
4. Verifikasi: `php artisan test --filter=MissionActiveTest`, `vendor/bin/pint`.

### Langkah 2 — `GeminiService` + mock

1. Buat `GeminiService::verifyWaste(string $path, string $mime): array`.
   Prompt: minta JSON `{is_valid: bool, confidence: 0-100, waste_category, reason}`.
   Timeout 20s, throw saat gagal agar controller bisa tandai `pending`.
2. Buat mode mock: jika `env('GEMINI_MOCK')` true → return `{is_valid:true, confidence:92, ...}` tanpa HTTP.
3. Unit test service dengan mock HTTP (`Http::fake`) + mode mock.

### Langkah 3 — `POST verify-waste`

1. Buat `VerifyWasteRequest` (aturan §4.2).
2. Implementasi `MissionController@verifyWaste` sesuai alur 6 langkah §4.2.
   Gunakan `Storage::fake('public')` di test.
3. Route dengan throttle:
   `Route::post('/missions/verify-waste', [MissionController::class, 'verifyWaste'])->middleware('throttle:10,1')->name('missions.verify-waste');`
4. `VerifyWasteTest`: success (mock), duplicate hash 409, low confidence rejected, MIME invalid 422, unauth 401.
5. Verifikasi manual: upload via Postman `multipart/form-data`.

### Langkah 4 — `POST mobility-sync`

1. Buat `MobilitySyncRequest` (aturan §4.3).
2. Implementasi `MissionController@mobilitySync` (validasi kecepatan, hitung CO2, transaction).
3. Route: `Route::post('/missions/mobility-sync', [MissionController::class, 'mobilitySync'])->name('missions.mobility-sync');`
4. `MobilitySyncTest`: success + cek `MobilityLog`/`PointTransaction`/stats; speed-reject; validasi 422; 401.
5. Verifikasi: `php artisan test`, `vendor/bin/pint`.

### Langkah 5 — Postman & docs

1. Tambah folder `Missions` di `KarbonKita_API.postman_collection.json`:
   active success/401, verify-waste success/duplicate/low-confidence/validation,
   mobility-sync success/speed-reject. Simpan `auth_token` seperti folder lain.
2. Update bagian yang menyebut endpoint belum ada (jika ada di komentar koleksi).

### Langkah 6 — Gate kualitas (wajib sebelum push)

```bash
cd backend
composer test
vendor/bin/pint --test
```

Tidak ada CI — gate lokal ini satu-satunya penangkap regresi (`AGENTS.md`).

## 7. Risiko & mitigasi

- Tanpa `GEMINI_API_KEY` → mitigasi mock (D1). Jangan mock di production (`GEMINI_MOCK=false` + key wajib).
- EXIF hilang setelah kompresi Flutter → mode longgar (D4), jangan tolak diam-diam.
- File besar / storage penuh → batasi 5MB, disk `public`, dokumentasikan retensi.
- Race condition klaim poin ganda → selalu `lockForUpdate(WargaProfile)` dalam transaction (contoh: `VoucherController.php:61`, `SagaController.php:127`).
- Kontrak vs DB beda nama field mobility → pertahankan mapping §4.3, jangan ubah kontrak tanpa update Postman + frontend.

## 8. Setelah roadmap ini (tidak dikerjakan sekarang)

- Fase 4: `merchant/dashboard`, `vouchers/redeem` + `XenditService` + role `mitra/admin`.
- Admin: pending list + verify (`MitraProfile.is_active`).
- Frontend: `dio` client + `secure_storage` + `auth/dashboard/saga/voucher blocs`.
- Opsional DB: composite index `(rt, rw, eco_points DESC)` jika leaderboard lambat; unique index `proof_image_hash`.

## 9. Perintah cepat

```bash
# dev backend (dari backend/)
composer dev
# atau satuan:
php artisan serve
php artisan queue:listen --tries=1
npm run dev

# test spesifik
php artisan test --filter=MissionActiveTest
php artisan test --filter=VerifyWasteTest
php artisan test --filter=MobilitySyncTest
# semua + format
composer test
vendor/bin/pint
```
