# AGENTS.md

## Quick Commands
- `flutter analyze` — lint check (required before commits)
- `flutter format lib/` — format code (required before commits)
- `flutter test` — run tests
- `flutter run` — local dev server

## Architecture
- **State management**: flutter_bloc (BLoC/Cubit pattern)
- **Networking**: dio
- **Storage**: shared_preferences (non-sensitive), flutter_secure_storage (tokens/passwords)
- **See CONTRIBUTING.md** for full coding rules (file naming, separation of concerns, widget extraction)

## Directory Layout
- `lib/bloc/` — BLoC/Cubit state management (currently empty)
- `lib/models/` — data models, fromJson/toJson (currently empty)
- `lib/services/` — API service, Dio client (currently empty)
- `lib/ui/screens/` — page-level widgets
- `lib/ui/widgets/` — reusable components (currently empty)
- `lib/main.dart` — app entry point

## Current State (Early Stage)
- Screens have UI code but no BLoC wiring — business logic is not yet implemented
- `bloc/`, `models/`, `services/` directories are scaffolded but empty
- App flow: `main.dart` → `LoginScreen` → `HomeScreen` (5-tab bottom nav)

## Conventions
- File names: snake_case
- Class names: PascalCase
- Variables/functions: camelCase
- Extract widgets to `ui/widgets/` when `build()` exceeds ~100 lines
- Assets in `assets/images/` — code uses `errorBuilder` fallbacks for missing images
