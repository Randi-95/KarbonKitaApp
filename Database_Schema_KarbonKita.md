# Skema Database: KarbonKita

Dokumen ini mendefinisikan arsitektur basis data relasional untuk platform **KarbonKita**. Struktur ini dirancang untuk mendukung fitur gamifikasi, verifikasi AI, ekonomi sirkular, dan integrasi finansial yang terukur.

## 1. Overview Sistem
- **Backend Framework**: Laravel
- **Frontend Framework**: Flutter
- **Engine**: RDBMS (MySQL / PostgreSQL)
- **Konteks Utama**: Sistem role-based (Warga, Mitra, Admin) dengan fokus pada validasi aksi lingkungan berbasis AI (Gemini API) dan disbursement otomatis (Xendit).

---

## 2. Diagram Relasi (Ringkasan)
1.  **Users** (1) -> (1) **Warga_Profiles** / **Mitra_Profiles**
2.  **Missions** (1) -> (N) **User_Missions** / **Quizzes**
3.  **Mitra_Profiles** (1) -> (N) **Vouchers**
4.  **Vouchers** (1) -> (N) **Voucher_Claims**
5.  **User_Missions** / **Voucher_Claims** (N) -> (1) **Point_Transactions** (Ledger)

---

## 3. Detail Tabel

### A. Core Management
| Tabel | Deskripsi |
| :--- | :--- |
| `users` | Kredensial login (Email/Phone, Password, Role). |
| `warga_profiles` | Profil warga, status level, XP, dan saldo poin. |
| `mitra_profiles` | Profil UMKM, data verifikasi (KTP/NIB), dan rekening bank. |

### B. Gamifikasi & Misi
| Tabel | Deskripsi |
| :--- | :--- |
| `missions` | Katalog misi (Mobility, Waste, Quiz). |
| `user_missions` | Log bukti foto, respon AI Gemini, & status Anti-Fraud. |
| `mobility_logs` | Data pelacakan GPS (rute, jarak, CO2 saved). |
| `quizzes` | Soal & kunci jawaban untuk misi edukasi. |

### C. Transaksi & Finansial
| Tabel | Deskripsi |
| :--- | :--- |
| `vouchers` | Katalog barang/jasa reward dari Mitra. |
| `voucher_claims` | Voucher yang dibeli warga (token QR unik). |
| `point_transactions` | **Buku Besar** (Ledger) untuk audit semua mutasi poin. |
| `disbursements` | Log transaksi uang riil ke rekening bank Mitra (via Xendit). |

---

## 4. Definisi Struktur Data (DDL Highlights)

### Tabel `user_missions` (Core AI Validation)
Penting untuk menjaga integritas data lingkungan.
- `id`: BIGINT (PK)
- `user_id`: FK
- `mission_id`: FK
- `proof_image_url`: VARCHAR
- `ai_gemini_response`: JSON (Raw data dari Gemini API)
- `confidence_score`: DECIMAL(5,2)
- `status`: ENUM ('pending', 'verified', 'rejected')
- `anti_fraud_flagged`: BOOLEAN (Deteksi duplikasi/kecurangan)

### Tabel `point_transactions` (Audit Trail)
Mencegah manipulasi saldo poin warga.
- `type`: ENUM ('credit', 'debit')
- `reference_id`: BIGINT (ID transaksi sumber, misal ID voucher)
- `reference_type`: VARCHAR (Tabel asal transaksi)

### Tabel `disbursements` (Fintech Integrity)
- `xendit_disbursement_id`: VARCHAR (Unique ID dari gateway)
- `status`: ENUM ('pending', 'completed', 'failed')
- `response_log`: JSON (Audit log komunikasi API Xendit)

---

## 5. Panduan Programmer
1. **Aturan Transaksi (Transaction Logic)**: Selalu gunakan database transaction di Laravel (DB::transaction) saat melakukan `point_transactions` dan update saldo di `warga_profiles` untuk memastikan data selalu konsisten.
2. **Keamanan AI**: Validasi AI Gemini harus dilakukan di **server-side** (Backend Laravel). Jangan pernah mengirimkan hasil validasi dari Flutter karena rawan manipulasi (*Client-side injection*).
3. **Data JSON**: Kolom JSON digunakan untuk fleksibilitas (seperti pada log AI Gemini dan koordinat GPS) agar memudahkan pengembangan fitur tanpa harus mengubah skema tabel di masa depan.
