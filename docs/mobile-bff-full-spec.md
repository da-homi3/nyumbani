# Mobile BFF — full feature specification

**Base:** `https://nyumbasearch.com/api/mobile/v1`  
**Headers:** `X-App-Client: flutter` (required on every route); `Authorization: Bearer <supabase_access_token>` when noted.  
**Principle:** Wrap existing cores / `createServerFn` logic. Do not duplicate business rules.  
**apiVersion:** every JSON body includes `"apiVersion": "v1"`.

> **Contract of record (shipped):** see [flutter-api-contracts.md](./flutter-api-contracts.md) for the complete Core + Waves 1–18 endpoint table (synced 2026-08-08). This document keeps principles + payments + open gaps.

## Status

| Area | State |
|------|--------|
| Core tenant MVP | Shipped |
| Waves 1–18 | Shipped in `src/lib/api/mobile/v1/wave*.ts` |
| Wave 19 | Shipped in `wave19.ts` — contact, advertise, CSV import, integrations keys, admin revenue |
| Wave 20 | Shipped in `wave20.ts` — admin announcements, founding promo, advertise review |
| Former WEB_FALLBACK product gaps | Closed in Waves 19–20 (no intentional BFF omit) |

## Auth

1. Reject missing/invalid `X-App-Client: flutter` with `403 APP_CLIENT_REQUIRED`.
2. Bearer via Supabase `getUser(jwt)`.
3. Role checks via `user_roles` / portal helpers / `requireAdmin`.
4. Caretaker: PIN → session; subsequent calls use `X-Caretaker-Token`.

## Payments (do not change)

| Flow | Provider | BFF |
|------|----------|-----|
| Rent | IntaSend | `POST /tenants/rent/pay` |
| Unlock / Plus / boost / leads / verification M-Pesa | Daraja STK | unlock / checkout / initiate |
| Card | Pesapal | `method=card` → redirect + poll `GET /payments/:id` |

Secrets stay in Worker env only.

## Open optional endpoints

| Endpoint | Why |
|----------|-----|
| Book viewings CRUD | Optional — leave-review uses viewings read-only today |
| `/favorites` alias | Cosmetic; `/saved` works |

`PATCH /providers/me` — **shipped** (wave 13) alongside Flutter `patchProviderMe`.

## Wave 19 endpoints

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/contact` | Public | Rate-limited; CF Email to ops |
| GET | `/advertise/packages` | Public | Package catalog |
| POST | `/advertise/inquiries` | Public | Creates inquiry row |
| POST | `/advertise/pay` | Bearer | initiate-payment-core (invoice) |
| POST | `/listings/import/preview` | Bearer + portal | CSV parse |
| POST | `/listings/import/execute` | Bearer + portal | Insert listings |
| GET | `/integrations/keys` | Bearer + portal | List keys |
| POST | `/integrations/keys` | Bearer + portal | Create key |
| POST | `/integrations/keys/:id/revoke` | Bearer + portal | Revoke |
| GET | `/admin/revenue` | Bearer + admin | Revenue summary |

Implementation: `src/lib/api/mobile/v1/wave19.ts`.

## Wave 20 endpoints

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/admin/announcements` | Bearer + admin | Product announcement broadcast |
| GET | `/admin/promo` | Bearer + admin | Founding promo dashboard |
| GET | `/admin/advertise` | Bearer + admin | Advertise inquiry queue |
| POST | `/admin/advertise/approve` | Bearer + admin | Approve + payment link email |

Implementation: `src/lib/api/mobile/v1/wave20.ts`.

## Website regression

After every BFF deploy, verify website: home, auth, search, detail, landlord, PM rent, unlock payments.
