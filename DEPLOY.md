# Panduan Deploy KarbonKita Backend — Docker + CloudPanel (VPS Sekolah)

Target: Laravel 12 API via Docker Compose di VPS sekolah yang memakai
**CloudPanel** (dulu FastPanel). HTTPS & port 80/443 dipegang Nginx
CloudPanel; projek kita cukup jalan di **satu port localhost** dan
di-*reverse proxy* dari panel.

Domain: **`mage.pemudasintaks.web.id`**

```
Internet
   │  :443 (CloudPanel Nginx — SSL otomatis)
   ▼
mage.pemudasintaks.web.id ──(Reverse Proxy)──► 127.0.0.1:8080
                                                    │  container `web` (nginx)
                                                    ▼
                                          fastcgi app:9000 ──► db, queue
```

> Prinsip multi-projek (sama seperti temanmu): tiap projek = **domain beda +
> port localhost beda**. Tidak ada container yang bind 80/443 selain
> CloudPanel, jadi mustahil bentrok.
>
> Panduan ini sudah **diuji end-to-end di Docker lokal**: build 33/33 sukses,
> 4 container jalan (`db` healthy), `curl http://127.0.0.1:8080/up` = 200.
> Semua jebakan yang ditemui saat pengujian didokumentasikan di bagian 9.

---

## 0. Cek kondisi VPS (SSH)

```bash
cat /etc/os-release                    # Ubuntu/Debian
docker --version || echo "docker belum ada"
docker compose version || echo "compose plugin belum ada"

# PENTING: pastikan port pilihan kita belum dipakai projek lain.
sudo ss -tlnp | grep ':8080'           # kosong = aman pakai 8080
sudo ss -tlnp | grep -E ':80|:443'     # harus Nginx/CloudPanel yang pegang
```

* Kalau `:8080` **kosong** → biarkan `WEB_PORT=8080`.
* Kalau `:8080` **terisi** → pakai `8081`/`8082` dst. (ganti di `.env`).

---

## 1. Install Docker (kalau belum)

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
newgrp docker
docker compose version
```

> Docker aman dipasang berdampingan dengan CloudPanel — keduanya mandiri.

---

## 2. Ambil kode & isi `.env`

```bash
sudo mkdir -p /opt/karbonkita && sudo chown "$USER":"$USER" /opt/karbonkita
git clone https://github.com/Randi-95/KarbonKitaApp.git /opt/karbonkita
cd /opt/karbonkita/backend

cp .env.production.example .env
nano .env
```

Wajib diisi:
* `APP_URL=https://mage.pemudasintaks.web.id` (sudah terisi)
* `WEB_PORT=8080` (atau port lain hasil cek langkah 0)
* `DB_PASSWORD` & `MYSQL_ROOT_PASSWORD` (kuat, berbeda)
* `XENDIT_API_KEY` + `XENDIT_CALLBACK_TOKEN` (mode **live**)

Generate `APP_KEY` (di VPS, tanpa PHP host):
```bash
docker run --rm -v "$PWD:/app" -w /app php:8.4-cli-alpine \
  php -r "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"
# tempel hasilnya ke APP_KEY= di .env
```

---

## 3. Build & jalankan

> **Wajib dari folder `backend/`** (file `docker-compose.yml` ada di sana).
> Error `no configuration file provided: not found` = kamu masih di folder
> lain. Flag `-p karbonkita` boleh dihilangkan karena compose sudah punya
> `name: karbonkita` — hasilnya identik.

```bash
cd /opt/karbonkita/backend
docker compose -p karbonkita up -d --build
docker compose -p karbonkita ps
docker compose -p karbonkita logs -f app     # tunggu "migrate ... DONE"
```

> Service `app` me-mount `./.env` host ke dalam container (agar
> `key:generate` bisa jalan). Pastikan file `.env` **sudah ada** sebelum
> `up` — kalau belum, Docker malah membuat folder bernama `.env`. Jika itu
> terjadi: `down`, hapus folder `.env` tersebut, `cp` dari contoh, lalu `up`
> lagi.

Cek dari **dalam VPS** (belum lewat domain):
```bash
curl -I http://127.0.0.1:8080/up             # harus 200 OK
```

Kalau `app` gagal karena `APP_KEY` kosong:
```bash
docker compose -p karbonkita exec app php artisan key:generate
docker compose -p karbonkita restart app
```
Kalau `key:generate` error `Permission denied` (umum bila `.env` di-mount
dari drive Windows/WSL), pakai `--show` lalu tempel manual:
```bash
docker compose -p karbonkita exec app php artisan key:generate --show
# salin output base64:... ke APP_KEY= di .env (nano), lalu:
docker compose -p karbonkita up -d
docker compose -p karbonkita restart app
```

> Aset Vite (`public/build`) dibangun di image, lalu disalin entrypoint ke
> volume bersama yang dibaca nginx. Tidak perlu `npm` di VPS.

---

## 4. DNS + Reverse Proxy di CloudPanel

1. **DNS domain**: pastikan A record `mage.pemudasintaks.web.id` →
   **IP publik VPS**. Cek: `nslookup mage.pemudasintaks.web.id`.
2. **CloudPanel** → **Sites** → buat site baru dengan domain
   `mage.pemudasintaks.web.id` (tipe boleh "Reverse Proxy" atau "Static";
   kalau panel menawarkan template khusus, pilih itu).
3. Di site tersebut, buka **Reverse Proxy**:
   ```
   Location : /
   Target   : http://127.0.0.1:8080
   ```
   Simpan.
4. Aktifkan **SSL/TLS (Let's Encrypt)** dari CloudPanel untuk domain itu —
   panel yang menerbitkan & memperbarui sertifikat otomatis.

> **Jangan** install/tambahkan Nginx atau Caddy baru di host; pakai yang
> sudah ada di CloudPanel. Kalau ragu di UI-nya, minta bantuan temanmu yang
> sudah biasa (pola `ctfd.semkanisa.my.id` identik).

---

## 5. Verifikasi dari luar

```bash
curl -I https://mage.pemudasintaks.web.id/up                  # 200 OK
curl    https://mage.pemudasintaks.web.id/api/donation-campaigns  # JSON
```
Kalau `502 Bad Gateway` → container `web` tidak jalan / port salah.
Cek: `docker compose -p karbonkita logs web` dan ulangi langkah 0.

---

## 6. Go-live Xendit

1. Dashboard Xendit → **Secret Key (live)** + **Callback Token (live)**.
2. Isi `.env` → `docker compose -p karbonkita up -d` (reload env).
3. Daftarkan webhook:
   ```
   https://mage.pemudasintaks.web.id/api/webhooks/xendit/payout
   https://mage.pemudasintaks.web.id/api/webhooks/xendit/invoice
   ```
4. Uji redeem nominal kecil → `payout_id` asli (bukan `po-mock-`),
   status `pending → completed` via webhook, saldo mitra bertambah.

---

## 7. Arahkan Flutter

```bash
flutter build apk --dart-define API_BASE_URL=https://mage.pemudasintaks.web.id/api
```

---

## 8. Operasional harian

> **Shortcut:** dari folder `backend/`, perintah panjang bisa disingkat via
> `Makefile`. Ini murni pembungkus — **semua perintah `docker compose ...`
> asli tetap bisa dipakai langsung** kapan pun.
>
> | Panjang | Singkat |
> |---|---|
> | `docker compose up -d --build` | `make up` |
> | `docker compose logs -f app` | `make logs` |
> | `docker compose exec app php artisan migrate --force` | `make artisan cmd="migrate --force"` |
> | `docker compose exec app php artisan key:generate --show` | `make key` |
> | `curl -I http://127.0.0.1:8080/up` | `make curl-up` (`PORT=8081` bila ganti port) |

**Update kode:**
```bash
cd /opt/karbonkita && git pull
cd backend && docker compose -p karbonkita up -d --build
```

**Backup database** (cron host, mis. 03:00):
```bash
docker compose -p karbonkita exec -T db \
  mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" karbonkita \
  | gzip > /opt/karbonkita/backup-$(date +%F).sql.gz
```

**Backup upload foto** (volume `karbonkita_storage_app`):
```bash
docker run --rm -v karbonkita_storage_app:/data -v /opt/karbonkita:/backup \
  alpine tar czf /backup/storage-$(date +%F).tar.gz -C /data .
```

**Log:** `docker compose -p karbonkita logs -f app queue web`

**Stop aman:** `docker compose -p karbonkita down`
**Hapus TOTAL (termasuk DB):** `docker compose -p karbonkita down -v` ⚠️

---

## 9. Troubleshooting

### Build gagal `COPY docker/entrypoint.sh: not found`

Penyebab: baris `docker` di `backend/.dockerignore` mengecualikan seluruh
folder `docker/` dari build context, padahal `Dockerfile` butuh
`docker/entrypoint.sh` (dan service `web` butuh `docker/nginx/default.conf`).
Fix (sudah diterapkan di repo): **hapus baris `docker` dari `.dockerignore`**.
Lalu ulangi `up -d --build` — step yang `CACHED` tidak diulang.

### Build gagal `composer install`: `symfony/* requires php >=8.4.1`

`composer.lock` terkunci ke symfony 8.1 (butuh PHP ≥ 8.4, selaras mesin dev
PHP 8.4.x), jadi image **wajib** `php:8.4-fpm-alpine. Fix (sudah diterapkan):
basis `Dockerfile` = `php:8.4-fpm-alpine`. Jangan turunkan ke 8.3 dan jangan
tambah `--ignore-platform-reqs` (menyembunyikan inkompatibilitas nyata;
`composer.json` `"php": "^8.2"` tetap mencakup 8.4).

### `key:generate` → `Permission denied` (mount Windows/WSL)

Tulis file dari container ke `.env` yang di-mount dari drive Windows sering
ditolak. Solusi: generate ke stdout lalu tempel manual (lihat langkah 3,
metode `--show`). Alternatif tanpa compose sama sekali:
```bash
docker run --rm php:8.4-cli-alpine \
  php -r "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"
```

### Ganti port localhost (mis. 8080 sudah dipakai projek lain)

Port **tidak di-hardcode** di compose — dibaca dari variabel `WEB_PORT`
(`docker-compose.yml` baris `"127.0.0.1:${WEB_PORT:-8080}:80"`). Jadi
mengganti port = ubah 1 baris di `.env`, tanpa sentuh kode/Flutter.

1. Cek port baru bebas:
   ```bash
   sudo ss -tlnp | grep ':8081'      # kosong = aman
   ```
2. Ubah `.env` (di `/opt/karbonkita/backend/.env`):
   ```ini
   WEB_PORT=8081
   ```
3. Recreate container `web` saja (tanpa rebuild, data DB aman):
   ```bash
   cd /opt/karbonkita/backend
   docker compose -p karbonkita up -d
   ```
4. Update target **Reverse Proxy** di CloudPanel → `http://127.0.0.1:8081`,
   lalu simpan.
5. Verifikasi:
   ```bash
   curl -I http://127.0.0.1:8081/up                 # dari VPS → 200
   curl -I https://mage.pemudasintaks.web.id/up     # dari luar → 200
   ```

> Port internal antar-container (`app:9000`, `db:3306`) **tidak perlu**
> diganti — mereka hanya hidup di network privat `karbonkita_internal`.
> Yang berubah saat pindah port hanya 2 tempat: `WEB_PORT` di `.env` dan
> target reverse proxy di CloudPanel.

### `502 Bad Gateway` dari domain
Container `web` mati / port tidak cocok. Cek `docker compose -p karbonkita
logs web`, pastikan `WEB_PORT` di `.env` = target CloudPanel, lalu `up -d`.

### `curl http://127.0.0.1:8080/up` gagal dari VPS
`app` belum selesai migrate atau `APP_KEY` kosong. Cek `logs app`; isi
`APP_KEY` (pakai metode `--show` di langkah 3 bila `key:generate` biasa
`Permission denied`), lalu `up -d` + `restart app`.

### Foto upload 404
Volume/`storage:link` belum terbentuk. Jalankan
`docker compose -p karbonkita exec app php artisan storage:link`.

---

## Checklist

- [ ] `ss -tlnp` dicek: 8080 bebas, 80/443 milik CloudPanel
- [ ] Docker terpasang
- [ ] `.env` terisi, `APP_DEBUG=false`, `APP_ENV=production`, `APP_KEY` set
- [ ] `APP_URL=https://mage.pemudasintaks.web.id`
- [ ] `curl http://127.0.0.1:8080/up` = 200 (dari VPS)
- [ ] CloudPanel Reverse Proxy → `127.0.0.1:8080` + SSL aktif
- [ ] `https://mage.pemudasintaks.web.id/up` = 200
- [ ] Xendit live: webhook terdaftar + 1 uji redeem kecil
- [ ] Backup DB & storage terjadwal
- [ ] Flutter `API_BASE_URL` menunjuk domain baru
