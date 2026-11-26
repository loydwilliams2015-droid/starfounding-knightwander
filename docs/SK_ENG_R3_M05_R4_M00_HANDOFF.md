# SK-ENG-R3-M05 → R4-M00: conditional character-animation closeout and rendering spiral

**26 November 2026** · Governing status: **R3 CLOSED—STANDALONE QA**, **R4-M00 PASSED—RENDER-POLICY QA**, production integration **OPEN**.

## A. Scope and stewardship

This handoff updates only a copied S33-derived Godot 4.7.2 QA project and two additive scripts, two native test suites, one additive scene, and a capture script. The original playable Starfounding Knightwander game and the immutable S33 archive are unchanged. R2's procedural world, spawn authority and route certificate are not part of this scene.

## B. R3 evidence and decision

| Checkpoint | Evidence and bounded disposition |
|---|---|
| R3-M01 Pose contrast and foot anchor | Four S33 reference poses against four palette treatments; prior standalone tests passed. No production-art approval. |
| R3-M02 Controller-driven motion | Existing controller, running, jump/landing and crouch, camera/parallax; native tests repeated in M05. No custom run/jump production sprites. |
| R3-M03 Animation priority | Seven geometry-anchored visual fixtures, limited ornamental motion and character-first draw order. No platform collision added. |
| R3-M04 Accessibility | On-screen checkbutton and M hotkey; redundant fixture redraw suppression, optional parallax freeze and camera anticipation off. Session-only preferences. |
| R3-M05 Closeout | **63/63 new checks** on original actor, pose, camera, fixtures, reduced-motion control and rendering handoff. |

R3 is ready for rotation **as a verified standalone test system**, not a production-complete animation engine.

## C. R4-M00 renderer/lighting contract

Four grounded graphic palettes: **stone**, **timber**, **relicwright**, **industrial**. Each has two static light roles:

| Role | Light energy policy | Intended purpose |
|---|---|---|
| Diffuse | Key 0.23; fill 0.13 | Low-contrast background context, restrained illumination. |
| Beacon | Key 0.93; fill 0.57 | Localized, authored-looking environmental illumination. |

Both add two **visual-only** lamps reusing S33's original radial lamp texture. Original S33 lamp positions and energies remain invariant. Lamp intensity is bounded (key ≤0.95, fill ≤0.62) and the actor's texture and modulate remain unchanged; the background palette affects only scenery. No light is used as a gameplay collision, physics or spawn authority.

**R4-M00 result: 311/311 new renderer assertions**, including all eight style × role combinations, invalid-profile rejection, static reduced-motion compatibility, parallax restoration, and a native run/jump/landing. Nine actual Godot captures (eight combinations and a relicwright reduced-motion frame) exist at 960×540. Rendered via Xvfb/Mesa llvmpipe; no production target GPU profiling.

## D. Fresh native regression and acceptance

Twelve freshly verified native Godot 4.7.2 suites:

| Suite | Assertions |
|---|---:|
| R3-M05 closeout | 63/63 |
| R4-M00 renderer | 311/311 |
| R3-M04 accessibility | 155/155 |
| R3-M03 hierarchy | 108/108 |
| R3-M02 motion | 74/74 |
| S32 camera | 76/76 |
| S31 crouch/reversal | 46/46 |
| S30 vertical camera | 15/15 |
| S29 traversal | 15/15 |
| S28 input/camera | 22/22 |
| S27 parallax/motion | 128/128 |
| S23 visual/collider | 19/19 |
| **Total** | **1,032/1,032** |

The nine native capture files passed format and resolution verification. A comparison contact sheet and staged GIF are *derivatives* and do not constitute live recorded gameplay.

## E. Blockers and risk boundary

**Blocked** until original playable project source and a merged source-control/asset build are available: game integration, actual authored R2 four-material stage, item/event spawning, puzzles, AI or persistent profile settings.

**Open acceptance**: uninterrupted 4–6 screen traversal across multiple procedural seeds; checkpoint reloading; empirical accessibility playtesting; non-debug final artwork and character animation; target-GPU frame-time tests and light accessibility levels. The native S33 QA actor remains physically and visually functional but these unmet gates cannot be inferred from the 1,032 checks.

## F. Next R4 spiral milestones

1. **R4-M01 — Layer ownership:** classify which elements are background, platform surface, foreground, character, or UI; test render ordering and parallax motion at several camera offsets.
2. **R4-M02 — Actual R2 geometry integration:** render source-authored stone/timber/relicwright/industrial platforms with correct collision-top silhouette, without decorative bridges or unverified spawns.
3. **R4-M03 — Light and camera interlock:** profile nearby fixtures, day/low-light modes and character-foreground separation during actual input-driven motion.
4. **R4-M04 — Accessible graphics budget:** reduced-motion persistence proposal, contrast review, GPU/CPU frame profiling under verified hardware.
5. **R4-M05 — Vertical-slice acceptance:** close standalone render QA, then seek whole-game integration only after canonical source and route/checkpoint gates are met.

**Change discipline:** one bounded observable outcome per milestone; fresh regression and negative tests; actual engine captures; prevent mission creep into gameplay spawning.