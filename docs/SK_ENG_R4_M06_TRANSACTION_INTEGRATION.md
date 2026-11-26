# SK-ENG-R4-M06 — Checkpoint + QA event and inventory single-record transaction

**2026-11-26 | Standalone Godot QA:** PASS within the explicit test scope.

## Decision
A grounded S33 knight's checkpoint position, exact native route prefix, and two *simulated* observable results (a +1 QA star fragment and an “inspected” QA event) are committed as one logical record. The same serialized journal envelope holds everything; no separate gameplay effect is performed before durable-read verification. Thus the QA projection is either at the preceding committed state or a complete new state. Production gameplay items and events remain disabled.

## Mechanism
- Provenance: exact route fingerprint, S33 controller ID, grounded physics foot, native edge prefix, QA-only scope.
- Each successful generation adds one deterministic `qa_observation_pad_XX` receipt and matching event outcome; the inventory count is recomputed from the receipts. Duplicate IDs, wrong order, negative/out-of-range pad, future events or mismatched balances fail validation.
- A candidate is prepared without mutating the visible state. Save uses a temp JSON envelope of Godot Variant binary bytes, SHA-256 checksum, verify-before-rename, atomic local rename to an alternating slot, then read-after-rename. Projection changes only after the post-rename verification passes.
- Each new generation must strictly extend checkpoint landing evidence and its predecessor's receipt list, and reference the previous checksum. Orphaned newer records fail closed, while a valid surviving genesis may be used as fallback.
- A restored scene is repositioned once at the checked checkpoint; Godot re-evaluates its collision floor before restoring the entire QA projection. Subsequent traversal is native input-driven; no mid-route teleporting.
- False and tampered journals cannot unlock actual items or events; `placement_gate` is always `blocked`, with empty lists.

## Test matrix
| Evidence | Result |
|---|---:|
| New native R4-M06 routes: seed 41 / 4 screens; 4096 / 5; 125000 / 5; 800000 / 6 | **224/224** |
| Cross-process native writer/readers: seed 41 / 4; 800000 / 6 | **36/36** |
| R4-M05, M04, M03, M02, M01, M00, R3, S23–S32 inherited suites | **7,128/7,128** |
| **Total fresh assertions, all runs distinct** | **7,388/7,388** |
| Godot 4.7.2 engine screenshots | **8/8** |

Failures tested: before-open, partial and fully serialized uncommitted temporary files; wrong route/controller; corrupted checksum and altered inventory; duplicate event receipt; unapproved event flags; unauthorized spawn flag; reordered slots; missing predecessor; unlinked checksum; airborne write; post-reload collision verification; replay duplicate checkpoint. Correctly failing invalid cases count as **passing assertions**.

## Explicit limitations
This is a QA-only single-record local atomic replacement, not a live transaction across physics/gameplay state. `FileAccess.flush()` and `DirAccess.rename_absolute()` do not by themselves establish real power-loss durability on every filesystem; there is no tested explicit directory `fsync`, interprocess writer lock or external durability barrier. Two-slot fallback prefers integrity over availability. Checksums are not keyed signatures and do not prevent a determined local forger from replacing files. Production-grade event APIs, authoritative gameplay inventory, cross-session identity, original-game integration, field playtesting and GPU performance remain OPEN.

The protected S33 archive is not modified.
