# SK R3-M02 — Input-driven animation readability (2026-11-26)

Scope: isolated S33 SCALE/ART QA project, not the original playable Starfounding Knightwander game. The immutable S33 ZIP is unchanged.

## New code and assets
- Reversible environmental grading for stone/timber/relicwright/industrial; foreground reduction, four existing parallax layers, actual S33 character controller, camera look-ahead and Profile A pose driver.
- Input-driven movement, jump/landing and crouch recovery, tested at the same unobstructed corridor start for reproducibility.
- An initial test at a raised platform hit a legitimate underside obstacle; the final repeatable jump test uses an open corridor rather than bypassing physics.
- Native Godot 4.7.2 test: R3-M02 **74/74**; inherited S32 **76/76**, S31 **46/46**, S30 **15/15**, S29 **15/15**, S28 **22/22**, S27 **128/128**, S23 **19/19**. Total **395/395** across eight suites.
- Twelve genuine 960×540 Xvfb/OpenGL screenshots; contact sheet and sampled GIF.
- Complete Godot project and original reference images: separately downloadable `SK_ENGINE_R3_M02_patch.zip`; SHA-256 `8cd6ad2c3d6b180aa0db479d035fc6f1e69b8cabd4c4bf219f280508a1261afd`; 187 ZIP entries; archive integrity passed.
- Published GitHub files contain the new QA code and documentation but **not** the full R3-M02 binary archive.

## Limitations
The S33 urban parallax is tinted with each biome palette; this is not four original R2 biome scenes. Running/jumping use the existing stand/crouch visual driver; dedicated authored run/jump frames remain deferred. Still open: visual design signoff, production physics/world integration, continuous full-route player traversal, accessible reduced motion and frame-time profiling.

## Next R3-M03
Compare actor motion and decorative joint animation at multiple camera offsets; scale back environment movement where it obscures player action. Preserve authoritative input, collision and fail-closed spawn rules.
