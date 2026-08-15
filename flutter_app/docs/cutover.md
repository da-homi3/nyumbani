# Flutter cutover runbook

Tenant MVP (phases 0–6) is implemented. Use this when replacing the Play Store WebView build with the Flutter AAB.

## Pre-cutover checklist

1. **Same package ID:** `ke.co.nyumbasearch.app` (do not change).
2. **Version:** Flutter `pubspec.yaml` must be **above** the last WebView Play upload (`1.0.12` / `13`). Current: **1.0.13+14**.
3. **Signing:** `flutter_app/android/key.properties` must use the **same upload keystore** as the WebView app. Copy from `key.properties.example`.
4. **assetlinks.json** already lists this package + SHA-256 fingerprints — no change needed if the signing cert is unchanged.
5. **Website / Worker:** Deploy BFF only after smoke (see below). Keep WebView FCM client `android` accepted.
6. **Device QA:** Complete the manual list in [`qa-aab.md`](./qa-aab.md).

## Build Play AAB

```bash
cd flutter_app
# Ensure android/key.properties exists (gitignored)
flutter clean
flutter test
flutter build appbundle --release
```

Artifact: `build/app/outputs/bundle/release/app-release.aab`

Upload to Play Console as a **production** (or staged rollout) release for `ke.co.nyumbasearch.app`. Users update in place; WebView APK is replaced by Flutter.

## Post-deploy Worker smoke

```bash
curl.exe -sS -H "X-App-Client: flutter" https://nyumbasearch.com/api/mobile/v1/health
curl.exe -sS -H "X-App-Client: flutter" "https://nyumbasearch.com/api/mobile/v1/listings?limit=1"
curl.exe -sS -o NUL -w "%{http_code}" https://nyumbasearch.com/api/health
```

Or: `dart run tool/live_bff_smoke.dart` from `flutter_app/`.

## Rollback

- Play Console → previous WebView release (same applicationId).
- Website/Worker: BFF routes are additive; rolling back the app does not require removing `/api/mobile/v1/*`.

## Out of scope (later)

- Landlord / agency / manager native modules (open website portals for now)
- iOS
- Replacing the in-repo WebView project until Flutter Play traffic is stable
