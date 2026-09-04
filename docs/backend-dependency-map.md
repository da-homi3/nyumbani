# Backend dependency map

Flutter and the website share Cloudflare Worker + Supabase. Flutter reaches protected logic only through the Mobile BFF.

| Domain | Existing core / server module | BFF consumer |
|--------|------------------------------|--------------|
| Listings search/detail | `lib/api/listings-core`, nyumba-shared | `/listings` |
| Contact unlock | `payments/contact-unlock-core`, unlock-pricing | `/unlock` |
| Payment initiate | `payments/initiate-payment-core` | `/payments/initiate`, unlock, subscriptions |
| M-Pesa Daraja | `api/mpesa.ts` | via initiate core |
| Rent IntaSend | `pm/intasend-collect.ts` | `/tenants/rent/pay`, PM rent |
| Pesapal card | `api/pesapal.ts`, complete-pesapal | `/payments/initiate` |
| Fulfillment | `revenue/fulfill-payment.ts` | webhooks / poll only |
| Plans / entitlements | `revenue/plans.ts`, entitlements.ts | `/subscriptions/*` |
| Favorites | saved property server fns | `/saved` |
| Messaging | conversation / lead fns | `/messages` |
| Reviews | review server fns | `/reviews` |
| PM | `api/pm*.functions.ts`, `lib/pm/*` | `/property-management/*`, `/tenants/*` |
| Providers | `api/service-provider.functions.ts` | `/providers/*` |
| Notifications | `api/notifications.functions.ts`, push-send | `/notifications`, `/fcm-token` |
| Verification | payment + verification.functions | `/verification/*` |
| Admin | admin.* server fns | `/admin/*` |
| Caretaker | caretaker session modules | `/caretakers/*` |
| Authz | `api/_authz.ts` requireRole | BFF auth helpers |
| FCM register | `api/mobile-fcm.ts` | `/fcm-token` |

**Do not call** website-only TanStack RPC from Flutter. Add BFF wrappers instead.
