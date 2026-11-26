# Starfounding Knightwander — R4-M11 single-provider and lock-recovery QA

**Date:** 2026-11-26  
**Disposition:** PASS — bounded standalone S33/R2 Godot 4.7.2 QA; **not** original-game or production save certification.

## Integration decision

`res://scripts/r4_m11_provider.gd` is the single **recommended and tested** dependency that a future gameplay integration would call for checkpoint and event acknowledgement persistence. Its contract is `configure`, `attach`, `acquire`, `save_landing`, `deliver_committed`, `recover_bound_scene`, `status`, `snapshot`, and `release`. The UI scene extends the prior M10 review and is purely observational. The dependency provider owns an R4-M10 coordinator that delegates to guarded R4-M06 transaction and R4-M08 acknowledgement implementations. No direct legacy writer calls are made in the new public workflow.

The binding does not expose gameplay spawn authority. The source remains accessible within Godot (including the provider's `_writer` member); underscore names, dependency injection, and in-process permits **do not constitute an adversarial security boundary**. The older raw writer classes still exist for inherited QA compatibility and could be instantiated by another script. Repository-wide static enforcement and a secure capability system remain open.

## Checkpoint and outbox semantics

- Before a checkpoint commit, validate scene content lock, native grounded player, route fingerprint and S33 controller-specific landing prefix.
- Commit checkpoint pad, native edge history, QA receipt, simulated inventory and event outcome as a single verified transaction record.
- Deliver the verified, read-only event view; record its persistent ACK through the same R4-M10 participating-writer lock. Prevent an advancing TX while an earlier ACK is pending.
- Duplicate delivery of an already acknowledged generation reports `idempotent` and does not grant another simulated reward.
- A fresh scene reload first checks journal lineage, restores the checkpoint, verifies actual Godot floor contact, then resumes native movement.
- Stale locks are **fail-closed**. No automatic takeover or silent TTL/lease expiry exists. The isolated test harness explicitly removes the lock only after its spawned writer has exited. No production cleanup command is provided.

## Tests executed

| Suite | Count | Result |
|---|---:|---|
| R4-M11 native provider cases: (41,4), (4096,5), (800000,6) | 252/252 | PASS |
| R4-M11 real SIGKILL: TX pre-rename / ACK post-TX, probes/recovery/replay | 64/64 | PASS |
| 20 inherited R4-M08 and earlier engine suites | 7,338/7,338 | PASS |
| R4-M09 native coordinator test | 83/83 | PASS |
| R4-M10 native gateway test | 96/96 | PASS |
| **Grand total (completed assertions, no duplicated clean-extraction rerun)** | **7,833/7,833** | **PASS** |

The three M11 routes completed **72/72 raised links** under the unchanged S33 physics. The SIGKILL cases included a live competing-process probe, a stale-lock probe following termination, explicit verified cleanup of isolated test locks, process-separated restore, native route continuation and ACK replay idempotence. **Two killed writer processes are excluded from passed test counts**; only completed probe/recovery/replay processes contribute 64 assertions.

Native screenshots: **11/11** actual 960×540 Godot 4.7.2 OpenGL/Mesa llvmpipe frames. A contact sheet and restoration comparison are assembled from these captures; they are not an actual gameplay recording.

## Scope limits and next gate

This is a **standalone QA adapter** with a cooperative single-writer convention. No real production inventory is modified; actual items and events remain locked. The tests do not establish user identity verification, keyed content authentication, real power-loss durability, multi-host leases, secure writer exclusivity, player-facing save policy, target hardware performance, or integration into the original full Godot game.

**R4-M12 candidate:** static enforcement / dependency-audit gate across all new entrypoints, versioned migration of the original save interface, and a real gameplay event-sink contract tested in isolation with idempotence before enabling actual spawning. Keep the legacy QA compatibility code isolated, never use it as a production writer.

Protected S33 archive SHA-256 (unchanged): `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`.
