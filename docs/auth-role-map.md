# Auth & role map

## Canonical roles (`app_role` / `user_roles`)

`tenant` | `landlord` | `manager` | `agency` | `caretaker` | `admin`

Multi-role users are supported. Server `requireRole` grants **admin** bypass.

## Signup account roles

`tenant` | `landlord` | `manager` | `agency`  
Privileged roles require org metadata and often `portal_applications` approval before dashboard access.

## Portals (`PortalId`)

| Portal | Home (web) | Access |
|--------|------------|--------|
| tenant | `/tenant` | Always (client) |
| landlord | `/landlord/dashboard` | `user_roles` contains landlord |
| manager | `/manager/dashboard` | manager role |
| agency | `/agency/dashboard` | agency role |
| caretaker | `/caretaker/dashboard` | PIN session (not layout role-gate) |
| admin | `/admin` | admin role |

Profile: `active_portal`, `is_portal_active`.

## Flutter implications

1. `GET /me` returns `roles[]` + profile including `active_portal`.  
2. Role switcher calls `POST /me/active-portal`.  
3. Lister shells require matching role; else show apply / pending.  
4. Caretaker uses separate `POST /caretakers/session` token storage (secure storage), not only Supabase JWT.  
5. Org team members (agency/manager) may see reduced nav — mirror `use-org-membership`.  
6. Never trust client-supplied role for authorization; BFF re-checks `user_roles`.

## Auth methods

| Method | Flutter | Notes |
|--------|---------|-------|
| Email/password | Done | Supabase |
| Google OAuth | Partial | PKCE + `ke.co.nyumbasearch.app://login-callback/` |
| Phone OTP | Not started | Reuse Africa's Talking server path via BFF |
| Password reset | Partial | Email link / OTP parity TBD |
| Session restore | Done | Splash hydration |
