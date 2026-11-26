# SK R2-M04 — Full native chain gate (2026-11-26)

**Scope:** standalone Godot 4.7.2 world/map QA, not the original playable Starfounding Knightwander project. S33 SCALE/ART immutable archive remains unchanged.

## Executed code and assets

- Added `scripts/r2_native_gate.gd` with route-geometry fingerprint and complete directed-edge native results. Any missing, duplicate, failed or wrong-route evidence prevents all item/event spawns. This is an internal QA attestation, **not a security-grade signature**.
- Changed the standalone world to retain only proxy-based `preview_placements`; actual `placements` defaults to blocked until the complete native chain is verified.
- Kept the sweeping, rotating mechanical spline joints fully visual; no additional physics bodies were introduced.
- The complete runnable source, four actual Godot screenshots, four-phase GIF, native logs, manifest and test files are in the separately supplied `SK_ENGINE_R2_M04_patch.zip`. GitHub files are an independent source handoff, not a claim that the full ZIP was uploaded.

## Acceptance

- Four-screen seed 0: 19/19 native destination landings; 28/28 assertions.
- Four-screen seed 41: 19/19 native destination landings; 28/28 assertions.
- Four-screen seed 77: 19/19 native destination landings; 28/28 assertions.
- **57/57 native platform links**, 84/84 assertions, each seed run in an isolated Godot process. Tests reset the physics probe at each edge; **not one uninterrupted player traversal**.
- Inherited route generation: 1,503/1,503; native collider tests: 143/143; proxy + spawn QA updated for fail-closed behavior: 5,416/5,416. **Grand total 7,146/7,146 assertions passed**.
- Four engine-rendered 960×540 views captured; ornamental joint phases staged for review.
- ZIP SHA-256 `a133996af2b35208ea12f08e1ad26c0d543da03cebab4211162f17341d8fd6f1`. ZIP CRC passed.

## Explicitly not certified

Other seeds; five/six-screen all-edge physics; continuous player-controlled traversal; checkpoint restore; original-game integration; production art/animation and runtime budget. Do not authorize production spawns on any other route by extrapolation.

## R2-M05 / R3 transition

Test actual uninterrupted input paths and checkpoint recovery for several routes, or formally defer those gates while rotating into R3 Profile A animation. Do not modify the protected S33 source archive.
