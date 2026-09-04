# Flutter parity backlog (Phase 4+)

Prioritized after Phase 0–1 docs. Work screen-by-screen: website screenshot → implement → update STATUS in inventory / uiux / feature matrices.

## P0 — Theme + shared chrome

1. Expand `NyumbaTokens` / `AppTheme` — **done**
2. Brand assets under `flutter_app/assets/` — **done**
3. Lucide→Flutter icon mapping — **done**
4. Tighten `SiteTopBar` / bottom nav — **done**

## P1 — Tenant visual fidelity

1. Home hero / neighborhood cards — **done**
2. Property cards — **improved** (intel chips: water/security/internet/parking)
3. Browse chrome — **done** (beds, max rent, parking/water/security chips + sort)
4. Detail gallery / 360 CTA — **functional**
5. Map 3D buildings — **done** (`mapbox_maps_flutter` + fill-extrusion/terrain)
6. Settings trust + About/Legal links — **done** (Wave 19)
7. Bottom nav sliding pill — **done** (`HomeShell` AnimatedPositioned glass pill)
8. Testimonials carousel — **done** (`HomeTestimonialsCarousel` + `/api/testimonials`)

## P2 — Motion / 3D

1. AmbientBackdrop / HeroOrbs — **improved** (R3F palette, ~70 rotating points, pointer camera drift, TickerMode pause); exact Three.js still IN DEVELOPMENT
2. TiltCard — **improved** (stronger hover parallax + press depth)
3. Page transitions — **done**
4. 360 tour — **functional** (in-app player; video_player + WebView embeds)
5. Save heart pop + contact reveal — **done**
6. Verification pipeline + plan lift cards — **done**
7. SiteTopBar `glassTopBar` token — **done**

## P3 — Portal denseness + former fallbacks

1. PM tables denseness — **done** (`PmDenseDataTable` across units/tenants/rent/maint/complaints/staff)
2. Agency/manager aliases — **done**
3. `PATCH /providers/me` — **done**
4. Admin queues + **AdminRevenuePage** — **done** (Wave 19) + stacked revenue chart
5. CSV import + integrations — **done** (Wave 19)
6. Contact + Advertise — **done** (Wave 19)
7. Admin announce / founding promo / advertise review — **done** (Wave 20)
8. Waves 19–20 BFF **deployed** to `nyumbasearch.com` (Worker version `2f33aca7…`)
9. Password-reset step pipeline — **done**
10. Shared `EmptyState` + landlord dense metrics/quick actions — **done**
11. Listings 2-col grid + empties (notifications/admin/PM) — **done**

## P4 — QA + cutover

1. Visual regression checklist — **tool exists**
2. Live BFF smoke + device QA — **tools exist**; deploy live — **done**; emulator install smoke **2026-08-11** (Supabase + BFF reachable; OAuth deep-link intent delivered)
3. Google OAuth physical device — **open** (callback route + resume harden + emulator deep-link intent OK; Google account confirm pending)
4. `APPLE_TEAM_ID` for AASA — **DEFERRED** (neglect for now; do not invent)
5. Signed AAB → Play replacing WebView **only after Section 26 gate** — **NOT PASSED**

## Documented blockers (not omissions)

| Item | Status |
|------|--------|
| Mapbox fill-extrusion | IMPLEMENTED |
| HeroScene3D exact Three.js | IN DEVELOPMENT (CustomPainter fidelity ↑) |
| APPLE_TEAM_ID | DEFERRED |
| Google OAuth device QA | TESTING (`/login-callback` + lifecycle) |
| Section 26 cutover gate | NOT PASSED |
