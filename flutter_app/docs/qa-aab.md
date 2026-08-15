# Flutter QA + Play AAB (Phase 6)

## Automated checks (verified 2026-08-07)

From `flutter_app/`:

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build appbundle --release
```

| Check | Result |
| --- | --- |
| Analyze | Clean (0 errors; optional `use_super_parameters` info only) |
| Tests | 11 passed |
| AAB | `build/app/outputs/bundle/release/app-release.aab` (~53 MB) |
| Live BFF | `/health` + `/listings` OK with `X-App-Client: flutter` |
| Site | `/api/health` → 200 |

Version: **1.0.13+14** (above last WebView Play upload `1.0.12` / code `13`).

`compileSdk = 37` (required by `permission_handler_android`).

### Strip warning

If Flutter prints *“failed to strip debug symbols”*, install Android **cmdline-tools** and accept licenses (`flutter doctor --android-licenses`), then rebuild. After cmdline-tools are present, `flutter build appbundle --release` should exit cleanly with `√ Built ... app-release.aab`.

### Disk / NDK

If Gradle fails installing NDK, free disk space, delete any partial `...\Android\Sdk\ndk\<version>` folder, and rebuild.

## Live BFF smoke (after every Worker deploy)

```bash
curl.exe -sS -H "X-App-Client: flutter" https://nyumbasearch.com/api/mobile/v1/health
curl.exe -sS -H "X-App-Client: flutter" "https://nyumbasearch.com/api/mobile/v1/listings?limit=1"
curl.exe -sS -o NUL -w "%{http_code}" https://nyumbasearch.com/api/health
```

Expect: BFF `status: ok`, listings `items` array, site `/api/health` → `200`.

## Play signing (required for store upload)

1. Copy `android/key.properties.example` → `android/key.properties` (gitignored).
2. Point `storeFile` at the **same** upload keystore used for the WebView app (`ke.co.nyumbasearch.app`).
3. Rebuild: `flutter build appbundle --release`.

Without `key.properties`, release builds sign with the **debug** key (local QA only — Play will reject).

## Manual device checklist

- [ ] Cold start → splash → home feed loads
- [ ] Search filters return listings
- [ ] Property detail + gallery
- [ ] Map markers + preview → detail
- [ ] Save / unsave (signed in)
- [ ] Unlock: Plus/trial free path
- [ ] Unlock: M-Pesa STK → poll → reveal phones (call / WhatsApp)
- [ ] Profile roles + open landlord/agency portal in browser
- [ ] App Link: `https://nyumbasearch.com/tenant/property/<id>` opens detail
- [ ] Website still loads after Worker deploy (`/api/health`)

## Package ID

Do not change `applicationId` / namespace: `ke.co.nyumbasearch.app`.
