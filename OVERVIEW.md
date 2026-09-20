# KarbonKita — Gambaran Proyek & Daftar Fitur

> **Tagline:** *Aksi kecil, dampak besar*

**KarbonKita** adalah aplikasi mobile (Flutter) + API backend (Laravel) yang mengajak masyarakat kota di Indonesia untuk hidup lebih ramah lingkungan — terutama **memilah sampah** dan **jalan kaki / bersepeda** — dengan cara yang seru seperti game (gamifikasi) dan menguntungkan (tukar poin jadi voucher UMKM).

Alurnya sederhana:

1. Warga melakukan aksi hijau (foto sampah terpilah, jalan/sepeda, ikut kuis).
2. Sistem memberi **Eco Points + XP + Streak**.
3. Poin ditukar jadi **voucher diskon/barang** milik UMKM mitra.
4. UMKM mencairkan voucher jadi **uang rupiah asli** (via Xendit).
5. Ada juga jalur **donasi** untuk mendanai campaign / voucher sosial.

Ada 3 peran pengguna: **Warga**, **Mitra UMKM**, dan **Admin**.

---

## 1. Fitur untuk Warga (Citizen App)

### 1.1. Register & Login
- **Apa:** Daftar akun dengan nama, HP/email, password, dan lokasi mikro (`Kota, Kecamatan, Kelurahan, RT, RW`). Login bisa pakai No HP atau Email.
- **Untuk apa:** Supaya peringkat (leaderboard) bisa dibuat per RT/RW dan misi tercatat milik siapa.

### 1.2. Beranda / Dashboard
- **Apa:** Menampilkan Eco Points aktif, Level (misal *Earth Warrior*), XP progress bar, status streak harian, dan ringkasan aktivitas hari ini.
- **Untuk apa:** Supaya pengguna tahu progresnya dan termotivasi naik level tiap hari.

### 1.3. Misi Pilah Sampah (Foto + AI Gemini)
- **Apa:** Daftar misi sampah aktif → buka kamera scanner → foto bukti sampah terpilah → backend memverifikasi pakai AI Gemini Vision (server-side, bukan di HP). Ada status *"Sistem Anti-Fraud Aktif"*.
- **Untuk apa:** Membuktikan warga benar-benar memilah sampah, bukan asal foto. Kalau lolos threshold (confidence ≥ 85), dapat poin + XP. Foto yang sama tidak bisa dipakai ulang (cek hash duplikat).

### 1.4. Misi Mobilitas Hijau (GPS Tracker)
- **Apa:** Tracker GPS real-time untuk jalan kaki / bersepeda. Mencatat rute, jarak (km), durasi, dan estimasi CO2 yang dihemat (±210 gram/km).
- **Untuk apa:** Mendorong orang naik sepeda / jalan kaki daripada kendaraan bermotor, sekaligus mengukur kontribusi pengurangan karbon.

### 1.5. Saga Map / Kuis Harian
- **Apa:** Kuis edukasi lingkungan berbentuk peta stage (nodes → questions → jawab A/B/C/D). Ada kuis harian untuk menjaga streak.
- **Untuk apa:** Tetap dapat XP dan menjaga streak walaupun hari itu tidak bisa aktivitas fisik. Sekaligus belajar isu lingkungan.

### 1.6. Leaderboard RT / RW
- **Apa:** Papan peringkat individu maupun per RT/RW (harian/mingguan).
- **Untuk apa:** Memicu kompetisi sehat antar tetangga / antar RT, tanpa perlu dashboard admin terpisah.

### 1.7. Statistik Karbon & Kalkulator Emisi
- **Apa:** Halaman profil berisi total CO2 saved, total KM, total KG sampah dipilah. Ada juga layar Kalkulator Karbon (input kendaraan / aktivitas → estimasi emisi + gauge + rekomendasi).
- **Untuk apa:** Supaya dampak lingkungan pengguna terlihat dalam angka nyata, bukan cuma poin.

### 1.8. Marketplace Voucher
- **Apa:** Katalog voucher dari UMKM mitra per kategori (`kuliner, sembako, fashion, jasa, donasi, transportasi`). Warga menukar Eco Points → dapat QR unik (`KBK-XXX-YYY`).
- **Untuk apa:** Poin hijau jadi manfaat ekonomi nyata — ekonomi sirkular.

### 1.9. Dompet Voucher Saya
- **Apa:** Daftar voucher yang sudah diklaim beserta kode QR-nya, status (`claimed/used/expired`).
- **Untuk apa:** Menyimpan dan menunjukkan QR ke kasir saat belanja di toko mitra.

### 1.10. Donasi
- **Apa:** Lihat katalog campaign donasi (bisa dilihat tanpa login), donasi setelah login, lihat riwayat donasi saya, batalkan donasi.
- **Untuk apa:** Jalur CSR / komunitas untuk mendanai campaign lingkungan atau pendanaan voucher sosial.

---

## 2. Fitur untuk Mitra UMKM (Merchant App)

### 2.1. Register Mitra & Dashboard Toko
- **Apa:** Pendaftaran khusus mitra (upload dokumen KTP/NIB + foto toko + data bank). Setelah diverifikasi admin, dapat dashboard berisi: toggle toko `Buka / Tutup`, saldo rupiah real-time, statistik voucher, dan riwayat pencairan.
- **Untuk apa:** Supaya UMKM bisa ikut menjual lewat voucher dan memantau pendapatan dari penukaran voucher warga.

### 2.2. Scanner / Redeem Voucher
- **Apa:** Scanner kamera QR + form input manual token. Setelah sukses ada tombol *"Selesai & Scan Lagi"* untuk antrean kasir cepat. Backend memverifikasi QR → payout otomatis via Xendit → saldo toko bertambah.
- **Untuk apa:** Mencairkan voucher warga jadi uang asli secara instan (*"Berhasil Dicairkan"*), tanpa rekap manual.

### 2.3. Tambah Katalog Voucher (via Admin / layar katalog)
- **Apa:** Layar `Tambah Katalog Voucher` — input nilai rupiah, harga poin, stok, tanggal kedaluwarsa, upload brosur.
- **Untuk apa:** Supaya toko bisa membuat promo / reward baru yang bisa diklaim warga dengan poin.

---

## 3. Fitur untuk Admin (Super Admin)

### 3.1. Verifikasi Mitra UMKM
- **Apa:** Daftar antrean toko (`pending`) berisi foto toko, dokumen KTP/NIB, status bank payout. Tombol aksi: `Tolak Pengajuan` / `Verifikasi & Aktifkan` (+ catatan penolakan).
- **Untuk apa:** Menjaga hanya UMKM valid dan terverifikasi yang bisa menerima payout uang asli.

### 3.2. Kelola Campaign Donasi & Voucher Pendanaan
- **Apa:** Buat / edit campaign donasi, dan buat voucher pendanaan dari dana sosial.
- **Untuk apa:** Mengelola program CSR / komunitas — misal voucher sembako gratis yang didanai donatur.

---

## 4. Fitur Sistem (di balik layar, tapi penting)

| Fitur | Untuk apa |
|---|---|
| **Login aman (Sanctum + throttle)** | Token bisa dicabut instan, login dibatasi 5x/menit anti brute-force. |
| **Anti-fraud foto** | Cek MIME (jpeg/png), cek EXIF, blokir hash foto duplikat (409). |
| **Transaksi DB + kunci baris** | Klaim/redeem voucher pakai `DB::transaction + lockForUpdate` — gagal Xendit = rollback total, tidak ada double-spend saat scan bersamaan. |
| **Ledger poin & disbursement** | `point_transactions` mencatat semua mutasi poin (audit), `disbursements` mencatat semua payout Xendit + log respons. |
| **Streak & Level otomatis** | Streak harian + naik level dihitung otomatis tiap misi/kuis berhasil. |
| **Webhook Xendit** | Menerima callback payout/invoice agar status pencairan selalu sinkron. |
| **Mode mock Gemini/Xendit** | Bisa development & testing tanpa API key asli (`GEMINI_MOCK` / `XENDIT_MOCK`). |

---

## 5. Teknologi Singkat

- **Frontend:** Flutter (Android/iOS/Web/Desktop), `flutter_bloc`, `dio`, `flutter_secure_storage`, `camera`, `geolocator`, `flutter_map`.
- **Backend:** Laravel 12, PHP 8.2, Sanctum, MySQL (prod/dev) / SQLite memory (test), Queue database, Vite + Tailwind.
- **AI & Payment:** Gemini Vision (server-side), Xendit Disbursement.
- **Dokumen acuan:** `PROJECT_CONTEXT.md`, `API_Contract_KarbonKita.md`, `Database_Schema_KarbonKita.md`, `BACKEND_IMPLEMENTATION_STEPS.md`, Postman collection di root.
