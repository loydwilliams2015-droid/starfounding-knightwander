# SK R2-M06 — Material-grounded graphical joints

**2026-11-26 | standalone Godot 4.7.2 map QA.** This is a bounded visual grammar pass, not original-game integration.

## Material rules and semantics

| World region | Valid visual vocabulary | Forbidden implication |
|---|---|---|
| Stone | Local sediment/fracture geometry beneath pad underside | Gears, ropes, engineered cross-gap bridge |
| Timber | Triangular brackets; wooden lintels on short level spans | Spinning gears; unsupported long beam |
| Relicwright | Anchored suspension cable, softly colored rivet halo | Unanchored rotor or walkable decorative cable |
| Industrial | Steel cables; pivot only for a proper hinged-brace span | Free-floating gears |
| Failed / unsupported link; biome transition | Disconnected end caps | A false connected traversable bridge |

Visuals do not supply collision bodies or prove an actual jumping trajectory. The earlier R2-M04 full-route certificate still controls all item/event spawns. **Unknown and failed classifications fail closed.** Material assignment is currently a deterministic test biome per 960-world-unit region, not the final game’s authored biome data.

## Executed native regression

- R2-M06 material semantics: **72,630/72,630 assertions**, 300 deterministic generated routes (100 seeds each at 4, 5, 6 screens), plus explicit synthetic material cases.
- R2-M01 generator: **1,503/1,503**.
- R2-M02 collider: **143/143**.
- R2-M03 spawn safety: **5,416/5,416**.
- **Total freshly executed: 79,692/79,692**, zero failures.
- **Four genuine Godot 960×540 screenshots**, one per material region. Contact sheet and four-frame slideshow GIF are included in the separate project ZIP.
- No physics objects added; the S33 archived SCALE/ART baseline not modified.
- R2-M04 57 native links **not rerun in R2-M06**; prior result is historical only.

## Archive

Full standalone Godot source, environment drawing logic, test scripts, captures, verification logs and manifests: **SK_ENGINE_R2_M06_patch.zip**. Local archive SHA-256:
`d09b55ea17265aa037b422cc30fc9d8beb174c916fcdaa9e657ca5e922389594`.
69 entries; ZIP CRC passed.

The repository file `qa/map/r2_m06_material_joints.gd` carries the material rule classifier with an adjusted BASE preload relative to the existing repository. Local runnable scene uses `scripts/r2_material_joints.gd` and `scripts/r2_context_joints.gd`. The original S33 ZIP remains protected under `qa/scale-art/archive/`. The entire M06 ZIP is **not** committed to GitHub.

**Next acceptance:** author context-aware terrain and architecture art, show distinct damage/biome-transition examples, test continuous traversal and checkpoint recovery. Preserve the spawn gate. Debug pad colors and graphic silhouettes are not production approval.
