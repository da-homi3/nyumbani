# NyumbaSearch — Flutter animation parity

**Website motion SOT:** Framer Motion + CSS tokens in `find-nyumba-smart/src/lib/design/motion.ts` and `src/styles.css`.  
**Flutter:** `flutter_animate`, `AnimationController` / tweens, `shared/widgets/motion.dart`.

## Website motion tokens

| Token | Value | Flutter target |
|-------|-------|----------------|
| `MOTION_EASE` | `[0.16, 1, 0.3, 1]` (ease-out expo-ish) | `Cubic(0.16, 1.0, 0.3, 1.0)` |
| `micro` | 150ms | 150ms |
| `fast` | 250ms | 250ms |
| `medium` | 450ms | 450ms |
| `slow` | 700ms | 700ms |
| `MOTION_STAGGER` | 70ms | 70ms between list items |
| `entranceInitial` | `{opacity:0, y:12}` | `ScrollReveal` begin |
| `entranceAnimate` | `{opacity:1, y:0}` | fade+slide |

## Component inventory

| Website component | Trigger | Duration | Easing | Behavior | Flutter equivalent | STATUS |
|---|---|---|---|---|---|---|
| `PageTransition` | route change | medium | MOTION_EASE | fade + slight y | `fadeRoute` / `nyumbaFadeSlidePage` | VISUALLY_MATCHED |
| `ScrollReveal` / stagger | scroll into view | medium + stagger | MOTION_EASE | fade+rise | `ScrollReveal` | FUNCTIONALLY_MATCHED |
| `AnimatedStat` | mount / ready | ~1s | easeOut | count-up | `AnimatedStat` | VISUALLY_MATCHED |
| `TenantBottomNav` layoutId pill | tab change | spring 380/30 | spring | shared-element pill | `HomeShell` AnimatedPositioned glass pill + icon scale | FUNCTIONALLY_MATCHED |
| `PropertyCard` hover/press | pointer | fast | spring | lift/scale | `TiltCard` hover parallax + press depth | FUNCTIONALLY_MATCHED |
| `NeighborhoodCard3D` tilt | mousemove | spring 300/20 | spring | rotateX/Y ±15°, scale 1.05 | `TiltCard` | FUNCTIONALLY_MATCHED — phone uses press depth |
| `SaveButton` | tap | micro | — | heart pop | `FavoriteButton` ScaleTransition pop | FUNCTIONALLY_MATCHED |
| `ContactRevealAnimation` | unlock success | medium | — | reveal phones | fade+slide `_RevealedContacts` | FUNCTIONALLY_MATCHED |
| `VerificationPipeline` | progress | medium | — | step motion | `VerificationPipeline` on verify request/status | FUNCTIONALLY_MATCHED |
| `TestimonialCarousel` | auto/swipe | slow | — | carousel | `HomeTestimonialsCarousel` (API + fallback) | FUNCTIONALLY_MATCHED |
| `PlanCards` | hover | fast | — | lift | `PlanLiftCard` on Plus + landlord plans | FUNCTIONALLY_MATCHED |
| `LandingHero` Ken Burns / crossfade | time | slow loop | linear | hero image | `AnimatedSwitcher` + `CachedNetworkImage` | FUNCTIONALLY_MATCHED |
| `AiAssistant` FAB pulse | idle | ~1.4s loop | — | pulse | `NyumbaAiFab` | FUNCTIONALLY_MATCHED |
| Skeleton loaders | loading | shimmer | — | pulse | `shimmer` package | FUNCTIONALLY_MATCHED |

## Implementation rules

1. Prefer shared widgets in `flutter_app/lib/shared/widgets/motion.dart`.
2. Match durations/easings from this table — do not invent slower “mobile” fades.
3. On low-end devices: reduce particle counts / disable tilt if frame budget fails; document in 3D doc.
4. Never replace a multi-step interaction with a single opacity fade without updating STATUS + justification.
