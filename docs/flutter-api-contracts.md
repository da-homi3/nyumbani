# Flutter Mobile BFF — API contracts

**Base URL:** `https://nyumbasearch.com/api/mobile/v1`  
**Required header (all routes):** `X-App-Client: flutter`  
**JSON:** every success body includes `"apiVersion": "v1"`.  
**Errors:** `{ "error", "code", "status" }`.

Auth legend:
- **Public** = flutter client header only  
- **Bearer** = `Authorization: Bearer <supabase_access_token>`  
- **Roles** as noted (tenant / portal / admin / caretaker token)

## Gaps vs website (optional follow-ups)

| Missing | Notes |
|---------|-------|
| `/favorites` alias | Use `/saved` |
| Book viewings CRUD | Leave-review eligibility reads viewings; no create BFF |

## Wave 19 (shipped)

| Wave | Method | Path | Auth notes |
|------|--------|------|------------|
| 19 | POST | `/contact` | Public (rate-limited) |
| 19 | GET | `/advertise/packages` | Public |
| 19 | POST | `/advertise/inquiries` | Public |
| 19 | POST | `/advertise/pay` | Bearer |
| 19 | POST | `/listings/import/preview` | Bearer + portal |
| 19 | POST | `/listings/import/execute` | Bearer + portal |
| 19 | GET | `/integrations/keys` | Bearer + portal |
| 19 | POST | `/integrations/keys` | Bearer + portal |
| 19 | POST | `/integrations/keys/:id/revoke` | Bearer + portal |
| 19 | GET | `/admin/revenue` | Bearer + admin |

## Wave 20 (shipped)

| Wave | Method | Path | Auth notes |
|------|--------|------|------------|
| 20 | POST | `/admin/announcements` | Bearer + admin |
| 20 | GET | `/admin/promo` | Bearer + admin |
| 20 | GET | `/admin/advertise` | Bearer + admin |
| 20 | POST | `/admin/advertise/approve` | Bearer + admin |

## Shipped endpoints (Core + Waves 1–18)

Base: `/api/mobile/v1` · All routes require `X-App-Client: flutter`

| Wave | Method | Path | Auth notes |
|------|--------|------|------------|
| Core | GET | `/health` | Public |
| Core | GET | `/me` | Bearer |
| Core | GET | `/listings` | Public |
| Core | GET | `/listings/:id` | Public |
| Core | GET | `/saved` | Bearer + tenant role |
| Core | PUT | `/saved/:id` | Bearer + tenant role |
| Core | DELETE | `/saved/:id` | Bearer + tenant role |
| Core | GET | `/unlock/:id` | Bearer |
| Core | POST | `/unlock/:id` | Bearer |
| Core | GET | `/payments/:id` | Bearer |
| Core | POST | `/fcm-token` | Bearer |
| 1 | GET | `/notifications` | Bearer |
| 1 | POST | `/notifications/read` | Bearer |
| 1 | GET | `/notifications/unread-count` | Bearer |
| 1 | GET | `/subscriptions/catalog` | Public |
| 1 | POST | `/reviews` | Bearer |
| 1 | GET | `/listings/:id/reviews` | Public |
| 1 | GET | `/tenants/rent/invoices` | Bearer |
| 1 | GET | `/tenants/rent/access` | Bearer |
| 1 | POST | `/tenants/rent/pay` | Bearer |
| 2 | GET | `/properties` | Bearer + lister |
| 2 | GET | `/properties/:id` | Bearer + owner/admin |
| 2 | PATCH | `/properties/:id` | Bearer + owner/admin |
| 2 | POST | `/me/active-portal` | Bearer |
| 2 | GET | `/property-management/properties` | Bearer + lister |
| 2 | GET | `/providers` | Public |
| 2 | GET | `/providers/:id` | Public |
| 2 | POST | `/caretakers/session` | Public (phone+PIN) |
| 2 | GET | `/admin/summary` | Bearer + admin |
| 3 | POST | `/subscriptions/checkout` | Bearer |
| 3 | POST | `/properties` | Bearer + lister/admin |
| 3 | GET/POST | `/messages` | Bearer |
| 3 | GET/POST | `/messages/:id` | Bearer + participant |
| 3 | GET | `/property-management/properties/:id` | Bearer + PM access |
| 3 | GET | `/property-management/properties/:id/units` | Bearer + PM access |
| 3 | GET | `/property-management/properties/:id/tenants` | Bearer + PM access |
| 3 | GET | `/property-management/properties/:id/maintenance` | Bearer + PM access |
| 4 | GET/POST | `/tenants/maintenance` | Bearer |
| 4 | GET/POST | `/tenants/complaints` | Bearer |
| 4 | POST | `/properties/:id/media/upload-urls` | Bearer + owner |
| 4 | POST | `/properties/:id/media` | Bearer + owner |
| 5 | POST | `/property-management/properties/:id/units` | Bearer + PM write |
| 5 | POST | `/property-management/properties/:id/tenants` | Bearer + PM write |
| 5 | POST | `/verification/requests` | Bearer |
| 5 | GET | `/verification/requests/:id` | Bearer |
| 6 | GET/PATCH | `/admin/verification-requests` (+ `/:id`) | Bearer + admin |
| 6 | GET/POST | `/property-management/properties/:id/leases` | Bearer + PM |
| 6 | GET | `/property-management/properties/:id/rent` | Bearer + PM |
| 7 | POST | `/property-management/properties/:id/rent/payments` | Bearer + PM |
| 7 | GET/PATCH | `/admin/verifications` (+ `/:id`) | Bearer + admin |
| 8 | GET | `/subscriptions/current` | Bearer |
| 8 | GET/PATCH | `/notifications/prefs` | Bearer |
| 8 | PATCH | `/me/profile` | Bearer |
| 8 | GET/POST | `/tenants/invites/:token` | Public GET / Bearer POST |
| 9 | GET | `/payments` | Bearer |
| 9 | GET | `/landlords/dashboard` | Bearer + portal |
| 9 | GET | `/me/portal-status` | Bearer |
| 9 | POST | `/me/portal-apply` | Bearer |
| 9 | POST | `/verification/requests/:id/pay` | Bearer |
| 10 | POST | `/property-management/properties` | Bearer + portal |
| 10 | POST | `/subscriptions/pm-module` | Bearer + portal |
| 10 | GET | `/caretakers/dashboard` | `X-Caretaker-Token` |
| 10 | PATCH | `/caretakers/properties/:id/vacancy` | `X-Caretaker-Token` |
| 10 | POST | `/auth/otp/request` | Public |
| 10 | POST | `/auth/otp/verify` | Public |
| 11 | GET/POST | `/caretakers` | Bearer + portal |
| 11 | POST | `/caretakers/:id/regenerate-pin` | Bearer + portal |
| 11 | POST | `/caretakers/:id/revoke` | Bearer + portal |
| 11 | GET/POST | `/landlords/payouts` | Bearer + portal |
| 11 | GET | `/landlords/payouts/batches` | Bearer + portal |
| 11 | POST | `/landlords/payouts/:id/deactivate` | Bearer + portal |
| 11 | POST | `/landlords/payouts/otp/request` | Bearer + portal |
| 11 | POST | `/landlords/payouts/otp/confirm` | Bearer + portal |
| 12 | GET | `/admin/portal-applications` | Bearer + admin |
| 12 | POST | `/admin/portal-applications/:id/review` | Bearer + admin |
| 12 | GET | `/admin/service-providers` | Bearer + admin |
| 12 | POST | `/admin/service-providers/:id/review` | Bearer + admin |
| 12 | GET/PATCH | `/admin/scam-reports` (+ `/:id`) | Bearer + admin |
| 12 | POST | `/tenants/rent/sms-claim` | Bearer |
| 13 | GET | `/providers/categories` | Public |
| 13 | GET | `/providers/me` | Bearer |
| 13 | PATCH | `/providers/me` | Bearer (edit existing profile) |
| 13 | POST | `/providers` | Bearer |
| 13 | GET | `/admin/properties` | Bearer + admin |
| 13 | POST | `/admin/properties/:id/active` | Bearer + admin |
| 13 | GET | `/property-management/properties/:id/complaints` | Bearer + PM |
| 13 | POST | `/property-management/complaints/:id/reply` | Bearer + PM |
| 13 | POST | `/property-management/complaints/:id/seen` | Bearer + PM |
| 13 | GET/POST | `/property-management/properties/:id/staff` | Bearer + PM |
| 14 | POST | `/auth/password-reset/request` | Public |
| 14 | POST | `/auth/password-reset/verify` | Public |
| 14 | POST | `/auth/password-reset/complete` | Public |
| 14 | GET | `/me/org-membership` | Bearer |
| 14 | GET/POST | `/org/team` | Bearer + agency/manager |
| 14 | POST | `/org/team/approve` | Bearer + org owner |
| 14 | POST | `/org/team/revoke` | Bearer + org owner |
| 14 | GET | `/agencies/dashboard` | Bearer + agency |
| 14 | GET | `/managers/dashboard` | Bearer + manager |
| 14 | GET | `/referrals/me` | Bearer |
| 14 | POST | `/referrals/resolve` | Public |
| 14 | GET | `/admin/pm/overview` | Bearer + admin |
| 14 | POST | `/admin/pm/disputes/:id/resolve` | Bearer + admin |
| 15 | GET | `/landlords/analytics` | Bearer + landlord/admin |
| 15 | POST | `/listings/compare` | Public |
| 15 | GET/POST | `/saved-searches` | Bearer |
| 15 | PATCH/DELETE | `/saved-searches/:id` | Bearer |
| 15 | POST | `/admin/service-providers/create` | Bearer + admin |
| 15 | POST | `/admin/properties` | Bearer + admin |
| 15 | POST | `/admin/properties/:id/verified` | Bearer + admin |
| 16 | PATCH | `/property-management/maintenance/:id` | Bearer + PM |
| 16 | POST | `/property-management/maintenance/:id/assign` | Bearer + PM |
| 16 | POST | `/tenants/maintenance/:id/confirm` | Bearer |
| 17 | GET | `/listings/:id/reviews/eligibility` | Bearer |
| 17 | PATCH | `/admin/properties/:id/authenticity` | Bearer + admin |
| 17 | POST | `/payments/initiate` | Bearer |
| 18 | GET | `/property-management/properties/:id/dashboard` | Bearer + PM |
| 18 | PATCH | `/property-management/units/:id` | Bearer + PM |
| 18 | POST | `/property-management/properties/:id/rent/generate` | Bearer + PM |
| 18 | POST | `/property-management/properties/:propertyId/tenants/:tenantId/invite` | Bearer + PM |

## Client conventions

- Flutter: `MobileApiClient` + `MobileApiRepository` in `flutter_app/lib/core/network/`.
- Strip null query params; listings may send `maxImages` (home uses `1`).
- Poll `GET /payments/:id` after STK / card redirect.
- Caretaker: store session token; send `X-Caretaker-Token`.

See [mobile-bff-full-spec.md](./mobile-bff-full-spec.md) for principles; this file is the **shipped** contract of record (synced 2026-08-11, Waves 1–20).
