# SK-ENG-R4-M03 — Native full-chain route QA and S33 certificate

**2026-11-26 · Acceptance: PASS for bounded standalone Godot 4.7.2 QA.** This is a test-world integration of R2 procedural platforms and S33 Knight movement, *not* the original complete Starfounding Knightwander game.

## New engineering work

- The actual S33 controller retains its 220 horizontal walk, -410 jump impulse and 1050 gravity. The entrance footholds introduced by R4-M02 remain real one-way collision surfaces.
- `r4_m03_chain_driver.gd` continues directly from a native ground-to-first-pad ascent through each neighboring raised platform, using `sk_right` and the existing S33 jump queue. **There are no teleports between elevated platform landings.** Each edge must include an airborne phase and a real collision landing on the exact target pad; tests cease at the first failed edge. This is a deterministic automated input driver, not human playtest certification.
- `r4_m03_certificate.gd` audits all expected edges, route geometry, source and destination foot coordinates, native flight/landing observation, complete entrance, S33 controller identity and the immutable-in-process trace digest. Fault tests revoke evidence for a missing or altered edge, wrong pad coordinates, wrong controller, false entrance, replay onto a different seed, altered digest or forged gameplay-spawn permission.
- `r4_m03_stage.gd` displays observational route rings and **preview-only** star/event symbols after native evidence passes. The actual item/event placement gate stays **blocked and empty**, even after a QA route passes. The hash is a provenance checksum, **not a cryptographic authentication signature** or production gameplay authorization.

## Native route matrix

| Seed | Screens | Native elevated links | Entrance jumps |
|---|---:|---:|---:|
| 41 | 4 | 19/19 | 2 |
| 4096 | 4 | 19/19 | 3 |
| 125000 | 5 | 24/24 | 2 |
| 4096 | 5 | 24/24 | 3 |
| 800000 | 6 | 29/29 | 2 |
| 41 | 6 | 29/29 | 2 |
| **Total** | | **144/144** | |

New R4-M03 native suite: **3,462/3,462** assertions, zero failures across six seed-isolated Godot processes. **17 inherited suites** (four R4-M02 entrance runs and 13 R4-M01/R4-M00/R3/S23–S32 regressions): **9,456/9,456**. **Grand total 12,918/12,918**. Other seeded generator candidates in test loops are purely analytic and do **not** constitute 200+ additional native routes.

Seven real Godot 960×540 captures track the knight from ground through stone, timber, relicwright and industrial segments of the same continuous route, followed by a verified QA HUD view and reduced-motion view. Two comparison sheets and one staged-slide GIF are included; the GIF is **not a live gameplay video**.

The complete native QA project ZIP `SK_ENGINE_R4_M03_patch.zip` contains imported source-ready assets, the full exhaustive test and screenshot scripts, native logs, six trace summaries and manifests. **442 ZIP entries; SHA-256 `3efd8b641a8c0a3a78015225c4a3ef3a36371221fa974630a8eefeee42ff63b8`.** ZIP CRC, fresh extraction, Godot editor import and new 557/557-assertion native retest passed.

## Publication / limitations

This repository's `qa/render/r4_m03_*.gd` files contain the exact new core source. The full runnable `res://scripts`, `res://scenes`, `res://tests`, S33 reference textures, screenshots and complete ZIP are **separately downloadable**, not fully stored in GitHub. Do not run the standalone connector source files without restoring the ZIP's Godot directory layout.

The protected archived S33 ZIP `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip` is unchanged.

**Not certified:** untested route seeds, human gameplay balance, actual pickup/event systems, checkpoint restoration and crash-safe save commits, original playable-game integration, production GPU performance, or approved final game art. The QA-only certificate and SHA checksum cannot authorize in-game item spawning.

**Next R4-M04:** interruption/recovery and checkpoint ownership; duplicate/reordered/partial checkpoint rejection; broaden native seed tests and record failures, then investigate controlled original-game integration with persistent provenance and explicit gameplay spawn authority.
