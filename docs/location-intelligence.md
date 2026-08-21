# Kenya Location Intelligence Layer

Authoritative place hierarchy for NyumbaSearch search, listings filters, landlord pin assist, inventory-gated `/areas` SEO, admin tooling, and demand analytics.

## Design

- **Two parallel trees in one table** (`locations`): electoral hierarchy (`COUNTRY → COUNTY → CONSTITUENCY → WARD`) and informal urban places (`LOCALITY` / `NEIGHBOURHOOD` / `ESTATE`). Estates are **not** electoral children.
- **Preserve free text**: `properties.neighborhood` and `address` stay intact. Reconciliation writes nullable FKs plus confidence / needs-review flags.
- **No invented places**: seed only from named sources + curated catalog. Roads come from OpenStreetMap names only; buildings only from an operator-supplied open GeoJSON.

## Schema

- `find-nyumba-smart/supabase/migrations/20260820140000_kenya_locations.sql` — PostGIS, locations, aliases, sources, property FKs
- `find-nyumba-smart/supabase/migrations/20260820210000_location_phase3.sql` — location audit, location search telemetry, `locations_containing_point` RPC

## Scripts

```bash
# From find-nyumba-smart/
npm run seed:locations
npm run reconcile:locations
npm run refresh:location-inventory
node scripts/apply-location-phase3.mjs
npm run seed:county-polygons
npm run seed:osm-roads
```

## Product surfaces

- **APIs**: `/api/locations/*` + Mobile BFF `/api/mobile/v1/locations/*`
- **Ranking tiers**: `inside` → `near` → `marketed_as` when a place filter is active
- **Admin**: Control Center → **Locations**
- **SEO**: localities ≥3; wards ≥1 nationally; empty pages `noindex`
- **Flutter**: landlord create-listing neighborhood autocomplete + location FK attach on create
- **Reverse geocode**: county polygons via PostGIS when geom present

## KeNHA / KURA note

Official KeNHA/KURA CAD/road networks are not redistributed. OSM major roads are an open proxy with provenance.
