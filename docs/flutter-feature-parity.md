# NyumbaSearch — Flutter feature parity (index)

**Goal:** Native Flutter app that feels like the same NyumbaSearch product as [nyumbasearch.com](https://nyumbasearch.com), sharing backend via Mobile BFF — without redesigning or breaking the website.

**Package:** `ke.co.nyumbasearch.app` · **App:** `flutter_app/` · **Website:** `find-nyumba-smart/`

## Living documents

| Doc | Purpose |
|-----|---------|
| [flutter-complete-feature-inventory.md](./flutter-complete-feature-inventory.md) | Master feature ID table (required) |
| [flutter-dashboard-parity.md](./flutter-dashboard-parity.md) | Dashboard chrome parity |
| [flutter-role-parity.md](./flutter-role-parity.md) | Role / permission parity |
| [flutter-android-compatibility.md](./flutter-android-compatibility.md) | Device / API / perf |
| [flutter-testing-matrix.md](./flutter-testing-matrix.md) | Functional + Section 26 gate |
| [flutter-feature-parity-matrix.md](./flutter-feature-parity-matrix.md) | Feature-by-feature STATUS (functional) |
| [flutter-uiux-parity.md](./flutter-uiux-parity.md) | Screen/component visual map |
| [flutter-animation-parity.md](./flutter-animation-parity.md) | Framer Motion → Flutter |
| [flutter-3d-parity.md](./flutter-3d-parity.md) | Three.js / Mapbox 3D → Flutter |
| [flutter-api-contracts.md](./flutter-api-contracts.md) | Shipped BFF endpoints |
| [flutter-backend-map.md](./flutter-backend-map.md) | Cores → BFF → Flutter |
| [mobile-bff-full-spec.md](./mobile-bff-full-spec.md) | BFF principles + payments |
| [flutter-architecture.md](./flutter-architecture.md) | App structure |
| [flutter-migration-plan.md](./flutter-migration-plan.md) | Phases 0–29 execution |
| [flutter-parity-backlog.md](./flutter-parity-backlog.md) | Prioritized Phase 4+ gaps |
| [auth-role-map.md](./auth-role-map.md) | Roles / portals |
| [payment-flow-map.md](./payment-flow-map.md) | IntaSend / Daraja / Pesapal |
| [pm-flow-map.md](./pm-flow-map.md) | Property management |
| [security-assessment.md](./security-assessment.md) | Security checklist |

## Honest gate (2026-08-11)

| Dimension | State |
|-----------|--------|
| Day-to-day role **functionality** (tenant → admin + Wave 19) | Strong — inventory mostly `IMPLEMENTED` / UNTESTED |
| **Visual** match vs website mobile chrome | Partial — tokens/nav close; polish open |
| **3D / Mapbox extrusion / HeroScene3D** | Mapbox 3D **IMPLEMENTED**; HeroScene3D stand-in IN DEVELOPMENT |
| Former marketing / advertise / import / integrations / revenue | Wave 19 **IMPLEMENTED** (not WEB_FALLBACK) |
| WebView cutover | **NOT PASSED** — keep WebView until Section 26 signed off |

**Do not claim full parity** until inventory rows are `VERIFIED` and device QA passes.
