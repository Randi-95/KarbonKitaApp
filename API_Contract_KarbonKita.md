# API Contract & Specification - KarbonKita
**Version**: 1.2.0 (Combined Full Spec: Read & Write)  
**Security Standard**: Laravel Sanctum, HTTPS Only  
**Format**: OpenAPI 3.0 / JSON RESTful

Dokumen ini adalah referensi tunggal (Single Source of Truth) untuk API KarbonKita, mencakup seluruh operasi GET (Read) dan POST (Write).

---

## 1. Standar Keamanan & Otomasi (Industry Best Practices)

## 🛡️ Autentikasi: Laravel Sanctum
Proyek ini menggunakan **Laravel Sanctum** sebagai standar autentikasi API. Sanctum dipilih karena integrasi bawaannya yang kuat dengan ekosistem Laravel 12, keamanan database-backed yang memungkinkan revokasi token instan (penting untuk fitur finansial UMKM), serta kemudahan implementasi untuk aplikasi mobile berbasis Flutter.

1. **Autentikasi**: Selalu gunakan header `Authorization: Bearer 1|toke...ere` pada route yang diproteksi.
2. **Anti-Fraud & Validasi File**:
   - Validasi file foto sampah menggunakan MIME type check (hanya `image/jpeg` atau `image/png`).
   - Backend mengekstrak EXIF metadata untuk mendeteksi *location spoofing*.
3. **Database Transaction**: Wajib pada `/api/vouchers/claim` dan `/api/vouchers/redeem` (Integrasi Xendit).
4. **Data Wrapping**: Semua response harus dibungkus dalam key `success`, `message`, dan `data`.

---

## 2. MODUL: AUTENTIKASI (POST)

### 1. Register Akun Baru
* **Endpoint**: `POST /api/auth/register`
* **Request Body**:
```json
{
  "name": "Moch. Rafi Andi",
  "phone": "+628123456789",
  "email": "rafi@example.com",
  "password": "SecurePassword123!",
  "password_confirmation": "SecurePassword123!",
  "role": "warga",
  "city": "Surabaya", "district": "Gubeng", "sub_district": "Mojo", "rt": "005", "rw": "02"
}
```

### 2. Login
* **Endpoint**: `POST /api/auth/login`
* **Request Body**: `{ "phone_or_email": "...", "password": "..." }`
* **Response (200 OK)**: `{ "success": true, "data": { "user": {...}, "token": "1|..." } }`

---

## 3. MODUL: WARGA (Citizen)

### A. Beranda & Leaderboard (GET)

#### 1. Get Home Dashboard Data
* **Endpoint**: `GET /api/user/dashboard`
* **Data**: Nama, Level, XP, Eco Points, Streak Status, Daily Summary.

#### 2. Get Leaderboard
* **Endpoint**: `GET /api/leaderboard?scope=rt&timeframe=weekly`
* **Data**: Ranking list (User, Rank, Points, RT/RW context).

### B. Misi & Aktivitas (GET & POST)

#### 1. Get Mission Saga Path (GET)
* **Endpoint**: `GET /api/missions/saga`
* **Data**: Status babak misi (Locked/Active/Completed).

#### 2. Validasi Foto Sampah via AI Gemini (POST)
* **Endpoint**: `POST /api/missions/verify-waste`
* **Type**: `multipart/form-data`
* **Params**: `mission_id`, `image` (File).
* **Logic**: AI Gemini menganalisis gambar -> Validasi Anti-Fraud -> Reward Points diberikan.

#### 3. Sinkronisasi Mobilitas Hijau (POST)
* **Endpoint**: `POST /api/missions/mobility-sync`
* **Body**: `activity_type` (cycling/walking), `distance_km`, `duration_seconds`, `gps_coordinates_path` (Array JSON).

#### 4. Get Carbon & Activity Stats (GET)
* **Endpoint**: `GET /api/user/carbon-stats`
* **Data**: Total CO2 saved, KM traveled, KG waste sorted (Untuk tampilan Profil).

### C. Marketplace & Rewards (GET & POST)

#### 1. Get Marketplace Vouchers (GET)
* **Endpoint**: `GET /api/vouchers`
* **Data**: List voucher UMKM yang tersedia untuk diklaim.

#### 2. Klaim Voucher Reward (POST)
* **Endpoint**: `POST /api/vouchers/claim`
* **Body**: `{ "voucher_id": 5 }`
* **Logic**: Cek poin warga -> Potong Poin -> Generate Unique QR Code.

#### 3. Get My Vouchers / Inventory (GET)
* **Endpoint**: `GET /api/user/my-vouchers`
* **Data**: Daftar voucher yang sudah dibeli dan kode QR-nya.

---

## 4. MODUL: MITRA UMKM (Merchant)

#### 1. Get Merchant Dashboard (GET)
* **Endpoint**: `GET /api/merchant/dashboard`
* **Data**: Saldo rupiah (Xendit), Status Buka/Tutup, Riwayat transaksi pencairan.

#### 2. Scan & Cairkan Voucher (POST)
* **Endpoint**: `POST /api/vouchers/redeem`
* **Body**: `{ "unique_code": "KBK-XXX-YYY" }`
* **Logic**: Verifikasi QR -> Hit Xendit API untuk Payout -> Update Saldo Toko.

---

## 5. MODUL: SUPER ADMIN

#### 1. Get Pending Validations (GET)
* **Endpoint**: `GET /api/admin/merchants/pending`
* **Data**: Daftar antrean toko baru yang mendaftar beserta link dokumen KTP/NIB.

#### 2. Verifikasi Mitra (POST)
* **Endpoint**: `POST /api/admin/merchants/{id}/verify`
* **Body**: `{ "action": "approve" | "reject", "reason": "..." }`
