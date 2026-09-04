# Flutter Android compatibility

**Package:** `ke.co.nyumbasearch.app` (unchanged — Play continuity with prior WebView app).  
**compileSdk:** 37 · **minSdk:** Flutter default (`flutter.minSdkVersion`) · **targetSdk:** Flutter default.

## Device matrix (required QA)

| Tier | Example | RAM | Checks |
|------|---------|-----|--------|
| Low-end | API 26–29, 2–3 GB | Maps markers ≤ clustered; disable heavy ambient when low memory | |
| Mid | API 30–33, 4–6 GB | Full product flows | |
| High | API 34+, 8 GB+ | Visual QA reference | |
| Tablet | 7–10" | LayoutBuilder breakpoints; no hardcoded widths | |

## Layout rules

- Use `SafeArea`, `LayoutBuilder`, `Flexible`/`Expanded`, slivers for lists.
- Never hardcode full-screen pixel sizes for content.
- Tables: horizontal scroll (`SingleChildScrollView` / `DataTable`) — already used on PM units/tenants/rent.
- Text overflow: `maxLines` + ellipsis on cards.

## Performance budgets

| Area | Budget / practice |
|------|-------------------|
| Home/search lists | Paginated `GET /listings`; list virtualization |
| Images | `cached_network_image`; listing `maxImages` capped via BFF |
| Map | Clustering; avoid per-frame rebuilds |
| 3D / ambient | CustomPainter orbs; **Mapbox 3D buildings + terrain** via `mapbox_maps_flutter` |
| Animations | Dispose controllers; respect reduced-motion where available |
| Network | Dio timeouts; debounce search; no secrets on device |
| Battery | No background polling except FCM; payment poll with backoff |

## Memory / leaks

- Cancel Riverpod listeners on dispose.
- Dispose `AnimationController`, map controllers, text controllers.
- Avoid holding full listing payloads when paginating.

## Test plan linkage

Execute rows in [flutter-testing-matrix.md](./flutter-testing-matrix.md) on at least one low + one mid Android device before cutover. Keep legacy WebView APK available until Section 26 gate is signed off.
