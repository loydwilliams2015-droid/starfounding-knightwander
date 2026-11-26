# SK-ENG-R3-M01 — Profile A pose readability across biome motifs

**2026-11-26.** First R3 Character Animation spiral pass. Standalone Godot 4.7.2 QA; production art and original playable-game integration remain open.

## Actual work
- Copied four unchanged reference PNG assets from protected S33 custody source: standing, S22 settling, S22 compression, crouching.
- Added one Godot test scene displaying all four original source textures at 1:1 pixel geometry and fixed bottom-center foot anchor.
- Compared against stone, timber, relicwright and industrial palette treatments at 960×540. One actual Godot engine screenshot per biome; 2×2 contact sheet and four-frame biome slideshow.
- Native Godot R3-M01 test **784/784** passed; inherited R3-M00 motif regression **23,548/23,548** passed. **24,332/24,332 freshly executed**.
- An import-order issue was detected in the release rehearsal (texture-import metadata removed before engine import). Corrected by running a fresh Godot editor import before final tests/captures. Final tests and all four captures passed.
- Visual review: strong foot alignment and distinguishing key poses at scene scale; relicwright teal may require additional silhouette contrast when moving.

## Scope and source custody
This GitHub path `qa/animation/r3_m01_pose_contract.gd` is an independent **code contract**. The full runnable drawing scene, reference PNGs, native tests and image assets are in the standalone `SK_ENGINE_R3_M01_patch.zip` downloadable artifact, not yet all stored in GitHub.

Local ZIP SHA-256: `c6d07f9b381cba6bd7124a0810a162f8e2573fda8e8883fac4f82364bf68224a`. ZIP integrity: passed. The protected S33 source remains unchanged.

**Not certified:** Input-driven animations, production pixel art, human playtesting, frame-time performance, original SK game integration, or authentic movement transitions in the R2 procedural scene. Existing S33 collider/adapter acceptance remains separate.

**Next R3-M02:** integrate the same source sprites into actual S33 controller/camera action sequences and test visual distinguishability with background movement and lighting; preserve the bottom-centered foot anchor and fail-closed route spawning.
