# Security assessment — Flutter full parity

## Non-negotiables

- [x] No `SUPABASE_SERVICE_ROLE_KEY` in Flutter  
- [x] No Daraja / IntaSend / Pesapal / AT secrets in Flutter  
- [x] Contact phones only after server unlock entitlement  
- [x] BFF validates Bearer via Supabase Auth  
- [x] BFF re-checks roles via `user_roles` (never trust client role claims)  
- [x] Payment webhooks unchanged  
- [x] Package ID unchanged  

## Threats & mitigations

| Risk | Mitigation |
|------|------------|
| PII phone scrape | Unlock core + RLS; BFF only |
| Privilege escalation | requireRole / admin checks on every admin & lister route |
| Payment tampering | Server-side amounts from cores; client sends intent only |
| Token theft | Short-lived access token; refresh; secure storage for caretaker PIN session |
| Private verification docs | Storage policies; signed URLs via server |
| Deep link hijack | assetlinks + release cert SHA-256 already published |
| Admin on mobile | Strict admin role; limit to queues; finance tables web fallback |

## Website compatibility

Additive BFF must not alter createServerFn contracts. After each Worker deploy: `GET /api/health` + smoke critical web paths.

## Open items

- Enable `FCM_SEND_ENABLED` only after notification UX tested  
- iOS ATS / keychain / Universal Links before App Store  
- Penetration pass on admin BFF before production admin mobile  
