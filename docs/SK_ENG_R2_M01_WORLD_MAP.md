# SK-ENG-R2-M01 — Deterministic connected map QA

**Spiral:** R2 world/map; standalone prototype, not original-game integration. R1 S33 archive stays untouched under `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip`.

New core scripts live at `qa/map/r2_m01_route_generator.gd` and `qa/map/r2_m01_generation_test.gd`. An independently downloadable standalone Godot 4.7.2 demonstration project also contains a scene with visual previews and captures.

## Acceptance evidence
- 4, 5, 6 screens at 960 world units each; 100 fixed seeds per length; 300 generated layouts.
- Exact seeded replay: 300/300.
- Continuous safety-ground route: 300/300.
- Explicit successive-pad graph connectivity and bounded geometry: 300/300.
- Invalid screen counts (3 or 7) and a deliberately tampered route correctly rejected.
- Native Godot 4.7.2 local prototype: **1,503/1,503 assertions**, zero failures.
- Three 960×540 actual Godot render previews (seed 41, screens 2–4). These are debug art, not production art.
- Collision-aware *player traversal* of upper pads, procedural obstacle difficulty, multi-region exploration and integration with original SK physics **NOT TESTED**. Conservative geometric graph reachability is not a physics-proof of jumping.

## Next gate R2-M02
Instantiate generated platforms as physics-bearing objects in a standalone scene and verify actual jump arcs, collision-free corridors and reachable checkpoints from reproducible seeds. Preserve the source S33 baseline and do not overwrite existing player-world behavior.
