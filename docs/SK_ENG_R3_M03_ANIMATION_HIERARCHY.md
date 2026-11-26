# SK-ENG-R3-M03 — Contextual decorative motion yields to character animation

**2026-11-26.** Standalone S33-derived Godot 4.7.2 SCALE/ART QA; not the original playable Starfounding Knightwander game or the R2 procedural world.

## Implemented and verified

- **Seven drawn fixtures** read directly from existing platform/ground `StaticBody2D` rectangle geometry, below their actual walkable edges. No free-floating joints, added collision shapes, bridge affordance, or item/event spawning authority.
- Four context treatments over the same S33 urban/parallax environment: **stone** fracture (static), **timber** bounded hanging tassel (at most 1.6 world pixels), **relicwright** soft anchored light (pulse amplitude at most 0.09), and **industrial** anchored axle (integrated speed at most 0.35 radians/sec). This is **not** full R2 biome integration.
- Character priority: when near the knight (within 260 world units), especially during running, crouching or jumping, ornament activity is attenuated toward 0.08. At 500+ units, activity may return to 1.0; exponential interpolation smooths changes. Opacity capped at 0.47.
- Fixed a subtle prototype angular-jump defect: **integrate capped angular velocity**, instead of multiplying the ever-growing global phase by changing activity. The R3-M03 test checks the per-step angular bound.
- The knight is drawn above all decorative fixtures and the prior S33 foreground. S33 original character controller, crouch collider, source textures, Profile A phase schedule, camera look-ahead, lighting count and four parallax rates are unchanged.
- Reduced-motion flag freezes ornamental movement; a user-facing accessibility setting is still deferred.

## Executed native evidence

| Godot 4.7.2 suite | Checks / result |
|---|---:|
| New R3-M03 hierarchy/collider/angle checks | **108/108 PASS** |
| Inherited R3-M02 motion/grade | 74/74 PASS |
| S32 camera ownership | 76/76 PASS |
| S31 crouch reversals | 46/46 PASS |
| S30 vertical camera | 15/15 PASS |
| S29 traversal | 15/15 PASS |
| S28 input camera | 22/22 PASS |
| S27 parallax camera | 128/128 PASS |
| S23 pose/collider | 19/19 PASS |
| **Total** | **503/503 PASS** |

**Six native 960×540 captures** (four material modes plus two industrial variants) were generated with Godot/Xvfb. A four-frame animated review is a **staged material slideshow**, not a live full-FPS gameplay capture.

**Clean archive test:** The final ZIP was extracted to a fresh directory; Godot 4.7.2 editor import and the 108/108 new tests both passed. ZIP CRC passed; 192 included files.

## Source custody and constraints

- Complete downloadable QA archive: `SK_ENGINE_R3_M03_patch.zip`
- ZIP SHA-256: `48579cb86067e117148232e0d23ba8bcf7fa0be661dbc9052a1bfb1f83583132`
- Exact core source file Git blob: `qa/animation/r3_m03_fixture_hierarchy.gd` SHA `26045794d2389b669b1de9083ade989d5881684d`.
- Scene wrapper Git blob: `qa/animation/r3_m03_stage.gd` SHA `42180319be45ca899fec4fb6007d5153e6817a07`.
- The full runnable scene, PNGs, test scripts, manifests and images are in the **downloadable ZIP**, not all committed to GitHub. A GitHub file manifest alone does not replace the missing ZIP bytes.
- The original protected `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip` was not modified.

## Open acceptance

Human silhouette/readability assessment, live motion/60 FPS captures, actual R2 physical-world platform integration, production-authorized character art, measurable frame-time budgets, reduced-motion UI integration, original-game integration, complete M03 GitHub archive custody.

**R3-M04 proposal:** reduced-motion user control, frame-time and motion-budget profiling, and real gameplay-scaled inspection at various camera speeds. R3-M05 would then consolidate closeout evidence before the next engine spiral.
