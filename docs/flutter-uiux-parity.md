# NyumbaSearch — Flutter UI/UX parity map

**Website = source of truth:** `find-nyumba-smart/` (~150 TanStack routes)  
**Flutter:** `flutter_app/` (`ke.co.nyumbasearch.app`)  
**Rule:** Do not claim full visual parity until STATUS is `VISUALLY_MATCHED`. Permanent `WEB_FALLBACK` is **retired** — use `IMPLEMENTED` / `FUNCTIONALLY_MATCHED` / `PARTIAL` / `BLOCKED` (with blocker template in [flutter-complete-feature-inventory.md](./flutter-complete-feature-inventory.md)).

**STATUS:** `FULLY_IMPLEMENTED` | `VISUALLY_MATCHED` | `FUNCTIONALLY_MATCHED` | `PARTIAL` | `IN DEVELOPMENT` | `BLOCKED` | `N/A`

---

## Shared chrome

| WEBSITE ROUTE | PURPOSE | ROLE | WEBSITE COMPONENTS | LAYOUT | ANIMATIONS | INTERACTIONS | DATA | BACKEND | FLUTTER SCREEN | FLUTTER COMPONENTS | STATUS |
|---|---|---|---|---|---|---|---|---|---|---|---|
| global | Site header | all | `SiteNav` | sticky top, glass | blur, role switch | Menu, notifs, logo | session | Supabase | all shells | `SiteTopBar`, `SiteMenuSheet` | FUNCTIONALLY_MATCHED — `glassTopBar` token |
| `/`, `/tenant/*` | Bottom nav | tenant | `TenantBottomNav` | fixed glass pill | layoutId pill | Home/Browse/Map/Rent/Messages | — | — | `HomeShell` | AnimatedPositioned glass pill + scale | VISUALLY_MATCHED |
| portals | Side nav | landlord/agency/manager | `LandlordShell` / `AgencyShell` / `ManagerShell` | desktop sidebar | — | nav tiles | roles | — | portal pages | `PortalShell` drawer (+ agency/manager aliases) | FUNCTIONALLY_MATCHED |
| global | Ambient particles | public | `AmbientBackdrop` | fixed canvas | particle drift | none | — | — | home/portals | `AmbientBackdrop` | FUNCTIONALLY_MATCHED |
| global | Page transition | all | `PageTransition` | AnimatePresence | fade+y | route change | — | — | go_router | `fadeRoute` / CustomTransitionPage | VISUALLY_MATCHED |

---

## Marketing / public

| WEBSITE ROUTE | PURPOSE | ROLE | WEBSITE COMPONENTS | LAYOUT | ANIMATIONS | INTERACTIONS | DATA | BACKEND | FLUTTER SCREEN | FLUTTER COMPONENTS | STATUS |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `/` | Landing | public | `LandingHero`, `HeroScene3D`, … | full-bleed hero | R3F orbs | search, CTAs | listings | listings-core | `HomePage` | hero, testimonials carousel, featured | FUNCTIONALLY_MATCHED — HeroScene3D CustomPainter stand-in |
| `/about`, legal, `/finance`, `/insurance`, `/reports`, `/whatsapp` | Static/legal/marketing | public | static pages | content | — | links | — | — | `SiteContentPage` | in-app WebView of live site | FUNCTIONALLY_MATCHED — chrome-stripped WebView |
| `/contact` | Contact form | public | contact UI | form | — | submit | email | contact + CF Email | `ContactPage` | form + BFF | FUNCTIONALLY_MATCHED |
| `/advertise`, `/advertise/pay` | Advertise | public | packages, inquiry, pay | forms/pay | — | pay | invoices | Wave 19 advertise | `AdvertisePage` | packages + inquiry + pay | FUNCTIONALLY_MATCHED |
| `/referrals` | Referrals | auth | referrals UI | cards | — | copy code | referral tables | referral fns | `ReferralsPage` | list + code | FUNCTIONALLY_MATCHED |

---

## Auth

| WEBSITE ROUTE | PURPOSE | ROLE | WEBSITE COMPONENTS | FLUTTER SCREEN | STATUS |
|---|---|---|---|---|---|
| `/auth/` | Login/signup | all | auth forms, Google, OTP | `LoginPage`, `SignupPage` | FUNCTIONALLY_MATCHED |
| `/auth/callback` | OAuth return | all | Supabase PKCE | `/login-callback` + `OAuthCallbackPage` | TESTING — device confirm open |
| `/auth/pending` | Portal pending | applicants | pending UI | `AuthPendingPage` | FUNCTIONALLY_MATCHED |
| `/auth/reset` | Password reset OTP | all | reset flow | `PasswordResetPage` | FUNCTIONALLY_MATCHED |

---

## Tenant marketplace

| WEBSITE ROUTE | PURPOSE | ROLE | WEBSITE COMPONENTS | FLUTTER SCREEN | STATUS |
|---|---|---|---|---|---|
| `/tenant/` | Browse/search | public/tenant | filters, cards, NyumbaAI | `SearchPage` | IMPLEMENTED — beds/budget/amenity chips + card intel |
| `/tenant/property/$id` | Detail | public | gallery, unlock, reviews | `PropertyDetailPage` | FUNCTIONALLY_MATCHED |
| `/tenant/map` | Map browse | public | `TenantMapApp`, Mapbox 3D | `MapPage` | FUNCTIONALLY_MATCHED — Mapbox fill-extrusion + terrain + markers (visual QA → VERIFIED) |
| `/tenant/saved` | Favorites | tenant | saved list | `SavedPage` | FUNCTIONALLY_MATCHED |
| `/tenant/compare` | Compare | tenant | compare UI | `ComparePage` | FUNCTIONALLY_MATCHED |
| `/tenant/messages` | Inbox | tenant | thread list | `MessagesPage` | FUNCTIONALLY_MATCHED |
| `/tenant/messages/$id` | Thread | tenant | chat | `MessageThreadPage` | FUNCTIONALLY_MATCHED |
| `/tenant/rent` | Rent/invoices | tenant | invoices, IntaSend | `RentPage` | FUNCTIONALLY_MATCHED |
| `/tenant/maintenance` | Maintenance | tenant | list/create | `MaintenancePage` | FUNCTIONALLY_MATCHED |
| `/tenant/complaints` | Complaints | tenant | list/create | `ComplaintsPage` | FUNCTIONALLY_MATCHED |
| `/tenant/checkout` | Plus | tenant | checkout | `PlusPage` | FUNCTIONALLY_MATCHED |
| `/tenant/review/$id` | Leave review | tenant | form | `LeaveReviewPage` | FUNCTIONALLY_MATCHED |
| `/tenant/invite/$token` | Accept invite | tenant | invite accept | `TenantInvitePage` | FUNCTIONALLY_MATCHED |
| `/tenant/profile` | Profile | tenant | profile form | `SettingsPage` | FUNCTIONALLY_MATCHED |
| `/notifications` | Inbox | auth | list + prefs | `NotificationsPage` | FUNCTIONALLY_MATCHED |
| `/settings` | Settings tabs | auth | Profile/Notifs/Security/Portals/Trust | `SettingsPage` | FUNCTIONALLY_MATCHED — About/Legal/Contact/Advertise links |

---

## Landlord / agency / manager

| WEBSITE SURFACE | FLUTTER | STATUS |
|---|---|---|
| Dashboard overview | `LandlordDashboardPage` / `AgencyDashboardPage` / `ManagerDashboardPage` | FUNCTIONALLY_MATCHED |
| Listings CRUD | `MyListingsPage`, create/edit | FUNCTIONALLY_MATCHED |
| Plan / boost / leads / payouts / analytics / caretakers | matching landlord pages | FUNCTIONALLY_MATCHED |
| Org team | `OrgTeamPage` | FUNCTIONALLY_MATCHED |
| PM manage tabs | `PmPropertyPage` | FUNCTIONALLY_MATCHED — all tabs DataTables |
| CSV import | `ListingImportPage` + Wave 19 BFF | FUNCTIONALLY_MATCHED |
| Integrations / API keys | `IntegrationsPage` + Wave 19 BFF | FUNCTIONALLY_MATCHED |

---

## Property management (shared)

| WEBSITE ROUTE pattern | FLUTTER | STATUS |
|---|---|---|
| `/*/manage` list + new + subscribe | `PmListPage`, `PmCreatePage`, `PmSubscribePage` | FUNCTIONALLY_MATCHED |
| Property dashboard KPIs | `PmPropertyPage` overview | FUNCTIONALLY_MATCHED |
| Units / tenants / rent / maintenance / complaints / staff | tabs on `PmPropertyPage` | FUNCTIONALLY_MATCHED — `PmDenseDataTable` denseness |

---

## Caretaker / services / verification / admin

| WEBSITE ROUTE | FLUTTER | STATUS |
|---|---|---|
| `/caretaker`, `/caretaker/dashboard` | `CaretakerLoginPage`, `CaretakerDashboardPage` | FUNCTIONALLY_MATCHED |
| `/services`, `/services/$category`, `/services/provider/$id`, register, dashboard | `ProvidersPage`, detail, register, me | FUNCTIONALLY_MATCHED |
| `/verify/*` | `VerifyRequestPage` + status | FUNCTIONALLY_MATCHED |
| `/admin` tabs | `AdminHomePage` + queue pages | FUNCTIONALLY_MATCHED |
| `/admin/revenue` | `AdminRevenuePage` + Wave 19 BFF | FUNCTIONALLY_MATCHED |
| Admin announcements | `AdminAnnouncementsPage` + Wave 20 BFF | FUNCTIONALLY_MATCHED |
| Admin founding promo | `AdminPromoPage` + Wave 20 BFF | FUNCTIONALLY_MATCHED |
| Admin advertise review | `AdminAdvertisePage` + Wave 20 BFF | FUNCTIONALLY_MATCHED |

---

## Design-system extraction (quick)

| Token | Website | Flutter |
|---|---|---|
| Primary | `#0a8f3d` / glow `#16a34a` | `NyumbaTokens.primaryLight` / `primaryGlowLight` |
| Dark primary | emerald `#22C55E` accents | `primaryGlowDark` |
| Cocoa brand | `#4A2713` | `NyumbaTokens.cocoa` |
| Gold | `#ffd54f` | `NyumbaTokens.gold` |
| Display font | Syne | `GoogleFonts.syne` |
| Body font | Manrope | `GoogleFonts.manrope` |
| Radius | `--radius` 0.75rem | 12 / sm8 / lg16 / xl20 / 2xl24 |

See also: [flutter-animation-parity.md](./flutter-animation-parity.md), [flutter-3d-parity.md](./flutter-3d-parity.md), [flutter-complete-feature-inventory.md](./flutter-complete-feature-inventory.md).
