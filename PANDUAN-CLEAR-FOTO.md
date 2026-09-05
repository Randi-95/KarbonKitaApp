# Panduan Clear Foto & Duplikat (Uji `verify-waste`)

Dokumen ini menjelaskan cara menghapus data uji foto agar **foto yang sama bisa
dipakai tes ulang** tanpa kena `409 Duplicate`. Berlaku untuk database development
(MySQL `karbonkita`) dan storage lokal `storage/app/public`.

## Kenapa perlu clear manual?

Anti-fraud duplikat bekerja global: setiap upload menghitung `sha256` isi file dan
menyimpannya di `user_missions.proof_image_hash`. Selama hash masih ada di tabel,
foto yang sama — oleh user mana pun — selalu ditolak `409` (`anti_fraud_flagged`).
Menghapus file saja tidak cukup; menghapus record saja menyisakan file yatim.

## Yang dibersihkan

| # | Lokasi | Isi | Perintah |
|---|--------|-----|----------|
| 1 | `storage/app/public/proofs/` | File foto bukti (`{userId}/*.jpg|png`) | PowerShell di bawah |
| 2 | `user_missions` | Baris dengan `proof_image_hash IS NOT NULL` (verified/rejected/pending foto) | SQL di bawah |
| 3 | `point_transactions` | Ledger `credit` milik record foto yang verified (morph, tidak cascade otomatis) | SQL di bawah |

Yang **tidak** ikut terhapus: profil warga (XP/poin/streak yang sempat ke-grant tetap),
misi non-foto (quiz/mobility), voucher, dan user.

## Langkah-langkah

Jalankan dari folder `backend/`:

```powershell
# 1. Hapus file foto (folder proofs-nya sendiri jangan dihapus)
Get-ChildItem storage\app\public\proofs -Recurse -File | Remove-Item -Force
```

```sql
-- 2. Hapus ledger poin milik submission foto (di DB karbonkita)
DELETE FROM point_transactions
WHERE reference_type = 'App\\Models\\UserMission'
  AND reference_id IN (SELECT id FROM user_missions WHERE proof_image_hash IS NOT NULL);

-- 3. Hapus record submission foto
DELETE FROM user_missions WHERE proof_image_hash IS NOT NULL;
```

## Verifikasi

```sql
-- Harus 0 sebelum tes ulang dengan foto yang sama
SELECT COUNT(*) FROM user_missions WHERE proof_image_hash IS NOT NULL;
```

```powershell
# Harus kosong (selain .gitignore)
Get-ChildItem storage\app\public\proofs -Recurse -File
```

## Reset total (opsional)

- Hanya statistik akun tester → kembalikan `warga_profiles` milik user tersebut
  (`xp`, `eco_points`, `streak_days`, `total_waste_kg`, `last_mission_at`) ke 0/NULL.
- Seluruh data dev → `php artisan migrate:fresh --seed` (menghapus SEMUA data,
  hanya untuk database development).

## Catatan produksi

Jangan pernah menjalankan panduan ini di database production — duplikat di sana
adalah data anti-fraud yang sah, bukan data uji.
