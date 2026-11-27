# SK-ENG R4-M12 — Versioned save projection and isolated event-sink acceptance

**Date:** 2026-11-26. **Milestone:** R4-M12. **Disposition:** PASS for bounded standalone Godot 4.7.2 QA, not production release.

## 1. Deliverables

- `scripts/r4_m12_provider.gd` extends the R4-M11 single-provider API with `v2_preview()`, `deliver_sandbox()`, and sink snapshots. The provider retains one participating writer lock for checkpoint and ACK, and the S33 world remains locked against actual item/event spawning.
- `scripts/r4_m12_migration.gd` migrates a **verified R4M06/tx/1 transaction** into a **derived read-only R4M12/qa_event_view/2 projection**. It binds route fingerprint, controller, generation, physical pad, source transaction SHA-256 and exact receipt order. It checks that a recreated projection is byte-for-byte equivalent as a dictionary to the authoritative source; it does not write to the existing save journal. Version 1 is still the persistent wire format. Version 2 is an interface/schema, **not a durable v2 saved file**.
- `scripts/r4_m12_sandbox_sink.gd` provides an in-memory, idempotent mock delivery sink. It accepts the validated v2 projection only if a matching, current R4-M08 acknowledgement exists; the single provider owns its writer lock; and the preview scene remains fail-closed. It refuses duplicate, stale, forged, missing-ACK, or unowned requests. `after_inventory`, `after_events` and `before_publish` faults discard candidate changes. The sink does **not** mutate Godot inventory, world events or persistent on-disk records.
- `tools/r4_m12_writer_audit.py` scans **58 Godot scripts** and records **nine known pre-M12 mutable QA interfaces**. These remain in the standalone project for inherited regression compatibility. The audit is an honest catalog of unresolved legacy imports, not a security sandbox or a universal enforcement guarantee.
- Additive Godot scene, native route test, two-seed cross-process SIGKILL harness, 12 engine screenshots and the full inherited regression report.

## 2. Native verification (fresh, non-overlapping assertion totals)

| Test group | Independent assertions | Result |
|---|---:|---|
| R4-M12, three native seed/screen runs (41/4; 4096/5; 800000/6) | 375/375 | PASS |
| R4-M12, two writer SIGKILL/recover/replay matrices (41/4 and 800000/6; 21+11 assertions each) | 64/64 | PASS |
| 23 inherited Godot suites, including M11/M10/M09 and S23–S32 | 7,601/7,601 | PASS |
| **Total** | **8,040/8,040** | **PASS** |
| Native 960×540 screenshots | 12/12 | PASS |
| Python static audit | 58 scripts, 9 legacy write interfaces | PASS (findings explicitly retained) |

The three new native route tests traversed **72/72** adjacent elevated links in aggregate with the real S33 CharacterBody2D (-410 jump, 1050 gravity, 220 walk). They include 3×3 explicitly compensated sandbox-fault injections (nine per route, 27 total), exact receipt balances, source corruption/forgery negatives, route signature mismatch and a no-spawn gate.

Two subprocess tests used actual `SIGKILL` after TX generation 2 was committed but ACK remained pending. A fresh process refused the stale lock until an explicit *test-only* cleanup, revalidated the saved checkpoint and native floor, acknowledged the pending receipt, reconstructed the v2 sandbox and finished normal platform movement. A third process replayed the same ledger without duplicating ACKs. These tests do **not** simulate electrical power loss or guarantee filesystem persistence under hardware failure.

The remaining legacy writers are intentionally **not removed**. An adversarial or unmanaged same-process script can still directly import older Godot classes, so R4-M12 does not certify universal repository-wide write mediation. The QA v2 checksum is neither an authenticated signature nor an external transaction protocol.

## 3. Explicit unaccepted production requirements

Real-game checkpoint HUD and death/respawn design; production gameplay event sink; save format v2 durable migration and rollback; cross-process durable writer coordination; validated filesystem `fsync` and power-loss guarantees; original complete game integration; malicious local-file tamper resistance; human playtest and production GPU performance. All remain OPEN. The protected S33 archive and original game were **not modified**.

## 4. Evidence and reproduction

Use `Godot_v4.7.2-stable_linux.x86_64`:

```bash
godot --headless --path . --editor --quit
godot --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 41 4
godot --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 4096 5
godot --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 800000 6
python tools/r4_m12_writer_audit.py
python tools/r4_m12_regressions.py
```

`tools/r4_m12_sigkill_matrix.py` intentionally terminates *only its own isolated Godot child processes*. Do not run it against personal or production save locations. Native captures are in `captures/r4_m12_engine/`; JSON evidence is in `reports/`.
