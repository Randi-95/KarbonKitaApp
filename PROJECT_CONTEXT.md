# CONTEXT UTAMA PROYEK (PROJECT CONTEXT) - KARBONKITA
**Dokumen Induk untuk AI Coding Agent & Developer**

Dokumen ini berfungsi sebagai **Context Prompt** utama. Ketika Anda memberikan folder proyek ini ke AI Coding Agent (seperti Claude Code, Cursor, atau OpenCode), minta AI tersebut untuk membaca file ini terlebih dahulu agar memahami seluruh arsitektur, tampilan UI, skema database, dan spesifikasi API proyek KarbonKita secara instan.

---

## 1. Ringkasan Proyek (Project Summary)
- **Nama Proyek**: KarbonKita
- **Tagline**: *Aksi kecil, dampak besar*
- **Tujuan**: Mendorong gaya hidup ramah lingkungan masyarakat perkotaan di Indonesia (pemilahan sampah & mobilitas aktif) menggunakan pendekatan gamifikasi tingkat RT/RW dan ekonomi sirkular.
- **Arsitektur Sistem**:
  - **Mobile App (Frontend)**: Flutter (Multi-role: Warga & Mitra UMKM).
  - **Backend API**: Laravel (RESTful API, Database Transaction, Scheduler).
  - **AI Engine**: Gemini API (Multimodal Vision di server-side untuk klasifikasi foto sampah terpilah & deteksi anti-fraud).
  - **Payment Gateway**: Xendit API (Disbursement otomatis secara real-time ke rekening bank Mitra UMKM saat voucher dipindai).

---

## 2. Struktur Dokumen Teknis (Directory Map)
Seluruh dokumen pendukung tersimpan secara absolut di folder `D:\KarbonKita Docs\`:
1. **Konstruksi Data**: `D:\KarbonKita Docs\Database_Schema_KarbonKita.md` (Spesifikasi field, tipe data, dan relasi).
2. **Visualisasi ERD (Markdown)**: `D:\KarbonKita Docs\ERD_KarbonKita.md` (Kode Mermaid JS untuk Github/Notion).
3. **Visualisasi ERD (Interactive)**: `D:\KarbonKita Docs\ERD_KarbonKita_Interactive.html` (Buka dengan browser untuk visualisasi interaktif).
4. **API Contract**: `D:\KarbonKita Docs\API_Contract_KarbonKita.md` (Payload request/response, HTTP status codes, middleware, security rules).

---

## 3. Struktur Tampilan UI & Flow Aplikasi

### A. Tampilan Warga (Citizen App)
1. **Autentikasi (Register & Login)**:
   - Register menampung data nama, kontak, password, dan wajib menentukan lokasi mikro secara presisi (`Kota`, `Kecamatan`, `Kelurahan`, `RT`, `RW`).
   - Login fleksibel menggunakan kombinasi No HP atau Email.
2. **Dashboard Utama (Beranda)**:
   - Menampilkan Poin Aktif (*Eco Points*), Level Pengguna (*Earth Warrior*), XP Progress Bar, dan status *Streak* harian.
   - Papan peringkat (*Leaderboard*) terintegrasi berdasarkan perolehan poin per individu maupun per RT/RW (menghindari dashboard admin terpisah).
3. **Halaman Misi & Deteksi AI (Misi)**:
   - Peta Misi Saga (*Saga Map*) berisi rangkaian tahapan belajar dan tantangan ramah lingkungan.
   - Kamera scanner untuk memotret bukti sampah terpilah dengan overlay instruksi dan status **"Sistem Anti-Fraud Aktif"**.
   - Tracker GPS real-time untuk merekam rute, jarak km, dan estimasi CO2 yang dihemat dari aktivitas mobilitas aktif.

### B. Tampilan Mitra UMKM (Merchant App)
1. **Dashboard Toko**:
   - Status toggle toko (`Buka / Tutup`).
   - Penampil saldo penarikan *real-time* (saldo rupiah asli dari penukaran voucher warga).
   - Riwayat transaksi voucher dengan status instan *"Berhasil Dicairkan"* (via Xendit).
2. **Voucher Scanner**:
   - Scanner kamera QR Code dan form backup input manual token voucher.
   - Loop Action setelah sukses: Tombol *"Selesai & Scan Lagi"* untuk mengurai antrean kasir.

### C. Tampilan Super Admin (Admin Panel)
1. **Verifikasi Mitra UMKM**:
   - Kartu detail UMKM berisi foto toko, dokumen KTP/NIB, serta status bank payout. Tombol aksi: `Tolak Pengajuan` dan `Verifikasi & Aktifkan`.
2. **Katalog Voucher**:
   - Input voucher baru dengan validasi nilai rupiah, konversi harga poin, kuota stok, tanggal kedaluwarsa, dan upload brosur voucher.

---

## 4. Aturan Penting Implementasi Kode (Coding Guardrails)
Jika AI Agent menulis kode untuk proyek ini, wajib mematuhi aturan berikut:
1. **Keamanan AI Validasi**: Prosedur validasi Gemini API **harus berjalan di Backend Laravel**, bukan di sisi Flutter client. Android/iOS hanya mengirim file gambar mentah.
2. **Integritas Transaksi Finansial**: Transaksi pengurangan poin warga dan pencairan dana ke UMKM melalui API Xendit harus dibungkus dalam blok `DB::transaction()`. Jika Xendit mengembalikan error timeout atau kegagalan transfer, DB wajib di-rollback total.
3. **Optimasi Database**: Gunakan eager loading (`with()`) pada Laravel Eloquent untuk query user-profile, dan gunakan database indexing pada table `warga_profiles` kolom `(rt, rw, eco_points DESC)` untuk mengoptimalkan kinerja *query* Leaderboard.
4. **Mekanisme Anti-Fraud**: Simpan md5/sha256 hash dari foto yang diupload warga ke table `user_missions` untuk memblokir aksi upload foto yang sama berulang kali (*duplicate check*).
