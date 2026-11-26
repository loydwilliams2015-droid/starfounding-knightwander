# SK-ENG-R4-M02 — Native ascent, camera visibility and spawn safety

**2026-11-26. Status: PASS — bounded standalone Godot 4.7.2 QA.**

## Implementation

This QA release uses the **actual S33 CharacterBody2D controller**, retaining its -410 vertical jump impulse, 1050 gravity, 220 walking speed, crouch/animation adapter and camera ownership. Rather than making the knight stronger, a deterministic access planner supplies small stone footholds with real one-way `StaticBody2D` collision. Each added ledge has a visible walking top precisely aligned to its collider; the original R2 base route's ground and elevated platforms are unchanged.

The ascent test runs using the S33 character's own input state. After the initial ground spawn, there are **no teleports between jumps**. Four independent native seed runs reached the first elevated pad: seed **41 (2 jumps)**, **4096 (3 jumps)**, **125000 (2 jumps)**, and **800000 (2 jumps)**.

The camera visibility contract checks three zooms (0.85×, 1.0× and 1.25×), three vertical offsets and two horizontal offsets per seed (72 cases total), the character's camera-space safe rectangle, foreground transparency and z-order. This is not a pixel-level occlusion classifier or human readability signoff. Six negative/fault-injection assertions per seed catch broken collider/art alignment, unsafe spawn flags, invalid route elevation, improper draw order and overly opaque foreground. Reduced-motion settings stay reversible.

**All item and event spawning remains blocked.** First-pad access alone does not certify the subsequent 19-platform chain. The older R2 probe used different physics; its certificate must not transfer to the S33 knight. Camera review, artwork and foothold generation have no content-spawn authority.

## Native evidence

| Native suite | Assertions | Result |
|---|---:|---|
| R4-M02, four seed-isolated runs | **3,984/3,984** | PASS |
| 13 inherited R4/R3/S23–S32 suites | **5,472/5,472** | PASS |
| **Total** | **9,456/9,456** | **PASS** |

The four runs also evaluate 840 geometric ascent candidate plans. Eight fresh **960×540 Godot 4.7.2 OpenGL/Mesa llvmpipe** captures cover ground-level approach, proven elevated landing, two zooms, reduced motion and all four material districts. Two contact sheets present the native captures. The final ZIP passed CRC verification, clean extraction, Godot editor import and an additional 995/995 clean-extraction R4-M02 test rerun; that rerun is a release check, not double-counted above.

Complete reproducible standalone Godot source, S33 reference PNGs, S23–S32 inherited regression suite, R2 generator, new QA tests, captures and report are provided in `SK_ENGINE_R4_M02_patch.zip`. Its measured SHA-256 is **`bebc7a7855266d2f9d57e3e2ded4fc7a2922944dd5eaec3c0f9948bc3df06359`**, with **368 ZIP entries**.

The GitHub `qa/render/r4_m02_*.gd` files and scene hold the exact six new source files; they use `res://scripts` and `res://scenes` dependencies from the separately supplied ZIP. **The complete runnable project, native test suite, screenshots and ZIP are not yet fully mirrored to GitHub.** The protected S33 source-custody archive remains unchanged.

## Acceptance boundary and next milestone

**Accepted:** native entry to the first pad; conservative access geometry; verified scene ordering and camera-space bounds; retained animation/accessibility contracts; fail-closed content gate.

**Open:** uninterrupted full upper-chain traversal under the S33 controller; checkpoint recovery; item/event authorization for fully verified chains; original playable-game source integration; human art review and target-GPU performance.

**R4-M03:** classify and test every upper platform link with the unchanged S33 controller, repair or reclassify impassable transitions, and allow content placement only on complete controller-specific proven paths.
