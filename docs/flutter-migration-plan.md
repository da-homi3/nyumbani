# NyumbaSearch — Full Flutter migration plan

**Goal:** Native Flutter app with website feature + visual parity for product roles, while the website remains production.

**Package ID:** `ke.co.nyumbasearch.app` (unchanged)  
**App:** [`flutter_app/`](../flutter_app/)  
**Website / Worker:** [`find-nyumba-smart/`](../find-nyumba-smart/)  
**Index:** [flutter-feature-parity.md](./flutter-feature-parity.md)

## Constraints

- Additive Mobile BFF only (`/api/mobile/v1/*`) wrapping existing cores.
- No service-role or payment secrets in Flutter.
- Payments: rent → IntaSend; other M-Pesa → Daraja; card → Pesapal.
- No destructive DB migrations without explicit approval.
- Do not delete WebView until parity gate + device QA pass.
- Do not redesign or break the website.
- Do not silently remove 3D/animations — document in [flutter-3d-parity.md](./flutter-3d-parity.md).

## Document pack

| Doc | Purpose |
|-----|---------|
| [flutter-feature-parity.md](./flutter-feature-parity.md) | Index |
| [flutter-feature-parity-matrix.md](./flutter-feature-parity-matrix.md) | Functional STATUS |
| [flutter-uiux-parity.md](./flutter-uiux-parity.md) | Visual screen map |
| [flutter-animation-parity.md](./flutter-animation-parity.md) | Motion inventory |
| [flutter-3d-parity.md](./flutter-3d-parity.md) | 3D / Mapbox |
| [flutter-api-contracts.md](./flutter-api-contracts.md) | Shipped BFF |
| [flutter-backend-map.md](./flutter-backend-map.md) | Backend wiring |
| [flutter-parity-backlog.md](./flutter-parity-backlog.md) | Phase 4+ gaps |
| [mobile-bff-full-spec.md](./mobile-bff-full-spec.md) | BFF principles |
| [flutter-architecture.md](./flutter-architecture.md) | App architecture |

## Baseline (2026-08-08)

- BFF Core + Waves **1–18** shipped.
- Flutter functional coverage broad (~70 routes, all major roles).
- Visual/3D: tokens + motion stand-ins; **not** full Three.js / Mapbox extrusion.
- AAB signed (`1.0.13+14`); WebView cutover **not** done.
- Open: Google OAuth device QA, `APPLE_TEAM_ID`, visual regression, denser PM tables.

## Phases 0–29 (brief sequence)

| Phase | Work | Status |
|------:|------|--------|
| 0 | Website audit | Done |
| 1 | Parity docs (UIUX/animation/3D/API/matrix) | Done (this pack refresh) |
| 2 | Flutter architecture + design system lock | Done (tokens/assets/icons 2026-08-08) |
| 3 | Mobile BFF expansion | Done through wave 18; `PATCH /providers/me` added |
| 4 | Auth + roles | Done (OAuth device QA open) |
| 5 | Shared components / chrome | Done (top bar + bottom nav tokens) |
| 6 | Tenant experience visual | Improved (neighborhood cards + tour CTA) |
| 7 | Property marketplace | Functional done; visual partial |
| 8 | Maps + 3D buildings | Partial (2D map; 3D deferred — see flutter-3d-parity.md) |
| 9 | Favorites / reviews | Done |
| 10 | Payments / unlock | Done |
| 11 | Landlord | Functional done |
| 12 | Manager / PM denseness | Improved (tables + agency/manager shells) |
| 13 | Agency | Improved (drawer nav + route aliases) |
| 14 | Caretaker | Done |
| 15 | Service providers | Done (`PATCH /providers/me`) |
| 16 | Subscriptions | Done |
| 17 | Verification | Done |
| 18 | Notifications | Done |
| 19 | Admin (mobile queues) | Improved (card queues); revenue WEB_FALLBACK |
| 20 | 3D / animations fidelity | Improved (fadeRoute + orbs/tilt; Mapbox 3D deferred) |
| 21 | Deep links | Android done; iOS Team ID pending |
| 22 | Performance | Ongoing |
| 23 | Visual regression testing | Checklist added (`tool/visual_qa_checklist.dart`) |
| 24 | Functional testing / smoke | Smoke tools exist |
| 25 | Security audit | See security-assessment.md |
| 26 | Real-device QA | Checklist pending completion |
| 27 | Production AAB | Built; rebuild after UI waves |
| 28 | Play Store WebView replacement | Blocked on gate |
| 29 | iOS build + testing | Partial |

## Feature loop (mandatory)

1. Audit website implementation  
2. Map BFF contract  
3. Implement Flutter UI matching tokens/motion  
4. Update STATUS in matrices  
5. Screenshot compare  
6. Website regression if BFF touched  

## Cutover gate

All must be true:

1. Critical matrix rows `IMPLEMENTED` / `FUNCTIONALLY_MATCHED` / justified `WEB_FALLBACK`  
2. UIUX P0–P1 backlog closed or STATUS’d  
3. Device QA checklist green (incl. Google OAuth)  
4. Signed AAB with upload keystore  
5. Website smoke green after last BFF deploy  
