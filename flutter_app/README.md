# NyumbaSearch Flutter App
#
# Native mobile frontend for the existing NyumbaSearch backend.
# Website (find-nyumba-smart) remains independent.
#
# Application ID: ke.co.nyumbasearch.app
#
# Setup:
# 1. Copy assets/env/.env.example values into run config / --dart-define
# 2. flutter pub get
# 3. node tool/patch_mapbox_agp.mjs   # required after pub get (Mapbox AGP kotlin fix)
# 4. dart run build_runner build --delete-conflicting-outputs
# 5. flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
#
# Map: Mapbox Maps SDK 3D buildings + terrain on /map (token from GET /api/mapbox-token).
# See ../docs/flutter-3d-parity.md
#
# See ../docs/flutter-migration-plan.md
