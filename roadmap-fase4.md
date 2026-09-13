# Roadmap Fase 4 — Voucher Redeem + Xendit + Merchant & Admin

> Status: **SELESAI 2026-09-05** — Task 0–6 dieksekusi dan hijau.
> Full suite akhir: **98 passed, 409 assertions** (naik dari 67 setelah Fase 3).
> Laporan per task di `backend/test-reports/TASK-*.md`. Satu deviasi tercatat:
> role admin memakai `admin` (enum DB) dengan alias dua arah ke `super_admin`
> (dokumen/ERD) di `EnsureRole` — lihat laporan Task 0.
> Scope: 4 endpoint kontrak yang tersisa: `GET merchant/dashboard`,
> `POST vouchers/redeem`, `GET admin/merchants/pending`,
> `POST admin/merchants/{id}/verify`.
> Acuan otoritatif: `PROJECT_CONTEXT.md`, `API_Contract_KarbonKita.md v1.2.0`,
> `Database_Schema_KarbonKita.md`, `BACKEND_IMPLEMENTATION_STEPS.md`,
> `KarbonKita_API.postman_collection.json`, `roadmap.md` (Fase 3 selesai).

## 0. Hasil audit (kenapa plan ini seperti ini)

Backend Laravel 12 + Sanctum. 13/17 endpoint kontrak sudah jadi (10 kontrak +
`POST auth/logout`, `GET user`, + 3 Fase 3: `missions/active`,
`verify-waste`, `mobility-sync`). Yang belum: 4 endpoint Fase 4 di atas.

| # | Temuan | Dampak ke Fase 4 |
|---|--------|------------------|
| A1 | Tidak ada role-check. Semua route hanya `auth:sanctum` (`routes/api.php:18`). `bootstrap/app.php:15-17` hanya alias `auth.society` (passthrough). | Wajib buat middleware role baru, kalau tidak warga bisa redeem & akses admin. |
| A2 | Tidak ada `XenditService`, tidak ada `config/services.php:xendit`, tidak ada env `XENDIT_*`. `composer.json` tidak ada SDK Xendit (bagus — pakai `Http` facade + Guzzle bawaan seperti `GeminiService`). | Buat service + config + env mengikuti pola `GeminiService` (mock via env). |
| A3 | Tidak ada `MerchantController` / `AdminController`. `VoucherController` hanya `index/claim/myVouchers`. | Controller baru, jangan menumpuk semua di `VoucherController`. |
| A4 | Penamaan kontrak vs DB beda: kontrak `unique_code` (`API_Contract:118`), DB `voucher_claims.qr_token` (migrasi `2024_01_02_000008`). Status kontrak `unused|used|expired`, DB `claimed|used|expired`. | Mapping wajib didokumentasikan, jangan ubah kontrak diam-diam: terima `unique_code`, query kolom `qr_token`; `claimed` = `unused`. |
| A5 | `MitraProfile` DB (`nama_usaha`, `status_verifikasi pending|verified|rejected`, `is_active`, `balance`) vs ERD/kontrak (`store_name`, `is_open`, `balance_saldo`). Tidak ada kolom catatan reject. | Mapping + 1 migrasi kecil `verification_note`. Jangan rename kolom besar. |
| A6 | `RegisterRequest` hanya `in:warga,mitra` — tidak ada jalur register `super_admin` (benar secara security). `UserSeeder` tidak punya admin. | Admin dibuat via seeder khusus, bukan via API publik. |
| A7 | `VoucherSeeder` sudah punya 1 mitra verified (`kopilokal@example.com`) + 5 voucher. `AuthController@register` mitra selalu `pending + is_active=false`. | Alur uji admin-verify sudah bisa pakai user register baru. |
| A8 | `disbursements` table sudah lengkap (`xendit_disbursement_id unique`, `amount`, bank fields, `status pending|completed|failed`, `response_log`, `failure_reason`). | Tidak perlu migrasi finansial, kecuali index tambahan jika lambat. |
| A9 | Pola yang wajib ditiru sudah ada: `VoucherController@claim:41-104` (`DB::transaction + lockForUpdate` + `PointTransaction`) dan `SagaController@answer:126` (transaction + `StreakService` + envelope). | Redeem meniru pola ini persis. |

## 1. Target & acceptance

1. `GET /api/merchant/dashboard` — saldo rupiah, status Buka/Tutup, riwayat pencairan.
2. `POST /api/vouchers/redeem` — verifikasi QR → payout Xendit → update saldo. Rollback total jika Xendit gagal.
3. `GET /api/admin/merchants/pending` — antrean verifikasi + link dokumen.
4. `POST /api/admin/merchants/{id}/verify` — approve / reject.

Kriteria selesai:

- [ ] 4 route terdaftar di `routes/api.php` dalam grup `auth:sanctum` + middleware `role`, pakai envelope `{success,message,data}`.
- [ ] `redeem` pakai `DB::transaction() + lockForUpdate()` pada `voucher_claims + vouchers + mitra_profiles`; double-scan bersamaan tidak bisa double-spend; Xendit gagal → rollback, claim tetap `claimed`.
- [ ] `XenditService` server-side saja (tidak pernah di Flutter), ada mode mock `XENDIT_MOCK=true` untuk dev/test, key asli hanya via env.
- [ ] Non-mitra ditolak `403` di endpoint merchant; non-admin ditolak `403` di endpoint admin; tanpa token `401`.
- [ ] Mitra hanya bisa redeem voucher milik tokonya sendiri (`403` jika milik toko lain); mitra `pending/rejected/nonaktif` tidak bisa redeem (`403`).
- [ ] `composer test` hijau, `vendor/bin/pint` bersih, koleksi Postman folder Merchant+Admin bisa jalan berurutan.

## 2. Keputusan default (ubah jika tidak setuju)

| # | Topik | Default |
|---|-------|---------|
| D1 | Kunci Xendit | Belum ada key → `XENDIT_MOCK=true` agar dev/test tanpa API asli. Key asli hanya via env `XENDIT_API_KEY` (Basic Auth, username=key, password kosong). Tidak di-commit. |
| D2 | Mapping input redeem | Terima field kontrak `unique_code`, query kolom DB `qr_token`. Status `claimed` diperlakukan sebagai `unused`. DB tidak diubah. |
| D3 | Mapping dashboard | `is_active` DB ↔ `is_open` kontrak; `balance` DB ↔ `balance_saldo`/`saldo` kontrak; `nama_usaha` ↔ `store_name`. DB tidak diubah. |
| D4 | Kepemilikan redeem | Ketat: mitra hanya bisa redeem voucher yang `vouchers.mitra_profile_id` = miliknya. Alasan: mencegah kasir toko A mencairkan voucher toko B. |
| D5 | Syarat redeem | Mitra harus `status_verifikasi=verified` DAN `is_active=true`. Jika tidak → `403` dengan pesan jelas. |
| D6 | Throttle redeem | `throttle:30,1` (lebih longgar dari `verify-waste 10,1` karena kasir butuh loop cepat `Selesai & Scan Lagi`, tapi tetap anti brute-force token). |
| D7 | Bank code Xendit | DB simpan nama bebas (`Bank BCA`); service punya `mapBankCode()` ke kode Xendit (`BCA/BNI/BRI/MANDIRI/...`), fallback kirim apa adanya + log. Dokumentasikan di kode. |
| D8 | External ID Xendit | `KBK-{claimId}-{YmdHis}-{random4}` agar unik + traceable. Kolom `xendit_disbursement_id` unique menjamin idempotency. |
| D9 | Toggle Buka/Tutup | Kontrak hanya menampilkan status, tidak ada endpoint toggle. Default: sertakan `PATCH /api/merchant/status` (`{is_open: bool}` → `is_active`) sebagai ekstra kecil di Task 2. Tolak jika tidak mau endpoint ekstra. |
| D10 | Webhook Xendit | Di luar scope. Fase 4 pakai respons sinkron `completed` (mock) / `pending→completed` asumsi sukses. Callback async dicatat sebagai follow-up. |

## 3. Prasyarat

```bash
cd backend
composer install
# MySQL dev: pastikan backend/.env DB_DATABASE=karbonkita (port 3306)
php artisan migrate --force
php artisan db:seed   # UserSeeder + VoucherSeeder (mitra kopilokal verified)
# tests otomatis SQLite memory via phpunit.xml — tidak perlu MySQL untuk test
```

Cek HTTP client (dipakai `XenditService`, sama seperti `GeminiService`):

```bash
composer show guzzlehttp/guzzle
# Laravel 12 sudah membawa guzzle via Http facade; jika tidak ada:
composer require guzzlehttp/guzzle
```

## 4. Spesifikasi endpoint (kontrak → implementasi)

### 4.1 `GET /api/merchant/dashboard`

- Auth: `auth:sanctum` + `role:mitra`.
- Controller: `MerchantController@dashboard` (baru).
- Query: `auth()->user()->load('mitraProfile')`; eager `vouchers`, `disbursements` latest 10.
- Jika tidak punya `mitraProfile` → `403 {success:false, message: Merchant profile not found}`.
- Jika `status_verifikasi != verified` → tetap `200` tapi sertakan `verification_status` + `can_redeem: false` (kasir tahu kenapa belum bisa). Jangan 404.
- Response `200`:

```json
{
  "success": true,
  "message": "Merchant dashboard retrieved successfully.",
  "data": {
    "store_name": "Kopi Lokal Surabaya",
    "verification_status": "verified",
    "is_open": true,
    "can_redeem": true,
    "balance": "150000.00",
    "stats": {
      "total_vouchers": 5,
      "active_vouchers": 4,
      "total_redeemed": 12,
      "total_disbursed": "240000.00"
    },
    "recent_disbursements": [
      {"id": 1, "voucher_claim_id": 9, "amount": "20000.00", "status": "completed", "xendit_disbursement_id": "xnd_...", "processed_at": "2026-09-05T10:00:00"}
    ]
  }
}
```

- Test: 401 tanpa token; 403 role warga; 200 mitra verified (`can_redeem true`); 200 mitra pending (`can_redeem false`).

### 4.2 `POST /api/vouchers/redeem`

- Auth: `auth:sanctum` + `role:mitra` + `throttle:30,1` (D6).
- URL tetap `/api/vouchers/redeem` (kontrak), handler `MerchantController@redeem` (bukan `VoucherController`, agar otorisasi peran jelas).
- Body: `{ "unique_code": "KBK-XXX-YYY" }` — validasi `required|string|exists:voucher_claims,qr_token` via `RedeemVoucherRequest`. Pesan error mapping jelas.
- Alur di dalam `DB::transaction()` (semua `lockForUpdate`):

  1. `MitraProfile::where('user_id', auth()->id())->lockForUpdate()->first()` → jika null → exception 403; jika `status_verifikasi != verified || !is_active` → 403 `Merchant not verified or inactive`.
  2. `VoucherClaim::where('qr_token', unique_code)->lockForUpdate()->first()` + `->load('voucher')` → jika null → 404 (ditangani validator `exists`, tapi cek ulang untuk pesan konsisten).
  3. Jika `claim.status == 'used'` → `409 Already redeemed` (+ `used_at`). Jika `expired` atau voucher `expired_at` past / `is_active false` → `422 Voucher expired or inactive`.
  4. Kepemilikan (D4): jika `voucher.mitra_profile_id != mitra.id` → `403 This voucher belongs to another merchant`.
  5. Bangun payload Xendit: `external_id` (D8), `amount = voucher.rupiah_value`, `bank_code = mapBankCode(mitra.nama_bank)`, `account_number = mitra.nomor_rekening`, `account_name = mitra.nama_pemilik_rekening`, `description = Redeem {qr_token}`.
  6. Panggil `XenditService::createDisbursement($payload)` → `{xendit_id, status, raw}`. Throw saat gagal agar rollback.
  7. Sukses: `claim->update({status: used, used_at: now()})`; `Disbursement::create({mitra_profile_id, voucher_claim_id, xendit_disbursement_id, amount, bank_*, status: completed, response_log: raw})`; `mitra->increment('balance', amount)`.
  8. Return `200 {claim_id, qr_token, amount, new_balance, xendit_disbursement_id, disbursement_status}`.
- Xendit gagal/timeout: biarkan exception → rollback total → catch di controller → `502 {success:false, message: Disbursement failed, please retry}`. Claim tetap `claimed`, tidak ada baris `disbursements` setengah jadi (jaminan `PROJECT_CONTEXT.md:68`). Opsional audit-failure di transaksi terpisah — catat sebagai follow-up, jangan di Fase 4 agar rollback murni.
- Jangan pernah terima `amount` dari client (anti manipulasi nominal).
- Test: success mock (+ cek claim used, disbursement completed, balance += rupiah_value); redeem ulang 409; voucher toko lain 403; expired 422; warga 403; unauth 401; Xendit 500 → 502 + claim tetap claimed (pakai `Http::fake` + `XENDIT_MOCK=false`).

### 4.3 `GET /api/admin/merchants/pending`

- Auth: `auth:sanctum` + `role:super_admin`.
- Controller: `AdminController@pending` (baru).
- Query: `MitraProfile::with('user')->where('status_verifikasi','pending')->orderBy('created_at')->paginate(15)`.
- Sertakan dokumen: `foto_ktp, foto_nib, foto_toko` (nullable saat ini — tampilkan apa adanya + `Storage::url()` jika path lokal). Jangan hard-fail jika null (data register lama tidak punya file).
- Response `200 {success, message, data: {current_page, data: [...], ...}}` (paginator Laravel standar di dalam envelope).
- Test: 401; 403 warga; 403 mitra; 200 admin hanya berisi pending (buat 1 pending + 1 verified di test, pastikan verified tidak muncul).

### 4.4 `POST /api/admin/merchants/{id}/verify`

- Auth: `auth:sanctum` + `role:super_admin`.
- Body via `VerifyMitraRequest`: `{ "action": "approve"|"reject", "reason": "string nullable, required jika reject, max:500" }`.
- Alur: `MitraProfile::lockForUpdate()->findOrFail($id)` → jika `status_verifikasi != pending` → `409 Already reviewed`. Approve: `status_verifikasi=verified, is_active=true, verification_note=reason`. Reject: `status_verifikasi=rejected, is_active=false, verification_note=reason` (butuh migrasi Task 1).
- Response `200 {id, store_name, verification_status, is_active}`.
- Test: approve flips; reject flips + note; re-verify 409; invalid action 422; reject tanpa reason 422; 403 non-admin.

## 5. Daftar file

Baru (wajib):

```text
backend/app/Http/Middleware/EnsureRole.php
backend/app/Http/Controllers/MerchantController.php
backend/app/Http/Controllers/AdminController.php
backend/app/Services/XenditService.php
backend/app/Http/Requests/RedeemVoucherRequest.php
backend/app/Http/Requests/VerifyMitraRequest.php
backend/app/Http/Requests/MerchantStatusRequest.php   (hanya jika D9 disetujui)
backend/database/seeders/AdminSeeder.php
backend/database/migrations/2026_09_06_000001_add_verification_note_to_mitra_profiles_table.php
backend/tests/Feature/MerchantDashboardTest.php
backend/tests/Feature/VoucherRedeemTest.php
backend/tests/Feature/AdminMitraTest.php
backend/tests/Unit/XenditServiceTest.php
```

Edit:

```text
backend/bootstrap/app.php                 (alias 'role' => EnsureRole::class)
backend/routes/api.php                    (4 route + 1 opsional toggle)
backend/config/services.php               (array 'xendit')
backend/.env.example                      (XENDIT_* vars)
backend/database/seeders/DatabaseSeeder.php (daftarkan AdminSeeder)
KarbonKita_API.postman_collection.json    (folder Merchant + Admin)
```

Jangan sentuh kecuali perlu:

```text
app/Http/Controllers/VoucherController.php (hanya referensi pola claim)
app/Http/Controllers/SagaController.php
app/Http/Controllers/MissionController.php
database/migrations/2024_* (kecuali migrasi note baru di atas)
```

## 6. Task breakdown (kerjakan berurutan)

### Task 0 — Fondasi: role middleware + env + admin seeder

Tujuan: semua endpoint Fase 4 punya pagar peran sebelum logika bisnis ditulis.

1. Buat `app/Http/Middleware/EnsureRole.php`:

```php
handle(Request $request, Closure $next, string ...$roles): Response
// $request->user() null → 401 envelope
// user->role tidak in $roles → 403 envelope {success:false, message: Forbidden...}
// contoh pemakaian: ->middleware('role:mitra'), ->middleware('role:super_admin')
```

2. Daftarkan di `bootstrap/app.php`: `$middleware->alias(['role' => EnsureRole::class])`. Jangan hapus alias `auth.society` yang ada.
3. Tambah ke `backend/.env.example`:

```text
XENDIT_API_KEY=
XENDIT_BASE_URL=https://api.xendit.co
XENDIT_MOCK=true
XENDIT_TIMEOUT=20
XENDIT_CALLBACK_TOKEN=
```

4. Tambah ke `config/services.php`:

```php
'xendit' => [
    'key' => env('XENDIT_API_KEY'),
    'base_url' => env('XENDIT_BASE_URL', 'https://api.xendit.co'),
    'mock' => env('XENDIT_MOCK', false),
    'timeout' => env('XENDIT_TIMEOUT', 20),
],
```

5. Buat `database/seeders/AdminSeeder.php`: 1 user `super_admin` (`admin@karbonkita.id`, `+628000000001`, `SecurePassword123!`, `is_active true`, kota Surabaya default). Daftarkan di `DatabaseSeeder`. Jangan tambahkan `super_admin` ke `RegisterRequest` (tetap `warga,mitra`).
6. Verifikasi: `php artisan test --filter=ExampleTest`, `vendor/bin/pint --test`. Route belum ditambah — tidak ada regresi.

Acceptance Task 0: alias `role` terdaftar; `XENDIT_*` terbaca via `config('services.xendit')`; `php artisan db:seed --class=AdminSeeder` membuat admin 1x (rerun aman via `firstOrCreate`).

### Task 1 — Migrasi note + `XenditService` + unit test

Tujuan: service payout siap + bisa di-mock, mengikuti pola `GeminiService`.

1. Migrasi: `php artisan make:migration add_verification_note_to_mitra_profiles_table` → `verification_note nullable text after status_verifikasi`. Tambahkan `'verification_note'` ke `$fillable` `MitraProfile`.
2. Buat `app/Services/XenditService.php` meniru struktur `GeminiService` (`fromConfig()`, `isMock()`, konstanta `TIMEOUT`):
   - `__construct(?string $apiKey, ?string $baseUrl, ?bool $mock, ?int $timeout)` baca dari `config('services.xendit')`.
   - `isMock(): bool` → `mock || apiKey === ''`.
   - `createDisbursement(array $payload): array` — wajib key `external_id, amount, bank_code, account_number, account_name`. Mock → return `{xendit_id: 'xnd_mock_'.Str::random(8), status: 'completed', raw: ['mock'=>true]}` tanpa HTTP. Real → `Http::withBasicAuth($key,'')->timeout($timeout)->post($baseUrl.'/v2/disbursements', [...])`, `failed()` → throw `RuntimeException`, return `{xendit_id, status, raw}`.
   - `mapBankCode(string $namaBank): string` — normalisasi (`strtoupper`, hapus `BANK `): `BCA→BCA, BNI→BNI, BRI→BRI, MANDIRI→MANDIRI, CIMB→CIMB, DANAMON→DANAMON, PERMATA→PERMATA, BTN→BTN`; tidak dikenal → return input + dokumentasikan.
   - Timeout 20 dtk, throw agar controller rollback (lihat §4.2).
3. Buat `tests/Unit/XenditServiceTest.php`: mock-mode tanpa key; `Http::fake` sukses real-mode; `Http::fake` 500 → throws; `mapBankCode('Bank BCA') === 'BCA'`.
4. Verifikasi: `php artisan test --filter=XenditServiceTest`, `vendor/bin/pint`.

Acceptance: 4 test hijau; tidak ada HTTP asli saat `XENDIT_MOCK=true`.

### Task 2 — `GET merchant/dashboard` (+ opsional toggle)

1. Buat `MerchantController@dashboard` sesuai §4.1. Gunakan `with()` eager loading. Bungkus envelope. `balance` format string decimal (`number_format($b, 2, '.', '')`) agar konsisten dengan cast `decimal:2`.
2. (Jika D9 disetujui) tambah `MerchantStatusRequest` (`is_open: required|boolean`) + `MerchantController@updateStatus` (`is_active = is_open`), route `PATCH /api/merchant/status` + `role:mitra`. Jika ditolak, lewati tanpa menghapus Task lain.
3. Route:

```php
Route::get('/merchant/dashboard', [MerchantController::class, 'dashboard'])->name('merchant.dashboard');
// opsional:
Route::patch('/merchant/status', [MerchantController::class, 'updateStatus'])->name('merchant.status');
```

4. Buat `tests/Feature/MerchantDashboardTest.php`: 401; 403 warga login; 200 mitra verified (`is_open`, `can_redeem true`, `balance`, `stats`, `recent_disbursements` array); 200 mitra pending (`can_redeem false`). Buat mitra via factory/`User::create + MitraProfile::create` di test, jangan bergantung seeder.
5. Verifikasi: `php artisan test --filter=MerchantDashboardTest`, `vendor/bin/pint`.

### Task 3 — `POST vouchers/redeem` (inti Fase 4)

1. Buat `RedeemVoucherRequest`: `unique_code: required|string|exists:voucher_claims,qr_token` + `failedValidation` envelope 422 (tirupola `ClaimVoucherRequest`). Tambahkan `throttle:30,1` di route (D6).
2. Implementasi `MerchantController@redeem` persis §4.2 langkah 1-8. Ingat: `lockForUpdate()` ketiga model, cek kepemilikan D4 + syarat D5, amount dari `voucher.rupiah_value` (jangan dari request), `DB::transaction()` closure me-return array sukses; catch `RuntimeException` Xendit → `502`.
3. Route: `Route::post('/vouchers/redeem', [MerchantController::class, 'redeem'])->middleware('throttle:30,1')->name('vouchers.redeem');` di dalam grup `auth:sanctum` + `role:mitra` (lihat contoh grouping Task 6).
4. Buat `tests/Feature/VoucherRedeemTest.php` (paling banyak kasus):
   - success: warga claim dulu (pakai alur `VoucherController@claim` atau buat `VoucherClaim` langsung + kurangi poin), lalu mitra pemilik redeem dengan `XENDIT_MOCK=true` → 200, `claim.status used`, `disbursements` 1 completed, `mitra.balance` += `rupiah_value`.
   - double redeem → 409.
   - voucher toko lain → 403 (buat mitra kedua + voucher kedua).
   - expired (`expired_at` kemarin) → 422.
   - mitra pending → 403.
   - warga coba redeem → 403 (pagar `role:mitra`).
   - tanpa token → 401.
   - Xendit gagal: `Config::set('services.xendit.mock', false)` + `Http::fake(... 500 ...)` → 502 + claim tetap `claimed` + tidak ada disbursement.
5. Verifikasi: `php artisan test --filter=VoucherRedeemTest`, `vendor/bin/pint`. Uji manual concurrency minimal: dua request cepat token sama → satu 200 satu 409 (dokumentasikan hasil di laporan).

### Task 4 — Admin `pending` + `verify`

1. Buat `VerifyMitraRequest`: `action: required|in:approve,reject`, `reason: nullable|string|max:500|required_if:action,reject`.
2. Buat `AdminController@pending` (§4.3, paginate 15, `with('user')`) + `AdminController@verify($id)` (§4.4, `lockForUpdate`, 409 jika bukan pending).
3. Route dengan `role:super_admin`:

```php
Route::get('/admin/merchants/pending', [AdminController::class, 'pending'])->name('admin.merchants.pending');
Route::post('/admin/merchants/{id}/verify', [AdminController::class, 'verify'])->name('admin.merchants.verify');
```

4. Buat `tests/Feature/AdminMitraTest.php`: 401 kedua endpoint; 403 warga & mitra; pending hanya pending; approve → verified+active; reject → rejected+inactive+note; verify ulang → 409; reject tanpa reason → 422.
5. Verifikasi: `php artisan test --filter=AdminMitraTest`, `vendor/bin/pint`.

### Task 5 — Postman + seed docs

1. Tambah folder `Merchant` di `KarbonKita_API.postman_collection.json`: dashboard success/401/403, redeem success/double-redeem-409/foreign-403/validation-422, (opsional status toggle). Simpan `qr_token` dari response claim ke variable (seperti `claim_id/qr_token` yang sudah ada) agar redeem bisa jalan berurutan setelah folder Voucher.
2. Tambah folder `Admin`: login sebagai admin (variable terpisah `admin_token` agar tidak menimpa `auth_token` warga/mitra), pending list, verify approve, verify reject, re-verify 409.
3. Pastikan urutan run: Auth → Voucher claim → Merchant redeem → Admin. Dokumentasikan di `description` koleksi seperti folder Saga.
4. Verifikasi manual: `php artisan serve`, jalankan berurutan, semua hijau.

### Task 6 — Gate kualitas (wajib sebelum push)

```bash
cd backend
composer test
vendor/bin/pint --test
```

Tidak ada CI — gate lokal ini satu-satunya penangkap regresi (`AGENTS.md`). Jika tambah file, pastikan `composer dump-autoload` tidak error.

## 7. Risiko & mitigasi

- Tanpa `XENDIT_API_KEY` → mitigasi mock D1. Jangan set `XENDIT_MOCK=false` di production tanpa key.
- Double-spend QR (kasir scan 2x / antrean) → `lockForUpdate` + status-check di dalam transaksi + `xendit_disbursement_id` unique. Test concurrency §Task 3.
- Nama bank bebas vs kode Xendit → `mapBankCode` + log `raw`; jika payout ditolak karena bank, error Xendit di-`report()` + return 502, bukan rollback diam-diam.
- Kontrak vs DB beda nama (`unique_code`/`qr_token`, `unused`/`claimed`, `is_open`/`is_active`) → pertahankan mapping D2-D3, jangan ubah kontrak tanpa update Postman + frontend.
- Webhook async Xendit belum ada → status langsung `completed` di mock; di real-mode jika Xendit return `pending`, simpan `pending` + catat follow-up polling/webhook (jangan blokir kasir terlalu lama, timeout 20 dtk).
- Saldo mitra vs mutasi poin warga: redeem tidak mengubah `eco_points` (sudah dipotong saat claim). Jangan tulis `PointTransaction` saat redeem — ledger poin ≠ ledger rupiah. `disbursements` adalah ledger rupiah.
- Foto KTP/NIB null di data lama → admin pending tetap tampil, jangan 500. Upload dokumen adalah follow-up di luar Fase 4.

## 8. Setelah Fase 4 (tidak dikerjakan sekarang)

- Webhook Xendit (`POST /api/webhooks/xendit`, verifikasi `XENDIT_CALLBACK_TOKEN`, update `pending→completed/failed` + sinkron `balance`).
- Upload dokumen mitra (KTP/NIB/foto toko) + validasi + `Storage::url()`.
- Katalog voucher oleh admin (`PROJECT_CONTEXT.md:61`) + `stock/expired` scheduler (`expired` otomatis via `schedule`).
- Toggle `is_open` jika D9 ditolak sekarang.
- Frontend: merchant dashboard + scanner QR + loop `Selesai & Scan Lagi`; admin panel verifikasi.
- Opsional DB: index `disbursements(voucher_claim_id)`, `voucher_claims(qr_token)` sudah ada — tambah jika lambat.

## 9. Perintah cepat

```bash
# dev backend (dari backend/)
composer dev
# atau satuan:
php artisan serve
php artisan queue:listen --tries=1
npm run dev

# test spesifik Fase 4
php artisan test --filter=XenditServiceTest
php artisan test --filter=MerchantDashboardTest
php artisan test --filter=VoucherRedeemTest
php artisan test --filter=AdminMitraTest
# semua + format
composer test
vendor/bin/pint
```
