# SK-ENG-R4-M01 — Rendering ownership and R2 collision integration

**2026-11-26 — Standalone Godot 4.7.2 QA.** This is an isolated S33-derived scene with an R2-generated collision district, not the full original playable Starfounding Knightwander project. The protected S33 archive is not modified.

## Implemented

The R4-M01 test adds real, deterministic R2 route geometry in a separate world region starting at **x=4000**. For seed 41, four screens contain **24 native physics bodies**: 4 continuous ground sections and 20 one-way elevated platforms. The original S33 knight, physics controller, camera and Profile A source poses are retained; the R2 physics-probe controller is **not** swapped in.

The four rendering strata are ordered behind the scene (z=-12 to -9); generated collision-aligned terrain is at z=0; decorative connectors at z=1; the existing S33 decorative foreground at z=8; and the knight at z=9. Contextual rock, timber, relicwright and industrial treatments follow the existing R2 material/surface/joint classifications. Cable and hinge ornamentation never creates a walkable bridge.

**F1–F4** inspect the four biome regions; **M** toggles reduced motion. The setting freezes the extra generated parallax strata and decorative joints in addition to the inherited accessibility behavior. World collision and character movement remain authoritative.

## Gameplay blocker: R2 movement proof is not transferable

The existing R2-M04 native edge certification used a test character with a **-600 jump impulse** and **1100 gravity**. The preserved S33 knight uses **-410** and **1050 gravity**. Idealized S33 vertical lift is about **80 world units**, insufficient to reach the first generated elevated pad from base ground. The R4-M01 test also confirms the failed ascent under **real Godot physics**, followed by a safe landing on continuous ground.

The new `r4_m01_bridge_contract.gd` diagnoses the controller mismatch and **always fails closed**. This scene spawns **zero items and zero events**. Do not promote the earlier R2 physics certificate to this different controller or authorize pickups on inaccessible platforms. A new native-controller full-chain acceptance test is required before modifying spawn authority.

## Executed verification

- R4-M01 native integration: **4,440/4,440 assertions**, zero failures. Includes actual generated collision bodies, surface/collider alignment, z-order, R2 safety classifications, S33 camera/pose ownership, four parallax rates, reduced-motion restoration, F3 shortcut, five-frame native capture workflow, 150 additional pure geometry/material test routes (50 seeds × 4/5/6 screens), and physical negative jump/landing.
- Twelve inherited R3/S23–S32/R4-M00 suites: **1,032/1,032** native assertions, zero failures.
- **Grand total: 5,472/5,472 Godot assertions** on this working project.
- Five genuine 960×540 Godot OpenGL/Mesa llvmpipe screenshots: four material regions plus relicwright reduced-motion; stitched four-panel contact sheet.
- Full ZIP clean extraction and fresh Godot editor import, followed by rerunning **4,440/4,440** new assertions. ZIP CRC verified. Final archive is **SK_ENGINE_R4_M01_patch.zip**, 296 entries; SHA-256 `2030e64e871e9ea8fc5fd3501b56a9839b85d2ce3e8c0599eb622d8714022ee0`.

## Source custody

GitHub contains the new exact-source `qa/render/r4_m01_stage.gd`, `r4_m01_art.gd`, `r4_m01_bridge_contract.gd`, and `r4_m01_layered_world.tscn`, plus this closeout. **The full runnable project** also requires the S33/R3/R4 ancestor scripts, R2 generator/material scripts, Profile A PNG textures and tests. These are supplied in the separate ZIP. Repository QA source paths are documentation/source references: before running, restore the ZIP's `res://scripts`, `res://scenes`, `res://tests` layout. The complete ZIP has not been committed to GitHub.

## Open acceptance

Full-chain actual knight reachability; minimum safe ascent geometry or appropriately balanced movement; continuous route playthrough and checkpoint recovery; audited content placement; original full-game source integration; target-GPU profiling; production art, accessibility preference persistence and human playtesting.

**Next R4-M02:** camera/parallax occlusion and visibility at variable zoom and vertical offsets, then an explicit *controller-consistent* access design for the raised R2 platforms. Never solve reachability only with graphic connectors.
