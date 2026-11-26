# Starfounding Knightwander — R4-M04 Local Checkpoint & Recovery QA

**Date:** 2026-11-26. **Scope:** standalone S33-derived Godot 4.7.2 test scene with R2 procedural colliders, not the complete original playable game. Protected S33 archive unchanged.

## Run this project

Open `project.godot` in Godot 4.7.2, allow source texture import, and run `scenes/r4_m04_checkpoint_review.tscn`. Normal movement controls, F1–F4 district views and `M` reduced-motion controls remain available. QA checkpoints are created only by the test harness; no in-game save menu or production event logic is implied.

```sh
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m04_checkpoint_test.gd -- 41 4
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m04_checkpoint_test.gd -- 800000 6
# Two distinct OS processes for disk persistence:
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m04_cross_process_test.gd -- write 41 4
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m04_cross_process_test.gd -- read 41 4
```

The checkpoint journal is kept under Godot `user://r4_m04/` in namespace-specific QA folders, never embedded in the game project ZIP. Tests reset **only their own named QA slots**.

## Implemented

- Two rotating local on-disk checkpoint slots, each written to a temporary file, flushed, verified, and renamed to its final slot. The slot data binds to exact R2 route fingerprint, S33 controller, safe grounded foot position and physical prefix of observed landings.
- Strictly increasing pad checkpoints (pad 5, then pad 11 in four in-process tests). Duplicate, regressing, malformed, wrong seed/controller, wrong pad/foot and unauthorized spawn flags fail closed.
- Simulated interruption occurs in midair **after a committed checkpoint**. A new scene is instantiated; the knight is repositioned once to the last validated saved foot position. A native physics grounding check must pass before movement resumes. No teleports occur between later landings.
- Two separate OS-process demonstrations write at pad 9, exit, reopen and complete the route, with exact-route QA certificate and preserved spawn lock.
- When newest local slot is corrupted or its link to the older slot is invalid, loading falls back to the older **fully validated** committed checkpoint. Uncommitted temporary files are ignored.
- Even full-chain resumed routes **do not authorize gameplay item/event spawning**. The journal is explicitly QA-only, not a production save solution.

## Native results

New 4 route tests **232/232**; cross-process writer/readers **30/30**; rerun R4-M03 6 full-chain routes **3,462/3,462**; inherited 17 S23–S32/R3/R4-M02 suites **9,456/9,456**. **Combined: 13,180/13,180 assertions, zero failures.** Seven genuine Godot OpenGL/Mesa llvmpipe 960×540 captures plus two contact sheets.

## Caveats

This is local file continuity QA, not secure signed attestation. The SHA-256 record digest is a corruption checksum; it does not resist a malicious party that edits the record and recomputes the checksum. A flush followed by atomic rename has been tested, but **power-failure safety, directory fsync and transactional game-save semantics have not**. There is no production UI, no inventory, no gameplay pickups/events, no original full-game integration and no broad random-seed checkpoint validation. The absence of items/events is an intentional safety gate.

**Next R4-M05:** systematic fault injection (power interruption simulation, reordered journal entries, scene reload during contact), checkpoint lifecycle and release-candidate closeout; then policy-authorized original-game source integration.