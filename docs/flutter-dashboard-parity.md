# Flutter dashboard parity

**Rule:** Every website dashboard chrome + nested page must exist in Flutter with the same capabilities. Website SoT: `find-nyumba-smart/src/components/dashboard/**`, portal shells, admin, caretaker, PM pages.

**STATUS:** NOT STARTED | IN DEVELOPMENT | IMPLEMENTED | TESTING | VERIFIED | BLOCKED

## Shells / chrome

| Role | Website | Flutter | STATUS | Notes |
|------|---------|---------|--------|-------|
| Landlord | `LandlordShell` + `PortalMobileHeader` + `RoleSwitcher` + `NotificationBell` | Landlord dashboard + `SiteTopBar` + portals | IMPLEMENTED | Dense 2-col metrics + quick actions |
| Agency | `AgencyShell` | `AgencyDashboardPage` + route aliases | IMPLEMENTED | Import/integrations nav (Wave 19) |
| Manager | `ManagerShell` | `ManagerDashboardPage` + aliases | IMPLEMENTED | Same as agency |
| Admin | `routes/admin.tsx` tabs | `AdminHomePage` + queue pages | IMPLEMENTED | Revenue tab (Wave 19) |
| Caretaker | `caretaker.dashboard` | `CaretakerDashboardPage` | IMPLEMENTED | |
| Provider | `services.provider.dashboard` | `ProviderMePage` | IMPLEMENTED | |
| Tenant | `TenantBottomNav` | `HomeShell` bottom nav | VERIFIED (layout) | Visual QA ongoing |

## Nested dashboard pages

| Surface | Web routes | Flutter | STATUS |
|---------|------------|---------|--------|
| Overview stats | `*/dashboard/` | Landlord/Agency/Manager dashboards | IMPLEMENTED |
| Billing | `*/dashboard/billing` | `/billing` | IMPLEMENTED |
| Plan | `*/dashboard/plan` | `/landlord/plan` | IMPLEMENTED |
| Payouts | `*/dashboard/payouts` | `/landlord/payouts` | IMPLEMENTED |
| Analytics charts | `*/analytics` | `LandlordAnalyticsPage` | IMPLEMENTED |
| Listings CRUD | `*/properties/*` | `/landlord/listings*` | IMPLEMENTED |
| Leads | `*/leads` | `/landlord/leads` | IMPLEMENTED |
| Caretakers | `*/caretakers` | `/landlord/caretakers` | IMPLEMENTED |
| Team | agency/manager `/team` | `OrgTeamPage` | IMPLEMENTED |
| Boost | landlord `/boost` | `/landlord/boost` | IMPLEMENTED |
| CSV import | `*/import` | `ListingImportPage` (`/landlord|/agency|/manager/import`) | IMPLEMENTED |
| Integrations | `*/integrations` | `IntegrationsPage` | IMPLEMENTED |
| PM list/new/subscribe | `*/manage/**` | `/pm*` | IMPLEMENTED |
| PM units/tenants/rent/maint/complaints | multi-page | `PmPropertyPage` tabs | IMPLEMENTED | All tabs DataTables |
| Admin queues | admin tabs | `/admin/*` | IMPLEMENTED |
| Admin revenue | `/admin/revenue` | `AdminRevenuePage` | IMPLEMENTED |
| Admin announce | admin announcements tab | `AdminAnnouncementsPage` | IMPLEMENTED |
| Admin founding promo | founding_promo tab | `AdminPromoPage` | IMPLEMENTED |
| Admin advertise review | advertise tab | `AdminAdvertisePage` | IMPLEMENTED |

## Charts

| Website | Flutter | STATUS |
|---------|---------|--------|
| `AnalyticsChart` / Recharts | Landlord analytics charts | IMPLEMENTED |
| `AdminAnalyticsTab` | Admin home summary | IMPLEMENTED — dense metric grid + queue chips |
| Admin revenue charts | `AdminRevenuePage` stacked bar CustomPainter | IMPLEMENTED |

## Empty / loading / error / confirm

All portal screens must use shared Flutter `AsyncBody` / snackbars matching website empty/error copy. STATUS: IMPLEMENTED (`EmptyState` + AsyncScaffoldBody error).
