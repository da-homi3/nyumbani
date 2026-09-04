# NyumbaSearch — Flutter feature parity matrix

**Status:** Living document — functional Waves 1–19; visual/3D fidelity open (2026-08-11)  
**Index:** [flutter-feature-parity.md](./flutter-feature-parity.md) · **Inventory:** [flutter-complete-feature-inventory.md](./flutter-complete-feature-inventory.md) · **UIUX:** [flutter-uiux-parity.md](./flutter-uiux-parity.md) · **3D:** [flutter-3d-parity.md](./flutter-3d-parity.md) · **Backlog:** [flutter-parity-backlog.md](./flutter-parity-backlog.md)  
**Rule:** No claim of full parity until every inventory row is **VERIFIED**. Permanent `WEB FALLBACK` / `NOT APPLICABLE TO MOBILE` as exit statuses are **retired** — use `IMPLEMENTED`→`VERIFIED` or `BLOCKED` with the inventory blocker template.

**STATUS values:** `IMPLEMENTED` | `PARTIAL` | `NOT STARTED` | `PENDING BACKEND SUPPORT` | `BLOCKED` | `TESTING` | `VERIFIED`

**Flutter app:** `flutter_app/` · **BFF:** `/api/mobile/v1/*` (waves 1–19 — see [flutter-api-contracts.md](./flutter-api-contracts.md)) · **Website:** `find-nyumba-smart/` (unchanged)

---

## Legend — BFF column

- Existing Tenant MVP endpoints are named as today (e.g. `GET /listings`).
- Planned endpoints use the full-spec paths from [mobile-bff-full-spec.md](./mobile-bff-full-spec.md).

---

## 1. Authentication & account

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Email/password sign-in | `/auth/` | Supabase Auth | `auth.users`, `profiles` | all | LoginPage | Supabase direct | IMPLEMENTED | — | |
| Email/password sign-up | `/auth/` | Supabase Auth + profile | `profiles`, `user_roles` | tenant (+ portal apps) | SignupPage | Supabase direct + `POST /me/portal-apply` | IMPLEMENTED | Wave 17 | Role chips; privileged → `/auth/pending` |
| Google OAuth | `/auth/`, `/auth/callback` | Supabase OAuth PKCE | `auth.users` | all | LoginPage + `OAuthCallbackPage` | Supabase PKCE + `/login-callback` | TESTING | allowlist redirect | Emulator deep-link intent delivered; Google account confirm pending |
| Password reset | `/auth/`, `/auth/reset` | Supabase reset email | `auth.users` | all | PasswordResetPage | `POST /auth/password-reset/*` | IMPLEMENTED | Wave 18 | OTP flow |
| Phone signup OTP | `/auth/` | Africa's Talking OTP server fns | profiles phone | all | SignupPage | `POST /auth/otp/request` + `/verify` | IMPLEMENTED | Wave 15 | Optional phone verify before signup |
| Password reset OTP | `/auth/reset` | OTP cores | — | all | PasswordResetPage | `POST /auth/password-reset/request\|verify\|complete` | IMPLEMENTED | Wave 18 | 6-digit email OTP |
| Session restore | global | Supabase session | — | all | SplashPage | Supabase | IMPLEMENTED | | |
| Logout | settings / profile | Supabase signOut | — | all | ProfilePage | Supabase | IMPLEMENTED | | |
| Email verification gate | `/auth/pending` etc. | Supabase | — | all | Signup info + AuthPendingPage | — | IMPLEMENTED | Wave 17 | Confirm-email message + portal pending screen |
| Role detection | useAuth / portals | `user_roles` | `user_roles`, `profiles.active_portal` | all | ProfilePage /me + PortalHomePage | `GET /me` | IMPLEMENTED | Wave 17 | Roles + pending apps + portal switch |
| Portal application pending | `/auth/pending` | portal_applications | `portal_applications` | landlord/agency/manager | AuthPendingPage + PortalHomePage | `GET /me/portal-status` + `POST /me/portal-apply` | IMPLEMENTED | Wave 13/17 | Apply + status on Portals + pending route |
| Role switcher | SiteNav RoleSwitcher | active_portal | `profiles` | multi-role | PortalHomePage + Profile | `POST /me/active-portal` | IMPLEMENTED | Wave 2/17 | Cards by role → switch + navigate; Profile shortcut |

---

## 2. Public / marketing

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Landing / featured | `/` | listings query | `properties` | public | HomePage | `GET /listings` | IMPLEMENTED | | Native product home (not marketing clone) |
| About | `/about` | static | — | public | SiteContentPage | in-app WebView | IMPLEMENTED | Wave 19 | |
| Contact | `/contact` | form/email | — | public | ContactPage | `POST /contact` | IMPLEMENTED | Wave 19 | |
| Pricing page | `/pricing` | plans catalog | — | public | PlusPage / LandlordPlanPage / BoostPage | `GET /subscriptions/catalog` | IMPLEMENTED | Wave 14/17 | Catalog surfaces cover mobile pricing needs |
| Advertise packages | `/advertise`, `/advertise/pay` | advertise payment fns | invoices | public | AdvertisePage | `/advertise/*` | IMPLEMENTED | Wave 19 | |
| Finance / insurance / reports marketing | `/finance`, `/insurance`, `/reports` | static | — | public | SiteContentPage | in-app WebView | IMPLEMENTED | Wave 19 | |
| WhatsApp agent landing | `/whatsapp` | static | — | public | SiteContentPage | in-app WebView | IMPLEMENTED | Wave 19 | |
| Referrals | `/referrals` | referral fns | referral tables | auth | ReferralsPage | `GET /referrals/me` | IMPLEMENTED | Wave 18 | Code + list; resolve public |
| Legal policies | `/privacy`, `/terms-of-service`, … | static | — | public | SiteContentPage | in-app WebView | IMPLEMENTED | Wave 19 | |

---

## 3. Tenant marketplace

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Browse / search | `/tenant/` | queryListings | `properties` | public/tenant | HomePage, SearchPage | `GET /listings` | IMPLEMENTED | | Pagination + filters |
| Advanced filters | `/tenant/` | listings-core | `properties` | public | SearchPage | `GET /listings` | IMPLEMENTED | Wave 19 | Core filters match web bar (rent/type/beds/verified); no amenity-array filter on web either |
| Property categories / types | `/tenant/` | propertyTypeSchema | `properties` | public | SearchPage | `GET /listings` | IMPLEMENTED | | |
| Property detail | `/tenant/property/$id` | listing detail | `properties` | public | PropertyDetailPage | `GET /listings/:id` | IMPLEMENTED | | |
| Image gallery | detail | storage signed URLs | storage | public | PropertyDetailPage | listings payload | IMPLEMENTED | | |
| Video playback | detail | video_url | `properties` | public | PropertyDetailPage | listings payload | IMPLEMENTED | Wave 19 | Opens walkthrough URL |
| Map browse | `/tenant/map` | listings + Mapbox | `properties` | public | MapPage | `/listings` + `/api/mapbox-token` | IMPLEMENTED | mapbox_maps_flutter | 3D fill-extrusion + terrain + markers |
| Current location | map | geolocation | — | public | MapPage | — | IMPLEMENTED | permissions | |
| Saved properties | `/tenant/saved` | favorites | saved/favorites | tenant | SavedPage | `GET/PUT/DELETE /saved` | IMPLEMENTED | | |
| Compare homes | `/tenant/compare` | client | — | tenant | ComparePage | `POST /listings/compare` | IMPLEMENTED | Wave 19 | Local IDs + BFF compare |
| Property share / deep link | detail | URLs | — | public | App Links + share | `/tenant/property/:id` | IMPLEMENTED | Wave 18 | Share sheet + Android App Links |
| Contact unlock state | detail | getListingUnlockStateCore | `contact_unlocks` | tenant | ContactUnlockCard | `GET /unlock/:id` | IMPLEMENTED | | |
| Contact unlock free (Plus/trial) | detail | unlockListingContactCore | `contact_unlocks`, profiles | tenant | ContactUnlockCard | `POST /unlock/:id` | IMPLEMENTED | | |
| Contact unlock M-Pesa STK | detail | initiatePaymentCore Daraja | `payments` | tenant | ContactUnlockCard | `POST /unlock/:id` + `GET /payments/:id` | IMPLEMENTED | | |
| Contact unlock card (Pesapal) | detail | Pesapal | `payments` | tenant | ContactUnlockCard | `POST /unlock/:id` method=card | IMPLEMENTED | Wave 11 | Opens Pesapal redirectUrl; polls payment |
| Reviews list | detail | review fns | reviews | public | ReviewsSection | `GET /listings/:id/reviews` | IMPLEMENTED | Wave 17 | List + leave-review CTA |
| Leave review | `/tenant/review/$propertyId` | review create | reviews | tenant | LeaveReviewPage | `POST /reviews` + eligibility GET | IMPLEMENTED | Wave 6/17 | Occupancy preflight + book-viewing web CTA |
| Recommendations / alerts | tenant UX | saved-search entitlements | | tenant | SavedSearchesPage | `GET/POST /saved-searches` | IMPLEMENTED | Wave 19 | Plus-gated alerts |
| Tenant Plus checkout | `/tenant/checkout` | initiatePayment tenant_plus | `subscriptions` | tenant | PlusPage | `GET /subscriptions/catalog` + `POST /subscriptions/checkout` | IMPLEMENTED | Wave 12 | M-Pesa STK + Pesapal card |
| Messaging threads | `/tenant/messages` | conversation fns | messages | tenant | MessagesPage | `GET /messages` + `POST /messages` | IMPLEMENTED | Wave 11 | List + create inquiry from detail |
| Message thread | `/tenant/messages/$id` | send/list | messages | tenant | MessageThreadPage | `GET/POST /messages/:id` | IMPLEMENTED | Wave 4 | Send + thread UI |
| Create inquiry (Plus) | property detail | createInquiry | messages | tenant | MessageLandlordCard | `POST /messages` | IMPLEMENTED | Wave 11 | Plus-gated; opens thread |
| Tenant profile | `/tenant/profile` | profiles | `profiles` | tenant | ProfilePage | `GET /me` + `PATCH /me/profile` | IMPLEMENTED | Wave 12 | Edit name/phone |
| Notifications inbox | `/notifications` | notifications.functions | `notifications` | auth | NotificationsPage | `GET /notifications` + prefs | IMPLEMENTED | Wave 12 | List + mark read + prefs toggles |
| Settings | `/settings` | prefs | notification_preferences | auth | NotificationsPage prefs | `GET/PATCH /notifications/prefs` | IMPLEMENTED | Wave 12 | Prefs on notifications screen |

---

## 4. Tenant property-management (as resident)

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Rent / invoices list | `/tenant/rent` | listTenantPmInvoices | `pm_rent_invoices` | tenant | RentPage | `GET /tenants/rent/invoices` | IMPLEMENTED | Wave 1/18 | Access empty states + invoice list |
| Pay rent M-Pesa (IntaSend) | `/tenant/rent` | payPmRent | `pm_rent_payments`, payments | tenant | RentPage | `POST /tenants/rent/pay` | IMPLEMENTED | Wave 1/18 | STK + payment poll (+ SMS claim) |
| Submit rent from SMS claim | rent | submitPmRentFromSms / claims | `pm_rent_payment_claims` | tenant | RentPage | `POST /tenants/rent/sms-claim` | IMPLEMENTED | Wave 16 | Paste full M-Pesa SMS |
| Maintenance requests | `/tenant/maintenance` | pm-tenant-maintenance | `pm_maintenance_requests` | tenant | MaintenancePage | `GET/POST /tenants/maintenance` + confirm | IMPLEMENTED | Wave 16 | List + create + confirm/reopen |
| Complaints | `/tenant/complaints` | pm-complaints | `pm_complaints` | tenant | ComplaintsPage | `GET/POST /tenants/complaints` | IMPLEMENTED | Wave 6 | List + create |
| Accept tenancy invite | `/tenant/invite/$token` | invite accept | pm_tenants / leases | tenant | TenantInvitePage | `GET/POST /tenants/invites/:token` | IMPLEMENTED | Wave 12 | App Link mapped; accept → `/rent` |

---

## 5. Landlord portal

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Portal entry / apply | `/landlord/` | portal_applications | portal_applications | public→landlord | PortalHomePage | `/me/portal-status` + apply | IMPLEMENTED | Wave 13 | Apply card + status |
| Dashboard home | `/landlord/dashboard/` | portal analytics lite | properties | landlord | LandlordDashboardPage | `GET /landlords/dashboard` | IMPLEMENTED | Wave 13 | Stats + shortcuts |
| Plan | `/landlord/dashboard/plan` | entitlements | subscriptions | landlord | LandlordPlanPage | `GET /subscriptions/current` + checkout | IMPLEMENTED | Wave 14 | Pro/Premium M-Pesa + card |
| Billing | `/landlord/dashboard/billing` | listTransactions | payments | landlord | BillingPage | `GET /payments` | IMPLEMENTED | Wave 13 | Shared payment history |
| Payouts settings | `/landlord/dashboard/payouts` | pm-payout | pm_payout_destinations | landlord | PayoutSettingsPage | `GET/POST /landlords/payouts` | IMPLEMENTED | Wave 15 | M-Pesa phone/till/paybill + OTP |
| Checkout / upgrade | `/landlord/checkout` | initiatePayment landlord_plan | subscriptions | landlord | LandlordPlanPage | `POST /subscriptions/checkout` | IMPLEMENTED | Wave 14 | landlord_plan |
| Properties list | `/landlord/properties/` | property list fns | properties | landlord | MyListingsPage | `GET /properties` | IMPLEMENTED | Wave 2–4 | FAB → create; tap → edit |
| Create listing | `/landlord/properties/new` | create property | properties | landlord | CreateListingPage | `POST /properties` | IMPLEMENTED | Wave 4/17 | Title/type/rent/desc/amenities; media via edit |
| Edit listing | `/landlord/properties/$id/edit` | update | properties | landlord | EditListingPage | `PATCH /properties/:id` | IMPLEMENTED | Wave 6/17 | Core fields + beds/baths/deposit/video/amenities + publish |
| Deactivate / publish | properties UI | update flags | properties | landlord | EditListingPage | `PATCH /properties/:id` | IMPLEMENTED | Wave 6 | is_active / is_vacant toggles |
| Media upload | edit form | storage | storage buckets | landlord | EditListingPage | `POST .../media` (+ upload-urls) | IMPLEMENTED | Wave 8 | Gallery picker + signed upload; URL attach also |
| Bulk import | `/landlord/import` | CSV import | properties | landlord | ListingImportPage | `POST /listings/import/*` | IMPLEMENTED | Wave 19 | |
| Integrations | `/landlord/integrations` | API keys | — | landlord | IntegrationsPage | `/integrations/keys*` | IMPLEMENTED | Wave 19 | |
| Leads / messages | `/landlord/leads` | conversations | messages | landlord | MessagesPage | `GET /messages` | IMPLEMENTED | Wave 4/18 | Shared messages inbox (lead packs separate) |
| Caretakers manage | `/landlord/caretakers` | caretaker fns | caretakers | landlord | CaretakersManagePage | `GET/POST /caretakers` | IMPLEMENTED | Wave 15 | Create, PIN regen, revoke |
| Analytics | `/landlord/analytics` | analytics | — | landlord | LandlordAnalyticsPage | `GET /landlords/analytics` | IMPLEMENTED | Wave 19 | Views + leads |
| Boost packages | `/landlord/boost` | property_boost payment | payments | landlord | BoostPage | `POST /subscriptions/checkout` | IMPLEMENTED | Wave 14 | property_boost + listing picker |
| PM suite (see §8) | `/landlord/manage/**` | pm.functions | pm_* | landlord | PmListPage / PmPropertyPage | `/property-management/*` | IMPLEMENTED | Wave 5/18 | List + property tabs + KPIs/edit/invite/generate |

---

## 6. Agency portal

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Agency dashboard suite | `/agency/dashboard/**` | same Portal* as landlord | | agency | AgencyDashboardPage | `GET /agencies/dashboard` | IMPLEMENTED | Wave 18/16 | Shortcuts incl. analytics (shared landlord analytics) |
| Team members | `/agency/team` | org membership | org tables | agency owner | OrgTeamPage | `GET/POST /org/team` | IMPLEMENTED | Wave 18 | Invite / approve / revoke |
| Properties / PM / checkout / leads / … | `/agency/**` | portal paths | | agency | — | shared property + PM BFF | IMPLEMENTED | Wave 18 | Via agency dashboard shortcuts; import/integrations Wave 19 |

---

## 7. Manager portal

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Manager dashboard suite | `/manager/**` | Portal* | | manager | ManagerDashboardPage | `GET /managers/dashboard` | IMPLEMENTED | Wave 18/16 | Includes team + analytics shortcut |
| PM suite | `/manager/manage/**` | pm.functions | pm_* | manager | PmListPage / PmPropertyPage | `/property-management/*` | IMPLEMENTED | Wave 5/18 | Shared with landlord |

---

## 8. Property management (shared)

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Managed properties list | `/*/manage/` | list PM properties | `pm_properties` | landlord/agency/manager | PmListPage | `GET /property-management/properties` | IMPLEMENTED | Wave 5/18 | FAB + subscribe CTA |
| Add managed property | `/*/manage/new` | create | `pm_properties` | | PmCreatePage | `POST /property-management/properties` | IMPLEMENTED | Wave 14 | Requires PM module |
| PM module subscribe | `/*/manage/subscribe` | subscribePropertyManagement | subscriptions / pm | | PmSubscribePage | `POST /subscriptions/pm-module` + checkout | IMPLEMENTED | Wave 14 | Trial or pay recommended tier |
| Property overview | `/*/manage/$id/` | dashboard | pm_* | | PmPropertyPage | `GET .../properties/:id` + `/dashboard` | IMPLEMENTED | Wave 5/18 | Overview KPIs |
| Units | `.../units` | units CRUD | `pm_units`, buildings | | PmPropertyPage | `.../units` + `PATCH .../units/:id` | IMPLEMENTED | Wave 8/18 | Horizontal DataTable (Unit/Status/Rent/Beds) — columns kept |
| Tenants | `.../tenants` | tenants/leases | `pm_tenants`, `pm_leases` | | PmPropertyPage | `.../tenants` + invite | IMPLEMENTED | Wave 9/18 | Horizontal DataTable (Tenant/Phone/Email/Portal) — columns kept |
| Rent / invoices | `.../rent` | invoices + record payment | `pm_rent_invoices`, payments | | PmPropertyPage Rent tab | `GET/POST .../rent` + generate | IMPLEMENTED | Wave 10/18 | Horizontal DataTable (Period/Unit/Status/Due/Paid) |
| Maintenance | `.../maintenance` | pm-maintenance | `pm_maintenance_requests` | | PmPropertyPage | `GET .../maintenance` + `PATCH .../maintenance/:id` | IMPLEMENTED | Wave 16 | List + Start / Mark completed |
| Complaints | `.../complaints` | pm-complaints | `pm_complaints` | | PmPropertyPage Complaints tab | `GET .../complaints` + reply/seen | IMPLEMENTED | Wave 17 | Reply + mark seen |
| Staff permissions | staff UI | pm/permissions | `pm_property_staff` | | PmPropertyPage Staff tab | `GET/POST .../staff` | IMPLEMENTED | Wave 17 | Owner upsert by email |
| Payout batches / fees | dashboard payouts | pm-payout | payout tables | | PayoutSettingsPage | `GET /landlords/payouts/batches` | IMPLEMENTED | Wave 17/18 | Batch list (matches web) |

---

## 9. Caretaker

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| PIN sign-in | `/caretaker/` | caretaker session | caretaker credentials | caretaker | CaretakerLoginPage | `POST /caretakers/session` | IMPLEMENTED | Wave 14 | Persists token → dashboard |
| Dashboard | `/caretaker/dashboard` | assigned properties | pm / caretaker assign | caretaker | CaretakerDashboardPage | `GET /caretakers/dashboard` + vacancy PATCH | IMPLEMENTED | Wave 14 | Vacancy toggle |

---

## 10. Service providers

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Directory home | `/services/` | listActiveProvidersByCategory | `service_providers` | public | ProvidersPage | `GET /providers` | IMPLEMENTED | Wave 7/18 | List + category filter + detail |
| Category browse | `/services/$category` | same | | public | ProvidersPage chips | `GET /providers?category=` | IMPLEMENTED | Wave 17 | Horizontal category filter |
| Provider profile | `/services/provider/$id` | getProviderById | | public | ProviderDetailPage | `GET /providers/:id` | IMPLEMENTED | Wave 18 | Call + WhatsApp actions |
| Provider register | `/services/register` | createServiceProvider | | auth | ProviderRegisterPage | `POST /providers` | IMPLEMENTED | Wave 17 | Pending approval |
| Provider profile edit | `/services/provider/dashboard` | updateServiceProviderProfile | | provider | ProviderRegisterPage (Edit) | `PATCH /providers/me` | IMPLEMENTED | Wave 13 | Uses PATCH when profile exists |
| Provider dashboard | `/services/provider/dashboard` | getProviderDashboard | | provider | ProviderMePage | `GET /providers/me` | IMPLEMENTED | Wave 17 | Profile + inquiries |
| Provider subscription | dashboard | provider_subscription pay | | provider | ProviderMePage | `POST /subscriptions/checkout` | IMPLEMENTED | Wave 19 | Featured/Premium M-Pesa |
| Admin create provider | `/admin/providers/new` | adminCreateServiceProvider | | admin | AdminCreateProviderPage | `POST /admin/service-providers/create` | IMPLEMENTED | Wave 19 | |

---

## 11. Payments (cross-cutting)

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Initiate M-Pesa (Daraja) non-rent | checkout / unlock | initiatePaymentCore | `payments` | auth | Unlock + PlusPage + checkout | `POST /unlock` + `POST /subscriptions/checkout` + `POST /payments/initiate` | IMPLEMENTED | Wave 4/17 | Shared initiate alias |
| Initiate rent (IntaSend) | tenant rent / PM | startRentIntasendStk | `payments` | tenant/PM | RentPage | `POST /tenants/rent/pay` | IMPLEMENTED | | STK + poll |
| Card (Pesapal) | checkout | Pesapal | `payments` | auth | Unlock + plan checkouts | `POST /unlock/:id` + checkout/initiate method=card | IMPLEMENTED | Wave 11/17 | Unlock + subscription card paths |
| Payment status poll | various | verifyPaymentStatus / BFF | `payments` | auth | STK dialog | `GET /payments/:id` | IMPLEMENTED | unlock | Reuse for all types |
| Webhooks | Worker routes | webhook-handlers | | system | — | unchanged | IMPLEMENTED | | Do not change semantics |
| Fulfillment | revenue/fulfill-payment | by payment_type | various | system | — | server-side | IMPLEMENTED | | Flutter never fulfills |

---

## 12. Subscriptions & monetization

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Plan catalog | `/pricing` | plans.ts | — | public | PlusPage / LandlordPlanPage / BoostPage | `GET /subscriptions/catalog` | IMPLEMENTED | Wave 14 | Plus + landlord + boost packages |
| Current entitlements | dashboards | entitlements.ts | subscriptions, profiles | auth | PlusPage + ProfilePage | `GET /subscriptions/current` | IMPLEMENTED | Wave 12 | Plus badge + trial info |
| Upgrade / renew | checkout | initiatePayment | | auth | PlusPage | `POST /subscriptions/checkout` | IMPLEMENTED | Wave 12 | STK + card |
| Lead packs | portal | lead_pack | | landlord+ | LeadPacksPage | `POST /subscriptions/checkout` | IMPLEMENTED | Wave 15 | qty packs from catalog |
| PM module plans | manage/subscribe | pm-module | | PM portals | PmSubscribePage | `POST /subscriptions/pm-module` + checkout | IMPLEMENTED | Wave 14 | Trial or pay |
| Renewal cron | Worker | subscription-renewals | | system | — | — | IMPLEMENTED | website | No Flutter change |

---

## 13. Verification & authenticity

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Verification marketing | `/verify/` | static | — | public | VerifyRequestPage | verification BFF | IMPLEMENTED | | Product verify flow |
| Submit verification request | `/verify/request` | createVerificationRequest | `verification_requests` | auth | VerifyRequestPage | `POST /verification/requests` + `/pay` | IMPLEMENTED | Wave 13 | Create + M-Pesa/card pay |
| Request status | `/verify/status/$id` | getVerificationRequest | | auth | VerifyStatusPage | `GET /verification/requests/:id` | IMPLEMENTED | Wave 8/18 | Status + pay path |
| Listing verified badge | detail | properties flags | properties | public | PropertyDetailPage | listings payload | IMPLEMENTED | | Display only |
| Admin verification queues | `/admin?tab=verifications` | listAdminVerifications | `verifications` | admin | AdminIdentityVerificationsPage + AdminVerificationsPage | `GET/PATCH /admin/verifications` + `/admin/verification-requests` | IMPLEMENTED | Wave 10/18 | Identity + paid request queues |
| Admin property checks | `property_checks` tab | verification_requests admin | | admin | AdminVerificationsPage | `GET/PATCH /admin/verification-requests` | IMPLEMENTED | Wave 10/19 | Same queue as paid requests |
| Authenticity score adjust | admin properties | authenticity column | properties | admin | AdminListingsPage | `PATCH /admin/properties/:id/authenticity` | IMPLEMENTED | Wave 17 | ±5 nudge; display Trust chip on detail |
| Scam reports | scams tab | scam report fns | | admin | AdminScamReportsPage | `GET/PATCH /admin/scam-reports` | IMPLEMENTED | Wave 16 | reviewed / dismissed |

---

## 14. Admin (mobile-appropriate)

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Admin console shell | `/admin/` | require admin role | user_roles | admin | AdminHomePage | `GET /admin/summary` | IMPLEMENTED | Wave 16/18 | Counts + queue links |
| Portal applications | applications tab | approve portal apps | portal_applications | admin | AdminPortalApplicationsPage | `GET/POST /admin/portal-applications` | IMPLEMENTED | Wave 16 | Approve / reject |
| Pending providers | providers tab | reviewServiceProvider | service_providers | admin | AdminPendingProvidersPage | `GET/POST /admin/service-providers` | IMPLEMENTED | Wave 16 | Approve / reject |
| Listing moderation | properties tab | admin listing fns | properties | admin | AdminListingsPage | `GET/POST /admin/properties` | IMPLEMENTED | Wave 17 | Activate / deactivate |
| Create listing as admin | `/admin/listings/new` | admin create | properties | admin | AdminCreateListingPage | `POST /admin/properties` | IMPLEMENTED | Wave 19 | |
| Revenue / finance views | `/admin/revenue`, revenue tab | aggregates | payments | admin | AdminRevenuePage | `GET /admin/revenue` | IMPLEMENTED | Wave 19 | Stacked 6-mo bar chart + denser stats |
| Announcements / founding promo / advertise admin | admin tabs | various | | admin | AdminHomePage | admin BFF | IMPLEMENTED | Wave 20 | Device visual denseness → VERIFIED |
| PM oversight / payouts admin | admin tabs | pm-admin | pm_* | admin | AdminPmPage | `GET /admin/pm/overview` + dispute resolve | IMPLEMENTED | Wave 18 | Subs, disputes, reversals |

---

## 15. Notifications & push

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Register FCM token | native / web | registerFcmToken | `push_tokens`, profiles | auth | PushRegistrationHost | `POST /fcm-token` | IMPLEMENTED | Wave 20 | google-services.json fetched for nyumbasearch-b70a1; device QA for receive pending |
| List notifications | `/notifications` | list notifications | `notifications` | auth | NotificationsPage | `GET /notifications` | IMPLEMENTED | Wave 12 | Mark-read + prefs |
| Mark read / prefs | settings | prefs fns | notification_preferences | auth | NotificationsPage | `GET/PATCH /notifications/prefs` | IMPLEMENTED | Wave 12 | Prefs panel |
| Push send (events) | server | push-send.ts | | system | — | existing | NOT APPLICABLE TO MOBILE | env flag | Server-only; Flutter registers token via BFF |

---

## 16. Maps & search (platform)

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Mapbox token | map | `/api/mapbox-token` | — | public | MapPage | existing Worker route | IMPLEMENTED | | |
| Marker clustering | map | client | — | public | MapPage | — | IMPLEMENTED | Wave 19 | Grid clusters + zoom expand |
| Map/list sync | map | client | — | public | MapPage | — | IMPLEMENTED | Wave 19 | Preview → detail |

---

## 17. Deep links & identity

| FEATURE | WEBSITE LOCATION | BACKEND FUNCTION | DATABASE TABLES | USER ROLE | FLUTTER SCREEN | FLUTTER API/BFF ENDPOINT | STATUS | DEPENDENCIES | NOTES |
|---------|------------------|------------------|-----------------|-----------|----------------|--------------------------|--------|--------------|-------|
| Android App Links property | `/tenant/property/:id` | assetlinks.json | — | public | PropertyDetailPage | deep_links.dart | IMPLEMENTED | package ID | |
| App Links search/map/tenant | paths | assetlinks | — | public | router | | IMPLEMENTED | Wave 19 | Expanded deep_links (agency/manager/admin/services/rent/verify/…) |
| Visual parity (tenant chrome) | tenant UI | styles.css | — | public | AppTheme + HomeShell + PropertyCard + detail/auth/map | — | IMPLEMENTED | Wave 20 | Syne/Manrope, green tokens, dark-first, floating nav, immersive gallery, intel chips, branded AppBars |
| iOS Universal Links | same URLs | apple-app-site-association | — | public | Runner.entitlements | `/.well-known/apple-app-site-association` | PARTIAL | Wave 19 | Reads `APPLE_TEAM_ID` env; placeholder `TEAMID` until set |
| Play package ID | — | — | — | — | ke.co.nyumbasearch.app | — | IMPLEMENTED | | Do not change |
| Signed AAB | — | keystore | — | — | release build | — | IMPLEMENTED | C:\secure\… | |

---

## Summary counts (seed)

| STATUS | Approx. rows |
|--------|----------------|
| IMPLEMENTED | majority of mobile-appropriate rows (Waves 1–19) |
| PARTIAL / TESTING | Google OAuth device QA (callback route ready; confirm redirect allowlist on device), iOS `APPLE_TEAM_ID` (deferred) |
| NOT STARTED | none critical for mobile MVP |
| BLOCKED (documented) | — |
| DEFERRED | `APPLE_TEAM_ID` (neglected for now) |

**Parity gate:** Every inventory row must reach `VERIFIED` (or `BLOCKED` with template). WebView stays until Section 26 gate is signed off.

**Device QA:** run `dart run tool/device_qa_checklist.dart` and complete on real devices before cutover.
