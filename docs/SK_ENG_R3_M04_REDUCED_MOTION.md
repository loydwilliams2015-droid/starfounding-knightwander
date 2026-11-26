# SK-ENG-R3-M04 — Reduced-motion accessibility and performance

**Date:** 2026-11-26. **Status:** PASSED for bounded standalone native QA; production integration pending.

## Implemented

The additive Godot 4.7.2 QA scene `scenes/r3_m04_accessibility.tscn` inherits from the existing S33/R3-M03 wrapper. A visible **Reduce motion [M]** CheckButton and M keyboard shortcut update one reversible accessibility setting. When enabled, decorative fixtures stop advancing their phase and stop submitting redundant redraws. All four optional parallax layers receive zero scroll scale; optional horizontal/vertical camera anticipation is disabled. The camera **remains parented to the knight**, so actor-follow continues normally. On disabling the setting, the initial parallax scroll scales and normal auto-camera anticipation are restored.

**Scope:** session-only control, not persistent preferences or a game-wide accessibility system. The original S33 controller, pose textures, crouch collider, collision-bearing platforms and map-spawn authority are unchanged. This is a standalone S33-derived QA scene, **not** the complete playable Starfounding Knightwander nor integrated R2 procedural platform world.

## Native test evidence

Ten Godot 4.7.2 suites were freshly rerun with **658/658 assertions passing**, zero failures:

| Suite | Checks |
|---|---:|
| New R3-M04 reduced-motion UI, fixture budget and movement | 155/155 |
| R3-M03 hierarchy | 108/108 |
| R3-M02 movement | 74/74 |
| S32 camera ownership | 76/76 |
| S31 crouch reversals | 46/46 |
| S30 vertical camera | 15/15 |
| S29 traversal | 15/15 |
| S28 input/camera | 22/22 |
| S27 camera/parallax | 128/128 |
| S23 visual/collision | 19/19 |
| **Total** | **658/658** |

New tests verify both UI paths, static fixtures, restored camera/parallax rates, original movement/jump/landing/crouch/recovery, and unchanged platform collision geometry and reference texture paths. Eight native Godot screenshots at 960x540 were saved, two for each environment tint (stone, timber, relicwright, industrial). These are treated as screenshot evidence, **not a human art signoff**.

## Performance: diagnostic only

Godot 4.7.2 OpenGL compatibility rendered through **Mesa llvmpipe CPU software renderer / Xvfb** at 960x540. Three sequential 160-frame trials after per-mode warmup:

| Sample | Decorative redraws | P50 elapsed interval | P95 elapsed interval |
|---|---:|---:|---:|
| Motion enabled | 160 | 9.43 ms | 11.24 ms |
| Reduced motion | 0 | 8.91 ms | 11.35 ms |
| Motion restored | 160 | 9.93 ms | 15.39 ms |

The verifiable improvement is suppression of redundant fixture redraws, **not a validated performance uplift**. Frame-time trends vary with software rendering, scheduling and trial order. No production GPU/FPS certificate or real-game frame budget is claimed. Full detailed report is in the separately downloadable ZIP.

## Source custody

The complete playable QA scene, actual S33 reference sprites, Godot tests, native log files, performance JSON, eight captures, composite and integrity manifest are in the separate **`SK_ENGINE_R3_M04_patch.zip`**. Archive SHA-256: **`0d9ee7c1b3327fc75c0187e5261f8179d1cb2ab2d3adf8d9ca1a7430303734fe`**; ZIP CRC and fresh-extraction editor import plus 155/155 new assertions passed. Project's `project.godot` points to the new M04 scene.

Published GitHub source paths under `qa/animation/` mirror the exact new Godot scripts and QA suite from the runnable package. **They use the local `res://scripts` and `res://scenes` paths; to run them, use the ZIP folder layout.** The complete new ZIP and screenshot bytes are not claimed to be committed to GitHub. The protected S33 archived ZIP is unchanged.

## Next spiral: R3-M05 acceptance and transition

1. Consolidate new R3 evidence (pose, motion, hierarchy, accessibility) and open risks without conflating standalone QA and original-game readiness.
2. Exercise reduced-motion preference persistence and accessible options if integration is authorized.
3. Test actual four-material R2 procedural scenes with character, camera and safe item/event gating; restore continuous traversal/checkpoint acceptance.
4. Benchmark target GPU frame times and obtain manual art/readability signoff before approving production.
5. Prepare R4 renderer/parallax/lighting rotation as a scoped dependency rather than expanding R3 indefinitely.
