# Flutter ↔ backend dependency map

Flutter never uses the Supabase service role or payment secrets. All protected product logic goes through the **Mobile BFF** (`/api/mobile/v1/*`) which wraps existing Worker cores.

**Companion docs:** [backend-dependency-map.md](./backend-dependency-map.md) (module table), [flutter-api-contracts.md](./flutter-api-contracts.md), [mobile-bff-full-spec.md](./mobile-bff-full-spec.md), [payment-flow-map.md](./payment-flow-map.md), [auth-role-map.md](./auth-role-map.md), [pm-flow-map.md](./pm-flow-map.md).

## Architecture

```
Flutter app
  → Dio MobileApiClient (X-App-Client: flutter + Bearer)
    → Cloudflare Worker /api/mobile/v1/*
      → listings-core / pm/* / payments/* / admin fns / …
        → Supabase (RLS or service role inside Worker only)
```

Website continues to use TanStack `createServerFn` paths unchanged. BFF is **additive**.

## Domain → core → BFF

| Domain | Website / core modules | BFF prefix | Flutter features |
|--------|------------------------|------------|------------------|
| Auth session | Supabase Auth | direct + `/auth/*` OTP | `features/auth` |
| Profile / roles | profiles, user_roles | `/me`, `/me/profile`, portal-apply | profile, portals |
| Listings | `listings-core`, nyumba-shared | `/listings` | home, search, detail, map |
| Saved | saved_properties | `/saved` | favorites |
| Unlock + pay | contact-unlock-core, initiate-payment-core | `/unlock`, `/payments` | property unlock |
| Rent | pm IntaSend collect | `/tenants/rent/*` | rent |
| Messages | conversation fns | `/messages` | messages |
| Reviews | review fns | `/reviews`, eligibility | reviews |
| Subscriptions | plans, entitlements | `/subscriptions/*` | plus, plans, boost |
| Listings CRUD | property owner fns | `/properties` | landlord listings |
| Media | storage signed | `/properties/:id/media` | create/edit listing |
| PM | `lib/pm/*`, pm.functions | `/property-management/*` | property_management |
| Caretaker | caretaker session | `/caretakers/*` | caretaker |
| Providers | service-provider.functions | `/providers/*` | providers |
| Notifications | notifications.functions | `/notifications`, `/fcm-token` | notifications |
| Verification | verification.functions | `/verification/*` | verification |
| Admin | admin.* | `/admin/*` | admin |
| Org | org team | `/org/*` or team paths | portal team |
| Referrals | referral fns | `/referrals/*` | referrals |
| Analytics | landlord analytics | `/landlords/analytics` | landlord analytics |
| Compare / saved searches | compare + alerts | `/listings/compare`, `/saved-searches` | compare, search |
| Contact form | notify / CF Email | `POST /contact` (Wave 19) | content |
| Advertise | advertise inquiries + initiate-payment-core | `/advertise/*` (Wave 19) | content |
| CSV listing import | portal import cores | `/listings/import/*` (Wave 19) | landlord |
| Integrations API keys | portal API key cores | `/integrations/keys*` (Wave 19) | landlord |
| Admin revenue | admin revenue cores | `GET /admin/revenue` (Wave 19) | admin |

## Payment routing (unchanged)

| Product | Provider | Flutter path |
|---------|----------|--------------|
| Rent | IntaSend | `POST /tenants/rent/pay` |
| Contact unlock / Plus / boost / leads / verification (M-Pesa) | Daraja STK | unlock / checkout / initiate |
| Card | Pesapal | method=card → redirectUrl + poll |

## Forbidden

- Service-role key in Flutter  
- Direct privileged PostgREST writes that bypass BFF for payments/PM/admin  
- Duplicating fulfill / pricing rules in the client  
