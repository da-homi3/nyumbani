# Flutter architecture — full parity

## Stack

- Flutter + Dart, Material 3  
- Riverpod, GoRouter  
- Freezed + json_serializable (models)  
- Dio → Mobile BFF only (`X-App-Client: flutter`)  
- supabase_flutter (Auth + RLS-safe ops only)  
- firebase_messaging (FCM)  
- cached_network_image, flutter_map, url_launcher, secure storage  
- google_fonts Syne / Manrope (match website)

**No payment or service-role secrets in the app.**

## Package

`ke.co.nyumbasearch.app` — do not change.

## Design system

| Source (web) | Flutter |
|--------------|---------|
| `styles.css` tokens | `lib/core/theme/nyumba_tokens.dart` |
| ThemeData recipes | `lib/core/theme/app_theme.dart` |
| Brand assets | `assets/brand/` (+ CDN fallback URLs) |
| Motion | `shared/widgets/motion.dart`, `ambient_backdrop.dart` |

Spacing (`space1`–`space10`), radii, shadows (`shadowSoft` / `shadowCard` / `shadowElegant` / `shadowGreen`), and motion curves/durations are locked to website CSS.

### Lucide → Flutter icon map (1:1 preferred)

| Lucide (web) | Flutter |
|--------------|---------|
| `Home` | `Icons.home_outlined` / `Icons.home` |
| `Search` | `Icons.search` |
| `Map` / `MapPin` | `Icons.map_outlined` / `Icons.place_outlined` |
| `Heart` | `Icons.favorite_border` / `Icons.favorite` |
| `Bell` | `Icons.notifications_outlined` |
| `Menu` | text “Menu” + sheet (web parity) |
| `User` / `UserCircle` | `Icons.person_outline` |
| `Building2` | `Icons.apartment` / `Icons.home_work_outlined` |
| `Wrench` | `Icons.build_outlined` |
| `MessageCircle` | `Icons.chat_bubble_outline` |
| `ShieldCheck` | `Icons.verified` |
| `Share2` | `Icons.share_outlined` |
| `Settings` | `Icons.settings_outlined` |
| `LogOut` | `Icons.logout` |
| `Plus` | `Icons.add` |
| `ChevronRight` | `Icons.chevron_right` |
| `Filter` | `Icons.tune` |
| `Sparkles` (NyumbaAI) | `Icons.auto_awesome` |

Do not invent random Material icons for branded chrome without updating this table.

## Feature folders (`flutter_app/lib/features/`)

```
auth/
home/
properties/
search/
maps/
favorites/
notifications/
profile/
landlord/
agency/
manager/
property_management/
caretaker/
providers/
subscriptions/
payments/
verification/
reviews/
messages/
admin/
tenants/
portal/
```

Shared: `core/` (config, network, errors, theme), `routing/`, `shared/widgets/`.

## Navigation

- **Tenant shell:** bottom nav — Home, Search, Map, Saved, (Rent), Profile  
- **Lister shell (landlord/agency/manager):** drawer — Dashboard, Properties, PM, Leads, Plan, Billing, Settings  
- **Caretaker shell:** after PIN — Dashboard  
- **Provider shell:** directory + `/services/me`  
- **Admin shell:** mobile queues  
- **Role switcher:** from `/me` roles + `active_portal`  

## Data flow

```
UI → Riverpod Notifier/Provider → Repository → MobileApiClient (Dio)
                                              ↘ Supabase Auth (session only)
```

Protected writes (unlock, pay, PM, entitlements, provider profile) **never** bypass BFF.

## Mobile UX rules

- Bottom sheets for filters / unlock / pay  
- Pull-to-refresh, skeletons, paginated lists  
- Native galleries / dialer / WhatsApp  
- Adapt dense tables with horizontal scroll — **do not drop columns**  
- Not a 1:1 desktop layout  

## Parity docs

See [flutter-feature-parity.md](./flutter-feature-parity.md) index.
