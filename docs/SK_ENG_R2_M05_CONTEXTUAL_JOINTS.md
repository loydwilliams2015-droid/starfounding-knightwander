# SK R2-M05 — Contextual joints and truthful connector geometry

**26 November 2026.** Standalone Godot 4.7.2 map QA, not an integrated game build.

## Corrected visual grammar

- Short level spans (<=164 world pixels, <=25 vertical): **anchored hinged brace** with limited pivot rotation at the actual structural midpoint.
- Larger viable offset spans (<=205 horizontal, <=85 vertical): **suspended cable** with riveted fixtures beneath both pads and subtle animated sag; no free-floating spinning hubs.
- Failed or unsupported span: **disconnected end caps**, caution detailing, and no continuous bridge graphic. Failure must remain visually legible.
- All three classes are **render-only** with zero additional collision bodies. Decorative structures do not authorize traversal or any pickup/event spawns.

## Executed

- Local full scene updated: `scripts/r2_physics_world.gd` now consumes `scripts/r2_context_joints.gd` and draws geometry according to explicit joint kind. The complete scene and captures are in the separately downloadable **SK_ENGINE_R2_M05_patch.zip**; GitHub's standalone classifier is at `qa/map/r2_m05_context_joints.gd`.
- New `tests/r2_m05_joint_test.gd`: **36,610/36,610** native Godot assertions across 300 generated routes plus synthetic aligned, offset and failed examples.
- Inherited R2-M03 spawn safety: **5,416/5,416**; R2-M02 collision: **143/143**; R2-M01 deterministic map: **1,503/1,503**. Total newly executed this pass: **43,672/43,672**.
- Four engine-rendered 960×540 preview images, contact sheet and staged four-frame GIF. The incumbent generator mostly takes the suspended-cable branch; the other classes passed automated semantic tests but were not approved visually.
- Local ZIP SHA-256: `cd28917775caf43eb00e8cd06569bd484822365e5c2142e5f39c1fa36730776c`; ZIP CRC pass.
- The protected `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip` is unchanged.

**Open:** Current synthetic structural semantics are not a gameplay bridge, player navigation affordance, production physics verification or art acceptance. R2-M04 three-seed full-chain native tests were **not rerun** in R2-M05; previously certified results remain prior milestone evidence.

**Next:** add stage-set context tags (natural stone, medieval timber, relicwright mechanical, urban infrastructure) so only relevant kit uses moving hardware; capture explicit damaged/disconnected and short-brace examples; retain fail-closed item/event policies.
