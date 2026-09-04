# Flutter role parity

Companion: [auth-role-map.md](./auth-role-map.md). Website enforces roles via `requireRole` / portal layouts; Flutter must mirror **visibility** and BFF must re-check roles (never trust client).

## Roles

| Role | Website home | Flutter home | Capabilities (must match web) | STATUS |
|------|--------------|--------------|-------------------------------|--------|
| tenant | `/tenant` | `/home` shell | Browse, save, unlock, pay, messages, rent/maint/complaints when invited | IMPLEMENTED |
| landlord | `/landlord/dashboard` | `/landlord` | Listings, boost, leads, caretakers, PM, billing, payouts, import, integrations | IMPLEMENTED (import/integrations Wave 19) |
| agency | `/agency/dashboard` | `/agency` | Same as landlord + **team**; no boost | IMPLEMENTED (import/integrations Wave 19) |
| manager | `/manager/dashboard` | `/manager` | Same as agency | IMPLEMENTED (import/integrations Wave 19) |
| caretaker | `/caretaker/dashboard` | `/caretaker/dashboard` | PIN session, vacancy updates | IMPLEMENTED |
| admin | `/admin` | `/admin` | Queues, create listing/provider, revenue | IMPLEMENTED (revenue Wave 19) |
| service provider | `/services/provider/dashboard` | `/services/me` | Profile, jobs visibility | IMPLEMENTED |

## Permission rules

1. Multi-role users: `GET /me` + `POST /me/active-portal` (Flutter PortalHomePage / Profile).
2. Portal apply: `POST /me/portal-apply` → `/auth/pending` until approved.
3. Org members: reduced nav when not owner — mirror website `use-org-membership` (Flutter OrgTeamPage).
4. Admin bypass on server only.
5. Caretaker token is separate (`X-Caretaker-Token`), not Supabase role alone.
6. Do not expose admin/manager UI without matching `user_roles` from `/me`.

## Auth methods parity

| Method | STATUS |
|--------|--------|
| Email/password | IMPLEMENTED |
| Google OAuth | TESTING (device QA) |
| Phone OTP signup | IMPLEMENTED |
| Password reset OTP | IMPLEMENTED |
| Session restore / logout | IMPLEMENTED |

## Gap list (remaining)

- Device QA: Google OAuth return → TESTING
- Visual denseness of PM/admin tables → IMPROVED (`PmDenseDataTable` + admin metric grid)
- Mapbox fill-extrusion 3D → **IMPLEMENTED** (`MapPage` + `enableMapbox3d`)
- iOS `APPLE_TEAM_ID` → **DEFERRED** (neglected for now; do not invent)
