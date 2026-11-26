# SK-ENG-R2-M02 — Collision-bearing procedural traversal (2026-11-26)

**Scope:** isolated R2 Godot 4.7.2 QA project. Original playable Starfounding Knightwander and the S33 SCALE/ART custody ZIP remain unchanged.

## Implemented
- Reuse R2-M01's deterministic seeded four-to-six-screen route generator.
- Instantiate each continuous ground segment as `StaticBody2D` with a real rectangular collider; create one-way elevated platform colliders for all generated pads.
- Instantiate a real `CharacterBody2D` capsule probe (radius 13, height 64), walking 230 units/s, jumping at -600 units/s against 1100 units/s² gravity.
- Add a standalone scene plus visual debug preview; no production artwork claimed.

## Local executed verification
- Prior R2-M01 seeded geometry and replay regression: **1,503/1,503** assertions.
- New R2-M02 physical geometry + seed checks across 15 seeded routes (4, 5, 6 screens × seeds 0, 1, 41, 77, 99), grounded collision initialization and real first-platform ascent/landing followed by a rightward jump: **143/143** assertions.
- Actual Godot 4.7.2 Xvfb/OpenGL 960×540 captures: **3/3** successful. Staged debug screenshots, not an end-to-end gameplay session.
- Local ZIP `SK_ENGINE_R2_M02_patch.zip` SHA-256: `562652a30c4709a5898f265cf0554ff9501a325a3a7d594f4bdc72300a2389fb`; ZIP CRC passed, 37 entries.

## GitHub publication
The source and tests are published at `qa/map/r2_m02_physics_world.gd` and `qa/map/r2_m02_physics_test.gd`. These paths hold the actual GDScript code. The full separately downloadable Godot demo project, scene, screenshot assets and ZIP are **not** claimed to be on GitHub. In the local project the same logic resides in `scripts/r2_physics_world.gd` and `tests/r2_m02_physics_test.gd` alongside the R2-M01 generator. These scripts therefore require their local scene and generator for execution; simply checking out the GitHub documents is insufficient.

**Acceptance boundary:** Real physics was verified for a first-pad landing and a subsequent rightward transition in seed 41. The 15 seeds cover collider instantiation, *not* exhaustive dynamic jump reachability. Full four-to-six-screen player traversal, checkpoints, streaming, original-game integration, production art/lighting and human playtesting remain deferred.

**Next run R2-M03:** exercise player-control trajectories between multiple platforms and across screen transitions for several seeds, add checkpoints, and capture complete input-driven sequences. Then rotate to R3 animation without modifying the protected S33 archive.
