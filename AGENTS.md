# AGENTS.md — KarbonKita

Two independent apps in one repo. No monorepo tooling. Run commands from the respective subfolder.

- `backend/` — Laravel 12, PHP ^8.2, Sanctum 4.0, Vite + Tailwind 4 (`backend/README.md` is stock Laravel, ignore it)
- `KarbonKitaFrontend/` — Flutter 3.11, `flutter_bloc`/`dio`/`flutter_secure_storage`

Authoritative specs (trust these over prose): `PROJECT_CONTEXT.md`, `Database_Schema_KarbonKita.md`, `API_Contract_KarbonKita.md`, `BACKEND_IMPLEMENTATION_STEPS.md`, `KarbonKita_API.postman_collection.json`

## Setup

**Backend** (`backend/`):
```bash
composer install
cp .env.example .env   # then set DB_DATABASE=karbonkita, MySQL 3306
php artisan key:generate
php artisan migrate --force   # 15 migrations incl. personal_access_tokens
npm install && npm run build
# shortcut that does all of the above + build:
composer setup
```
Requires MySQL (`DB_CONNECTION=mysql`, `DB_DATABASE=karbonkita` in `backend/.env`). Tests override to SQLite in-memory via `phpunit.xml:26-27` — no MySQL needed for tests.

**Frontend** (`KarbonKitaFrontend/`):
```bash
flutter pub get
```

## Development

**Backend — prefer `composer dev`** (`backend/composer.json:48-51`):
```bash
composer dev  # concurrently: php artisan serve + queue:listen --tries=1 + vite (npm run dev) on ports 8000/vite
# individually:
php artisan serve              # APP_URL=http://localhost
php artisan queue:listen --tries=1  # QUEUE_CONNECTION=database
npm run dev                    # vite dev server
npm run build                  # vite build (resources/css/app.css + resources/js/app.js, see vite.config.js:8)
```
Config is Laravel 12 minimal: routes in `routes/api.php`, middleware aliases in `bootstrap/app.php:15-17` (`auth.society` only). No `app/Http/Kernel.php`.

**Frontend:**
```bash
flutter run
flutter analyze   # uses flutter_lints via analysis_options.yaml:10
flutter test
```

## Testing & Quality

**Backend:**
```bash
composer test                          # = php artisan config:clear --ansi && php artisan test
php artisan test                       # all tests (Feature + Unit, phpunit.xml:8-13)
php artisan test --filter=TestName     # single test
php artisan test tests/Feature/ExampleTest.php
vendor/bin/pint                        # formatter (laravel/pint ^1.24, no pint.json — defaults)
```
`phpunit.xml` forces `DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`, `CACHE_STORE=array`, `QUEUE_CONNECTION=sync`. No external services needed for unit/feature tests.

**Frontend:**
```bash
flutter test
flutter analyze
```

Run `composer test` / `flutter analyze` before pushing; there is no CI workflow to catch you.

## Architecture & Guardrails

- **Auth:** Laravel Sanctum (`tymon/jwt-auth` is installed but unused — Sanctum via `HasApiTokens` on `app/Models/User.php:14` is source of truth). All protected routes under `auth:sanctum` in `routes/api.php:15`. Login throttled `throttle:5,1` (`routes/api.php:12`). Token via `POST /api/auth/register` + `POST /api/auth/login` → `Bearer 1|...`.
- **DB transactions & locking:** Financial endpoints (`POST /api/vouchers/claim`, future `redeem`/Xendit) MUST use `DB::transaction()` + `lockForUpdate()` — see `app/Http/Controllers/VoucherController.php:41-46,61` for pattern. Rollback on Xendit failure. Also wrap `User`+`Profile` creation on register.
- **AI validation server-side only:** Gemini Vision for `POST /api/missions/verify-waste` runs in backend `GeminiService`, never in Flutter. Includes EXIF check + duplicate hash blocking (`PROJECT_CONTEXT.md:66-70`).
- **Response envelope:** All JSON wrapped as `{success, message, data}` (`API_Contract_KarbonKita.md:20`, `VoucherController.php:29-33`).
- **Eloquent:** Use `with()` eager loading for `user`/`wargaProfile`/`mitraProfile` queries; index `warga_profiles.eco_points` exists for leaderboard (`database/migrations/2024_01_02_000001_create_warga_profiles_table.php:16`). Contract also expects composite `(rt, rw, eco_points DESC)` — add if leaderboard is slow.
- **Models/relations:** `User` hasOne `WargaProfile`/`MitraProfile`, hasMany `UserMission`/`VoucherClaim`/`PointTransaction` (`app/Models/User.php:44-72`). `warga_profiles` holds `level`/`xp`/`eco_points`/`streak_days`.
- **Throttle / anti-fraud:** `user_missions` stores `proof_image_url`, `ai_gemini_response` JSON, `confidence_score`, `anti_fraud_flagged` + image hash duplicate check.

## Conventions & Gotchas

- `.editorconfig` enforces LF, 4-space indents (2 for yaml), `trim_trailing_whitespace` except `*.md`.
- `.gitignore` ignores `backend/vendor/`, `node_modules/`, `.env`, `storage/*.key`, `.phpunit.cache`. Never commit `.env` — use `.env.example`.
- `backend/.env` has `APP_KEY` pre-generated for local; regenerate on fresh clone only if missing.
- Frontend `lib/` already scaffolded (login, register, marketplace, mission, mitra dashboard, quiz FAB). See `KarbonKitaFrontend/AGENTS.md` when working in frontend. Frontend deps: (`dio`, `flutter_bloc`, `shared_preferences`, `flutter_secure_storage`).
- No `opencode.json`, no `.github/workflows`, no `CLAUDE.md`/`.cursor` rules — this file is the sole agent instruction source at root (plus `KarbonKitaFrontend/AGENTS.md` for frontend).
- `vite.config.js` uses `@tailwindcss/vite` — requires Node 18+ for `npm run dev/build`.
- Branch naming: `feature/<name>`, `bugfix/<name>` (from frontend CONTRIBUTING.md).
- **Deploy (backend):** Docker Compose production stack in `backend/docker-compose.yml` (services `app`/`queue`/`db`/`web`). VPS sekolah uses **CloudPanel** (Nginx host owns 80/443); `web` (nginx container) only binds `127.0.0.1:${WEB_PORT}`, CloudPanel reverse-proxies `mage.pemudasintaks.web.id` → that port. Full guide: `DEPLOY.md`. Files: `backend/Dockerfile`, `backend/docker/entrypoint.sh`, `backend/docker/nginx/default.conf`, `backend/.env.production.example`. Never bind 80/443 in this stack — CloudPanel handles TLS.
