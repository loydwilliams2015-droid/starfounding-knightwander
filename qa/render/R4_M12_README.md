# Starfounding Knightwander · R4-M12 v1/v2 checkpoint view + sandbox event sink

**Standalone Godot 4.7.2 QA project.** The original full game and protected S33 archive are unchanged.

Run `res://scenes/r4_m12_versioned_sink_review.tscn` in Godot 4.7.2. The knight's controls are A/D move, SPACE jump, F1–F4 district material previews, M reduced motion. The upper route uses native S33 character physics and physically colliding R2 platforms. There is no production gameplay inventory or event spawning in this project.

New code: `scripts/r4_m12_migration.gd`, `scripts/r4_m12_sandbox_sink.gd`, `scripts/r4_m12_provider.gd`, and `scripts/r4_m12_stage.gd`. The v2 projection is constructed from a **validated, already-committed v1 transaction** and is **not a new persisted format**. The sandbox sink is an in-memory, read-only QA projection, not an official game event consumer. Legacy direct writer classes remain available for regression compatibility; a static audit inventories the exposure.

## Native tests

```
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --editor --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 41 4
Godot_v4.7.2-stable_linux.x86_64 --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 4096 5
Godot_v4.7.2-stable_linux.x86_64 --headless --fixed-fps 60 --path . --script res://tests/r4_m12_migration_sink_test.gd -- 800000 6
python tools/r4_m12_writer_audit.py
python tools/r4_m12_regressions.py
```

Two cross-process `SIGKILL` recovery fixtures are driven by `tools/r4_m12_sigkill_matrix.py` **in disposable test namespaces only**. The native screenshot script uses an Xvfb OpenGL/Mesa software renderer and writes twelve 960×540 images under `captures/r4_m12_engine/`.

Results: **8,040/8,040 native Godot assertions** (375 new route, 64 kill/recovery, 7,601 inherited), **12/12 native screenshots**, and a separate 58-script static dependency audit. See `docs/R4_M12_MIGRATION_SINK_ACCEPTANCE.md`, `reports/R4_M12_VERIFICATION.json`, and integrity manifests.

These results do **not** certify power-loss-safe storage, production event effects, true security isolation, original-game integration, or an actual v2 saved-file migration. This is a reproducible QA milestone only.
