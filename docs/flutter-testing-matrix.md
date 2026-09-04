# Flutter testing matrix

Pair with [flutter-complete-feature-inventory.md](./flutter-complete-feature-inventory.md). For each inventory ID: website behavior → Flutter behavior must match.

## Functional regression (per ID)

| Step | Pass criteria |
|------|---------------|
| 1. Open website route | Loads without error |
| 2. Open Flutter screen | Same role can access |
| 3. Perform primary action | Same validation |
| 4. Backend / DB effect | Same tables updated |
| 5. Success / error UI | Equivalent messaging |
| 6. Permission denial | Unauthorized role blocked |

Mark inventory **TEST STATUS** = PASSED only after steps 1–6 on a real device or emulator with DNS working.

## Visual regression (major screens)

| Screen | Website ref | Flutter | Checklist |
|--------|-------------|---------|-----------|
| Home | `/` / tenant | `/home` | Brand, hero, cards, spacing |
| Search | `/tenant` | `/search` | Filters, cards |
| Map | `/tenant/map` | `/map` | Markers, cluster, 3D buildings + terrain |
| Property detail | `/tenant/property/:id` | `/property/:id` | Gallery, unlock, CTAs |
| Landlord dash | `/landlord/dashboard` | `/landlord` | Stats, nav |
| PM property | `/landlord/manage/:id/*` | `/pm/:id` | Tabs denseness |
| Admin | `/admin` | `/admin` | Queues |
| Auth | `/auth` | `/login` | Fields, Google |

Compare: position, size, spacing, type, color, icons, images, shadows, radius, motion, hierarchy. Use `flutter_app/tool/visual_qa_checklist.dart`.

## Payment / auth smoke

| Flow | Provider | Pass |
|------|----------|------|
| Contact unlock M-Pesa | Daraja via BFF | |
| Contact unlock card | Pesapal redirect | |
| Rent pay | IntaSend via BFF | |
| Plus / plan checkout | Daraja / Pesapal | |
| Email login | Supabase | |
| Google OAuth | Deep link return | |
| Phone OTP | Africa's Talking | |
| Password reset OTP | Email (CF Email) | |

## Android compatibility smoke

See [flutter-android-compatibility.md](./flutter-android-compatibility.md) — low + mid device.

## Section 26 gate checklist

- [ ] All website routes audited (inventory complete)
- [ ] All dashboards audited
- [ ] All roles audited
- [ ] All components / animations / 3D audited
- [ ] All required BFF endpoints exist
- [ ] All Flutter screens exist for inventory rows (or BLOCKED documented)
- [ ] Major workflows work on device
- [ ] Major UI/UX differences corrected
- [ ] Critical Android tests pass
- [ ] **WebView / legacy APK retained until this list is signed off**

**Gate status (2026-08-11):** **NOT PASSED**

Signed-off criteria unmet:
- Inventory rows are `IMPLEMENTED` / `UNTESTED`, not yet `VERIFIED`
- Visual denseness + device QA open (emulator available; denseness improved)
- Mapbox 3D is **IMPLEMENTED** (device visual QA open)
- Empty/error copy uses shared `EmptyState`
- `APPLE_TEAM_ID` remains **DEFERRED** (neglected for now — do not invent)
- **WebView / legacy APK must remain** until an explicit human sign-off of this checklist

Do not retire WebView based on Wave 19 alone.
