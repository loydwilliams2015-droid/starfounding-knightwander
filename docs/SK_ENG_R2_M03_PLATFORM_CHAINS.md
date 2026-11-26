# SK-ENG-R2-M03 — Platform-chain safety and kinetic art

**2026-11-26 · standalone Godot 4.7.2 QA.** The protected S33 SCALE/ART ZIP is unchanged.

### Implemented
- Deterministic jump-envelope classifier with interior landing preference; deliberately does **not** claim exhaustive Godot physics validity.
- Fail-closed content rule: any invalid or impassable edge blocks **all** item and event placements on its connected chain. Broken horizontal/vertical examples tested.
- Sweeping suspended lines with layered metallic ribbons, rivets and continuously rotating mechanical hubs between platforms. These are render-only ornamental joints, with **no new collision shapes**.
- The full updated Godot project, production-shaped drawing code, two new test suites and actual engine captures are preserved in the separately supplied `SK_ENGINE_R2_M03_patch.zip`.

### Native evidence
- Route/placement safety: **5,414/5,414 assertions**, 300 seeds across 4–6 screens; deliberate broken-chain injections suppress every spawn.
- Physically executed Godot jumps: **54/54 assertions** over 18 selected platform links from three seeds (0, 41, 77). An initial approach falsely passed five links that landed on a neighboring platform; revised interior aim resolved those 18 sampled cases.
- Inherited R2-M01 deterministic geometry **1,503/1,503**; R2-M02 native collider **143/143**. Total **7,114/7,114**.
- Four actual Godot 960×540 decorative scene captures; staged animation phases, not uninterrupted gameplay.

**Acceptance boundary:** Ballistic classification remains a proxy. It has not physically certified every link on every generated seed. Production item/event spawning MUST be gated by complete native verification or a proven accessible alternate route before these positions are promoted from QA to gameplay.

Standalone release ZIP SHA-256: `104a86d9c5e4c60aa8b8e96081ef9881e30903389b903cb113dd742fd13480eb`.

Next: R2-M04 whole-chain native traversal automation with fixture-grounded edge certification and explicit checkpoints. Do not expand the content spawner's authority before that proof.
