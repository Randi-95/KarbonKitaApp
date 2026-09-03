# AGENTS.md — KarbonKita (monorepo)

## Layout
- `KarbonKitaFrontend/` — Flutter app (Dart SDK `^3.11.4`). Has its own `AGENTS.md`; read it when working in frontend.
- `backend/` — Laravel 12 API (PHP `^8.2`, Sanctum + `tymon/jwt-auth`). Standard Laravel layout (`routes/`, `app/`, `database/`, `tests/`).
- Root docs (read before coding): `PROJECT_CONTEXT.md` first, then `API_Contract_KarbonKita.md`, `Database_Schema_KarbonKita.md` for field/endpoint truth.

## Backend commands (run in `backend/`)
- `php artisan test` — PHPUnit suite
- `./vendor/bin/pint --test` — style check (laravel/pint is in require-dev)

## Backend guardrails (from PROJECT_CONTEXT.md §4 — do not violate)
- Gemini vision validation runs **server-side only**; mobile sends raw image files.
- Point deduction + Xendit disbursement must be wrapped in `DB::transaction()`; rollback fully on Xendit timeout/failure.
- Eager-load (`with()`) user-profile queries; `warga_profiles` is indexed on `(rt, rw, eco_points DESC)` for leaderboard queries — keep that access pattern.
- Store sha256/md5 hash of uploaded mission photos in `user_missions` for duplicate-photo (anti-fraud) checks.

## Cross-cutting
- Auth tokens live in `flutter_secure_storage` on mobile, never `shared_preferences`.
- Branch naming: `feature/<name>`, `bugfix/<name>` (from frontend CONTRIBUTING.md).
- No CI workflows in repo; verify with `flutter analyze` / `php artisan test` locally before pushing.
