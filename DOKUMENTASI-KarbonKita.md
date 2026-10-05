# Dokumentasi Lengkap Aplikasi KarbonKita

> **Tagline:** *Aksi kecil, dampak besar*
> **Versi dokumen:** 1.0 — 4 Oktober 2026
> **Status proyek:** Backend selesai (Fase 1–4 + Donasi + Webhook), Frontend tahap UI

---

## 1. Gambaran Umum

**KarbonKita** adalah platform aksi iklim perkotaan Indonesia yang menggabungkan **aplikasi mobile (Flutter)** dan **API backend (Laravel)** dengan pendekatan **gamifikasi + ekonomi sirkular**.

Masalah yang dijawab:
- Rendahnya pemilahan sampah rumah tangga di kota.
- Dominasi kendaraan bermotor untuk jarak pendek.
- Rendahnya literasi karbon dan kurangnya insentif ekonomi untuk perilaku hijau.
- UMKM kesulitan menjangkau pelanggan baru lewat promo murah.

Solusi KarbonKita — alur 5 langkah:

1. **Warga beraksi hijau:** foto sampah terpilah, jalan kaki/bersepeda (GPS), atau ikut kuis edukasi.
2. **Sistem memberi reward:** *Eco Points* + *XP* + *Streak harian* + *Level*.
3. **Poin ditukar voucher:** katalog voucher UMKM mitra (kuliner, sembako, fashion, jasa, transportasi, donasi).
4. **Voucher dicairkan UMKM:** kasir scan QR → payout **rupiah asli otomatis via Xendit** ke rekening toko.
5. **Jalur donasi:** donatur/CSR mendanai campaign lingkungan atau voucher sosial.

Tiga peran utama: **Warga**, **Mitra UMKM**, dan **Super Admin**.

---

## 2. Arsitektur Sistem

```
┌─────────────────────┐      HTTPS/JSON       ┌──────────────────────┐
│  Flutter App        │ ◄──────────────────► │  Laravel 12 API      │
│  (Warga & Mitra)    │   Bearer Sanctum      │  routes/api.php      │
│  - flutter_bloc     │                       │  - Auth / Misi /     │
│  - dio              │                       │    Saga / Voucher /  │
│  - secure_storage   │                       │    Merchant / Admin /│
│  - camera / GPS /   │                       │    Donasi / Webhook  │
│    QR scanner       │                       └──────┬───────┬───────┘
└─────────────────────┘                              │       │
                                              ┌──────▼───┐ ┌─▼────────┐
                                              │ Gemini   │ │ Xendit   │
                                              │ Vision   │ │ Payout   │
                                              │ (server- │ │ (server- │
                                              │  side)   │ │  side)   │
                                              └──────────┘ └──────────┘
                                                     ┌─────────────┐
                                                     │ MySQL prod  │
                                                     │ SQLite mem  │
                                                     │ (test)      │
                                                     └─────────────┘
```

Prinsip arsitektur:

- **Frontend bodoh, backend pintar:** validasi AI Gemini dan payout Xendit **hanya di backend Laravel**. Flutter hanya kirim foto mentah / token QR.
- **Semua response JSON** memakai envelope `{ success, message, data }`.
- **Transaksi finansial atomik:** `DB::transaction() + lockForUpdate()`. Gagal Xendit = rollback total.
- **Ledger ganda:** `point_transactions` (audit poin) dan `disbursements` (audit rupiah).

---

## 3. Peran Pengguna

| Peran | Cara daftar | Akses utama |
|---|---|---|
| **Warga** | `POST /api/auth/register` (nama, HP/email, password, Kota/Kecamatan/Kelurahan/RT/RW) | Dashboard, misi sampah, misi mobilitas, kuis Saga, leaderboard, marketplace, dompet voucher, donasi, profil karbon |
| **Mitra UMKM** | `POST /api/auth/register-mitra` (multipart: data usaha + KTP/NIB + foto toko + bank) → status `pending` → diverifikasi admin | Dashboard toko, toggle Buka/Tutup, riwayat disbursement, scanner/redeem QR |
| **Super Admin** | Dibuat via seeder (`AdminSeeder`), **tidak bisa** via API publik | Antrean verifikasi mitra, approve/reject, kelola campaign donasi & voucher pendanaan |

Login fleksibel pakai **No HP atau Email** (`POST /api/auth/login`), dibatasi `throttle:5,1` anti brute-force. Token Sanctum `1|...` bisa direvoke instan (penting untuk fitur finansial).

---

## 4. Fitur Warga (Citizen App)

### 4.1 Register & Login
- Lokasi mikro presisi (`city, district, sub_district, rt, rw`) — fondasi leaderboard RT/RW.
- Validasi + transaksi `User` + `WargaProfile` sekaligus.

### 4.2 Beranda / Dashboard (`GET /api/user/dashboard`)
- Eco Points aktif, Level (mis. *Earth Warrior*), XP progress bar, streak harian, ringkasan aktivitas hari ini.
- `GET /api/user/levels` untuk daftar tier level, `GET /api/user/activities` untuk aktivitas terbaru.

### 4.3 Misi Pilah Sampah (`GET /api/missions/active`, `POST /api/missions/verify-waste`)
- Daftar misi `mobility|waste` yang aktif → kamera scanner dengan overlay + label *"Sistem Anti-Fraud Aktif"*.
- Upload `multipart/form-data` (`mission_id` + `image` jpeg/png ≤ 5 MB).
- Backend: cek MIME → cek hash SHA256 duplikat (409 jika foto dipakai ulang) → cek EXIF best-effort → simpan di `public/proofs` → panggil `GeminiService` server-side.
- Lolos jika `confidence ≥ 85` (`GEMINI_MIN_CONFIDENCE`): `UserMission verified` + tambah XP/poin + update `total_waste_kg` + streak/level + `PointTransaction credit`. Di bawah threshold = `rejected`. Error AI = `pending` (503).
- Mode `GEMINI_MOCK=true` untuk dev/test tanpa API key.

### 4.4 Misi Mobilitas Hijau (`POST /api/missions/mobility-sync`)
- Tracker GPS real-time (jalan/sepeda): rute, `distance_km`, `duration_seconds`, `gps_coordinates_path [{lat,lng}]`.
- Backend mapping ke DB: `activity_type→transport_mode`, `duration_seconds→duration_minutes (ceil)`, path→`start_point/end_point/route_coordinates`.
- Anti-cheat: kecepatan rata-rata > 30 km/jam ditolak (tidak masuk akal untuk jalan/sepeda).
- Hitung `co2_saved_grams = distance_km × 210 gram/km` (konstanta mobil bensin).
- Tulis `UserMission + MobilityLog + PointTransaction`, update `total_distance_km`, `total_carbon_saved_kg`, XP/level/streak.

### 4.5 Saga Map / Kuis Harian (`GET /api/saga/nodes`, `/nodes/{id}/questions`, `/quizzes`, `POST /api/saga/answer`)
- Peta stage edukasi lingkungan (nodes → questions → jawab A/B/C/D).
- Kuis harian menjaga streak tanpa aktivitas fisik. Jawaban benar → XP + streak. Throttle `10,1` anti spam.

### 4.6 Leaderboard RT/RW (`GET /api/leaderboard?scope=rt&timeframe=weekly`)
- Peringkat individu maupun agregat RT/RW (harian/mingguan). Tanpa dashboard admin terpisah — kompetisi antar tetangga.
- Dioptimasi index `(rt, rw, eco_points DESC)` + composite index leaderboard + eager loading `with()`.

### 4.7 Statistik Karbon & Kalkulator Emisi (`GET /api/user/carbon-stats`)
- Total CO2 saved, total KM, total KG sampah. Layar profil + kalkulator (input kendaraan/aktivitas → estimasi emisi + gauge + rekomendasi).

### 4.8 Marketplace Voucher (`GET /api/vouchers?category=...`, `POST /api/vouchers/claim`)
- Kategori: `kuliner|sembako|fashion|jasa|donasi|transportasi`. Tanpa param = semua.
- Klaim: cek poin → potong poin dalam transaksi + `lockForUpdate` → generate QR unik `KBK-XXX-YYY` (`qr_token`) status `claimed`. Double-spend dicegah kunci baris.

### 4.9 Dompet Voucher Saya (`GET /api/user/my-vouchers`)
- Daftar voucher diklaim + QR + status `claimed/used/expired`. Ditunjukkan ke kasir saat belanja.

### 4.10 Donasi
- Katalog publik tanpa login: `GET /api/donation-campaigns`, `GET /api/donation-campaigns/{slug}`.
- Setelah login: `POST /api/donations`, `GET /api/user/my-donations`, `POST /api/donations/{id}/cancel`.
- Mendanai campaign lingkungan / voucher sosial (CSR/komunitas).

---

## 5. Fitur Mitra UMKM (Merchant App)

### 5.1 Register & Dashboard (`GET /api/merchant/dashboard`, `GET /api/merchant/disbursements`, `PATCH /api/merchant/status`)
- Daftar khusus mitra, menunggu verifikasi admin (`pending`, `is_active=false`).
- Setelah `verified`: dashboard berisi `store_name`, `verification_status`, `is_open` (map dari `is_active`), `can_redeem`, `balance` (string desimal), `stats` (total/active/redeemed/disbursed), `recent_disbursements` 10 terakhir.
- Mitra `pending` tetap dapat 200 tapi `can_redeem:false` agar kasir tahu alasan.
- Toggle `Buka/Tutup` via `PATCH /api/merchant/status {is_open: bool}`.

### 5.2 Scanner / Redeem Voucher (`POST /api/vouchers/redeem`)
- Scanner QR + input manual `unique_code` (dikirim sebagai `qr_token` di DB). Throttle `30,1` agar loop kasir *"Selesai & Scan Lagi"* tetap cepat tapi anti brute-force.
- Syarat ketat dalam `DB::transaction + lockForUpdate (mitra + claim + voucher)`:
  1. Mitra harus `verified` dan `is_active`.
  2. Claim harus `claimed` (`claimed` = `unused` kontrak). `used` → 409, expired → 422.
  3. Voucher harus milik toko sendiri (`403` jika milik toko lain).
  4. Nominal dari `voucher.rupiah_value` — **tidak pernah** dari client.
  5. Panggil `XenditService::createDisbursement` (`external_id = KBK-{claimId}-{YmdHis}-{random4}`, `bank_code` via `mapBankCode`, nomor/nama rekening).
  6. Sukses: claim→`used`, tulis `Disbursement completed + response_log`, `mitra.balance += amount`.
  7. Gagal/timeout Xendit: exception → rollback total → `502`, claim tetap `claimed`, tanpa baris setengah jadi.
- Redeem tidak menulis `PointTransaction` (poin sudah dipotong saat claim; `disbursements` adalah ledger rupiah).

---

## 6. Fitur Super Admin

### 6.1 Verifikasi Mitra (`GET /api/admin/merchants/pending`, `GET /api/admin/merchants`, `GET /api/admin/merchants/{id}`, `POST /api/admin/merchants/{id}/verify`)
- Antrean `pending` paginasi 15 + `with('user')`, tampilkan `foto_ktp/nib/toko` via `Storage::url()` (tahan null untuk data lama).
- Approve: `verified + is_active=true`. Reject: `rejected + is_active=false + verification_note wajib`. Verifikasi ulang yang sudah direview → 409.

### 6.2 Kelola Donasi & Voucher Pendanaan (`GET/POST/PATCH /api/admin/donation-campaigns`, `POST /api/admin/vouchers`)
- Buat/edit campaign donasi, buat voucher pendanaan dari dana sosial (mis. sembako gratis donatur).

### 6.3 Webhook Xendit (`POST /api/webhooks/xendit/payout`, `POST /api/webhooks/xendit/invoice`)
- Callback async payout/invoice, verifikasi `XENDIT_CALLBACK_TOKEN`, sinkron `pending→completed/failed` + saldo. Follow-up polling jika hanya respons sinkron.

---

## 7. Gamifikasi: XP, Level, Streak, Leaderboard

| Mekanik | Aturan |
|---|---|
| **Eco Points** | Mata uang reward (klaim voucher). Mutasi tercatat di `point_transactions` (`credit/debit`, `amount`, `balance_after`, `reference_type/id`). |
| **XP & Level** | XP dari misi/kuis. `LevelService::resolveLevel(xp)` naikkan tier (mis. *Earth Warrior*). |
| **Streak** | `StreakService::nextStreak` update harian tiap misi/kuis sukses. Kuis menjaga streak saat tidak bisa aktivitas fisik. |
| **Leaderboard** | Agregasi `warga_profiles.eco_points` per individu / RT / RW. Index `eco_points` + composite `(rt, rw, eco_points DESC)`. |
| **Anti-fraud** | MIME jpeg/png, EXIF best-effort (longgar karena kompresi Flutter sering strip EXIF), hash SHA256 duplikat → 409 + `anti_fraud_flagged=true`. Validasi kecepatan GPS. Throttle jawaban/upload/redeem. |

---

## 8. Teknologi

**Frontend — `KarbonKitaFrontend/` (Flutter 3.11, Dart ^3.11.4):**
`flutter_bloc`, `dio`, `flutter_secure_storage` (token) + `shared_preferences` (non-sensitif), `camera`, `image_picker`, `image`, `geolocator`, `flutter_map` + `latlong2`, `mobile_scanner` (scan QR) + `qr_flutter` (tampil QR), `hive`/`hive_flutter`, `connectivity_plus`, `path_provider`, `url_launcher`, `animated_bottom_navigation_bar`, `art_sweetalert`. Lint `flutter_lints`, format `dart format`.

Struktur `lib/`: `bloc/`, `core/`, `data/`, `models/`, `services/`, `ui/screens/`, `ui/widgets/`, `main.dart` (entry → `LoginScreen` → `HomeScreen` 5-tab bottom nav; `MarketplaceScreen` → `DompetVoucherScreen` ticket + QR bottom sheet). Catatan: screen UI sudah ada, wiring BLoC/API masih tahap awal.

**Backend — `backend/` (Laravel 12, PHP ^8.2):**
Sanctum 4.0 (auth; `tymon/jwt-auth` terinstal tapi tidak dipakai), Eloquent + Resources, `DB::transaction + lockForUpdate`, Queue `database`, Scheduler, Vite + Tailwind 4 (`@tailwindcss/vite`, Node 18+), `laravel/pint` formatter. Config minimal Laravel 12 (`bootstrap/app.php`, middleware alias `role`/`auth.society`). Testing SQLite in-memory via `phpunit.xml` (tanpa MySQL), prod/dev MySQL `karbonkita:3306`.

**AI & Payment (server-side only):**
- `GeminiService` (Vision multimodal, prompt JSON `{is_valid, confidence, waste_category, reason}`, timeout 20 dtk, `GEMINI_MOCK`/`GEMINI_MIN_CONFIDENCE=85`).
- `XenditService` (Disbursement via `Http` + Basic Auth, `XENDIT_MOCK`, `mapBankCode()`, timeout 20 dtk, `external_id` unik, `xendit_disbursement_id` unique untuk idempotency).

---

## 9. Struktur Repositori

```
KarbonKitaApp/
├── backend/                  # Laravel 12 API
│   ├── app/Http/Controllers/ # Auth, Dashboard, Mission, Saga, Voucher,
│   │                         # Merchant, Admin, Donation, Webhook, ...
│   ├── app/Services/         # GeminiService, XenditService,
│   │                         # StreakService, LevelService
│   ├── app/Models/           # User, WargaProfile, MitraProfile, Mission,
│   │                         # UserMission, MobilityLog, Quiz, Voucher,
│   │                         # VoucherClaim, PointTransaction, Disbursement
│   ├── routes/api.php        # ±30 endpoint (lihat §11)
│   ├── database/migrations/  # ±27 migrasi (users, profiles, misi, voucher,
│   │                         # donasi, disbursements, jobs, cache, tokens)
│   ├── database/seeders/     # MissionSeeder, VoucherSeeder, AdminSeeder, ...
│   ├── tests/                # Feature + Unit (±98 passed, 409 assertions)
│   ├── docker-compose.yml + Dockerfile + docker/nginx/  # stack prod
│   └── DEPLOY.md             # panduan VPS CloudPanel
├── KarbonKitaFrontend/       # Flutter app
│   ├── lib/                  # bloc, models, services, ui/screens, main.dart
│   ├── assets/images/        #
│   └── pubspec.yaml          #
├── PROJECT_CONTEXT.md        # context induk AI agent (otoritatif)
├── API_Contract_KarbonKita.md# kontrak API v1.2.0 (otoritatif)
├── Database_Schema_KarbonKita.md + ERD_KarbonKita.md/.html
├── BACKEND_IMPLEMENTATION_STEPS.md  # Fase 1–4
├── roadmap.md (Fase 3 Misi/Gemini — selesai) + roadmap-fase4.md (selesai)
├── KarbonKita_API.postman_collection.json + KarbonKita.postman_environment.json
├── OVERVIEW.md               # ringkasan fitur singkat
├── AGENTS.md                 # instruksi agen root
└── DOKUMENTASI-KarbonKita.md # file ini
```

Tidak ada monorepo tooling. Perintah dijalankan dari subfolder masing-masing.

---

## 10. Database (ringkas)

- **Core:** `users` (kredensial + `role: warga|mitra|admin`, relasi `hasOne WargaProfile/MitraProfile`, `hasMany UserMission/VoucherClaim/PointTransaction`), `warga_profiles` (`level/xp/eco_points/streak_days/total_distance_km/total_carbon_saved_kg/total_waste_kg`, lokasi mikro), `mitra_profiles` (`nama_usaha, status_verifikasi pending|verified|rejected, is_active, balance, bank, verification_note, dokumen KTP/NIB/toko`).
- **Gamifikasi & misi:** `missions` (`category mobility|waste|quiz|donation, xp_reward, points_reward, target_distance, validation_prompt, is_active`), `user_missions` (`proof_image_url/hash, ai_gemini_response JSON, confidence_score, status pending|verified|rejected, anti_fraud_flagged`), `mobility_logs` (`start/end/route JSON, distance_km, co2_saved_grams, duration_minutes, transport_mode`), `quizzes` (soal + kunci).
- **Transaksi & finansial:** `vouchers` (`mitra_profile_id, category, rupiah_value, points_price, stock, expired_at, is_active`), `voucher_claims` (`qr_token unik KBK-*, status claimed|used|expired, used_at`), `point_transactions` (ledger audit `credit|debit`), `disbursements` (`xendit_disbursement_id unique, amount, bank_*, status pending|completed|failed|cancelled|expired, response_log, failure_reason`).
- **Donasi:** `donation_campaigns` + `donations` (lihat migrasi `2026_09_08_000001`).
- **Sistem:** `personal_access_tokens` (Sanctum), `jobs`, `cache`.

Relasi ringkas: `Users(1)→(1) Warga/Mitra_Profiles`; `Missions(1)→(N) User_Missions/Quizzes`; `Mitra(1)→(N) Vouchers(1)→(N) Voucher_Claims`; `User_Missions/Voucher_Claims(N)→(1) Point_Transactions`.

---

## 11. API (ringkas, base `/api`, envelope `{success,message,data}`)

**Auth:** `POST auth/register`, `POST auth/register-mitra`, `POST auth/login`, `POST auth/logout`, `GET user`.
**Warga:** `GET user/dashboard`, `GET user/levels`, `GET user/activities`, `GET leaderboard`, `GET missions/active`, `POST missions/verify-waste`, `POST missions/mobility-sync`, `GET saga/nodes`, `GET saga/nodes/{id}/questions`, `GET saga/quizzes`, `POST saga/answer`, `GET user/carbon-stats`, `GET vouchers`, `POST vouchers/claim`, `GET user/my-vouchers`.
**Donasi:** `GET donation-campaigns` (publik), `GET donation-campaigns/{slug}` (publik), `POST donations`, `GET user/my-donations`, `POST donations/{id}/cancel`.
**Merchant (`role:mitra`):** `GET merchant/dashboard`, `GET merchant/disbursements`, `PATCH merchant/status`, `POST vouchers/redeem`.
**Admin (`role:admin`):** `GET admin/merchants`, `GET admin/merchants/pending`, `GET admin/merchants/{id}`, `POST admin/merchants/{id}/verify`, `GET/POST/PATCH admin/donation-campaigns`, `POST admin/vouchers`.
**Webhook:** `POST webhooks/xendit/payout`, `POST webhooks/xendit/invoice`.

Koleksi Postman di root dapat dijalankan berurutan (Auth → Misi → Saga → Voucher claim → Merchant redeem → Admin).

---

## 12. Keamanan & Integritas

- Sanctum + HTTPS, throttle login `5,1`, jawab/verify `10,1`, redeem `30,1`.
- Middleware `role:mitra|admin` (`EnsureRole`, alias dua arah `admin ↔ super_admin`).
- Validasi AI & payout server-side; nominal & hasil validasi tidak pernah dipercaya dari client.
- `DB::transaction + lockForUpdate` untuk register (User+Profile), claim, redeem, mission reward — cegah double-spend/scan bersamaan.
- Audit penuh: `ai_gemini_response`, `response_log` Xendit, `point_transactions`, `xendit_disbursement_id` unique.
- Mode mock (`GEMINI_MOCK`/`XENDIT_MOCK`) untuk dev/test; key asli hanya via env, tidak di-commit (`.env` di-gitignore).

---

## 13. Menjalankan & Menguji

**Backend (`backend/`):**
```bash
composer install
cp .env.example .env   # set DB_DATABASE=karbonkita, MySQL 3306
php artisan key:generate
php artisan migrate --force
php artisan storage:link
php artisan db:seed    # MissionSeeder + VoucherSeeder + AdminSeeder
composer dev           # serve :8000 + queue:listen + vite (atau satuan di bawah)
# php artisan serve | php artisan queue:listen --tries=1 | npm run dev / npm run build
composer test          # config:clear + php artisan test (SQLite memory, tanpa MySQL)
php artisan test --filter=NamaTest
vendor/bin/pint        # formatter
```

**Frontend (`KarbonKitaFrontend/`):**
```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

Jalankan `composer test` / `flutter analyze` sebelum push — tidak ada CI.

**Deploy prod:** stack Docker Compose (`app/queue/db/web`) + CloudPanel Nginx reverse-proxy (`mage.pemudasintaks.web.id` → `127.0.0.1:${WEB_PORT}`). Nginx container **tidak** bind 80/443 — TLS dipegang host CloudPanel. Detail: `backend/DEPLOY.md`, `Dockerfile`, `docker/entrypoint.sh`, `docker/nginx/default.conf`, `.env.production.example`.

---

## 14. Status & Peta Jalan

- **Selesai:** Fase 1 (DB & migrasi 15+ tabel), Fase 2 (Auth Sanctum), Fase 3 (Misi + Saga + Gemini, 64 passed), Fase 4 (Redeem + Xendit + Merchant/Admin, 98 passed), Donasi + Webhook + onboarding mitra + index leaderboard.
- **Berikutnya:** upload dokumen mitra penuh, katalog voucher oleh admin + scheduler `expired` otomatis, polling/webhook Xendit lanjutan, wiring BLoC + Dio client Flutter (auth/dashboard/saga/voucher/scanner), hardening EXIF/GPS & retensi storage.

---

## 15. Dokumen Acuan (otoritatif)

1. `PROJECT_CONTEXT.md` — konteks induk (arsitektur, UI flow, guardrails).
2. `API_Contract_KarbonKita.md` — kontrak API v1.2.0.
3. `Database_Schema_KarbonKita.md` + `ERD_KarbonKita.md` / `ERD_KarbonKita_Interactive.html`.
4. `BACKEND_IMPLEMENTATION_STEPS.md` — Fase 1–4.
5. `roadmap.md`, `roadmap-fase4.md` — laporan selesai Fase 3 & 4.
6. `KarbonKita_API.postman_collection.json` + `KarbonKita.postman_environment.json`.
7. `backend/DEPLOY.md` — deploy CloudPanel/Docker.
8. `AGENTS.md` (+ `KarbonKitaFrontend/AGENTS.md`) — aturan kerja agen.
