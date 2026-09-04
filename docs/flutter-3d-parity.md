# NyumbaSearch — Flutter 3D / WebGL parity

**Rule:** Do not remove 3D/visual effects without explicit justification in this file.

## Inventory

### 1. HeroScene3D (desktop landing)

| Field | Detail |
|-------|--------|
| **File** | `find-nyumba-smart/src/components/hero/HeroScene3D.tsx` |
| **Stack** | `@react-three/fiber`, Three.js Canvas |
| **Visual** | Floating jade particles (~70), translucent glow orbs (jade/gold), pointer-linked camera drift |
| **Interaction** | Passive-only camera follow; `pointerEvents: none` on canvas |
| **Gating** | Lazy-loaded from `LandingHero`; heavy on desktop; mobile web already gates heavy 3D |
| **Flutter today** | `HeroOrbsLayer` + `AmbientBackdrop` — web palette (`#1EB88A`/`#F6AD55`/`#12856B`), ~70 rotating points, pointer-linked camera drift, `TickerMode` pause |
| **Flutter plan** | P0: improve orb/particle fidelity — **done**. P1: pointer camera drift — **done 2026-08-11**. P2: optional `flutter_gl` if budget allows. **Not** a static screenshot. |
| **Perf** | Cap particles on Android mid-tier; pause via `TickerMode` offscreen |
| **STATUS** | PARTIAL (much closer to R3F look; still CustomPainter not Three.js) — IN DEVELOPMENT toward VERIFIED |

### 2. AmbientBackdrop (global)

| Field | Detail |
|-------|--------|
| **File** | `find-nyumba-smart/src/components/motion/AmbientBackdrop.tsx` |
| **Visual** | Canvas floating glyphs/particles over dark UI |
| **Flutter** | `flutter_app/lib/shared/widgets/ambient_backdrop.dart` |
| **Plan** | Match opacity, count, drift; reuse on portal scaffolds |
| **STATUS** | PARTIAL → target VISUALLY_MATCHED |

### 3. NeighborhoodCard3D tilt

| Field | Detail |
|-------|--------|
| **File** | `find-nyumba-smart/src/components/landing/NeighborhoodCard3D.tsx` |
| **Visual** | CSS 3D perspective, rotateX/Y from pointer, image scale |
| **Flutter** | `TiltCard` Matrix4 perspective + spring press scale |
| **Plan** | Keep interactive tilt on pointer devices; on touch use subtle press scale (not flat) — **done 2026-08-08** |
| **STATUS** | PARTIAL → closer to VISUALLY_MATCHED |

### 4. PropertyCard 3D-ish motion

| Field | Detail |
|-------|--------|
| **File** | `PropertyCard.tsx` (web) |
| **Flutter** | `PropertyCard` + `TiltCard` wrapper |
| **STATUS** | PARTIAL |

### 5. Mapbox 3D buildings / terrain

| Field | Detail |
|-------|--------|
| **File** | website historically `mapbox-3d` / Tenant map; Flutter `lib/features/maps/` |
| **Visual** | `fill-extrusion` buildings minzoom 13; DEM terrain; Kenya maxBounds; pitched camera |
| **Flutter today** | Official **`mapbox_maps_flutter`** (`MapWidget` + `streets-v12`) with `enableMapbox3d()` — fill-extrusion layer `nyumba-3d-buildings`, DEM terrain, pitch ~52°, Kenya camera bounds, listing point annotations |
| **Token** | Runtime `GET /api/mapbox-token` → `MapboxOptions.setAccessToken` |
| **Android** | AGP 8.11.1 + `tool/patch_mapbox_agp.mjs` (unconditional `kotlin-android` for plugin 2.28.0). Debug APK builds verified. |
| **STATUS** | **IMPLEMENTED** — interactive 3D buildings + terrain (device visual QA → VERIFIED) |

Apple Team ID / Universal Links remain deferred (out of scope for this map work).


### 6. Panorama / 360 / video tour

| Field | Detail |
|-------|--------|
| **Website** | tour_url / video on detail; `Panorama360Viewer` where present |
| **Flutter** | Detail: walkthrough video + **Open 360° / virtual tour** (`tour_url`) via external browser/viewer |
| **Plan** | External launch keeps interaction; native 360 embed optional later |
| **STATUS** | PARTIAL → FUNCTIONALLY_MATCHED for URL tours |

## Explicit non-removals

| Effect | Allowed substitute | Forbidden |
|--------|-------------------|-----------|
| Hero particles/orbs | CustomPainter / shader orbs | Delete / blank hero |
| Card tilt | Matrix4 tilt or press depth | Flat card only |
| Map 3D buildings | Mapbox Maps Flutter (`enableMapbox3d`) | Flat raster-only map |
| Ambient particles | Canvas painter | Remove for “clean UI” |

## Performance tiers

1. **High:** full particles + tilt + Mapbox 3D buildings/terrain  
2. **Medium (default phones):** reduced particles, tilt on demand, Mapbox 3D with pitch  
3. **Low:** ambient off, no tilt; keep Mapbox vector map (may lower pitch if frame budget fails) — still branded chrome  

Detect via device class / frame timing; never ship tier-3 as the only experience without documenting.
