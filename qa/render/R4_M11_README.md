# SK R4-M11 — single provider / checkpoint + ACK integration QA

A complete **standalone Godot 4.7.2** QA project derived from R4-M10. The original playable game and protected S33 zip have not been overwritten.

## Open

In Godot 4.7.2, import the extracted directory and open the default scene `res://scenes/r4_m11_provider_review.tscn` (960×540). Use **A/D** to move, **SPACE** to jump, **F1–F4** to preview procedural material districts and **M** to toggle reduced motion.

The scene previews the S33 knight and R2 generated collision-bearing platforms. Checkpoint transactions in this milestone are driven by native QA tests and do not modify real player inventory.

## Native test commands (Linux)

Set `GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64`, from this directory:

```bash
$GODOT --headless --path . --editor --quit
$GODOT --headless --fixed-fps 60 --path . --script res://tests/r4_m11_provider_test.gd -- 41 4
$GODOT --headless --fixed-fps 60 --path . --script res://tests/r4_m11_provider_test.gd -- 4096 5
$GODOT --headless --fixed-fps 60 --path . --script res://tests/r4_m11_provider_test.gd -- 800000 6
$GODOT --headless --fixed-fps 60 --path . --script res://tests/r4_m10_gateway_test.gd -- 41 4
```

The `tests/r4_m11_cross_process.gd` script is a multi-process writer/probe/resume/replay fixture. **Do not SIGKILL or delete lock files on your own data.** Its external orchestration was tested on isolated `r4m11_test_` namespaces; see `reports/R4_M11_SIGKILL_MATRIX.json` and `docs/R4_M11_PROVIDER_CLOSEOUT.md`.

## Captures

The real engine images are under `captures/r4_m11_engine/`. `R4_M11_ELEVEN_FRAME_NATIVE_REVIEW.png` is a contact sheet and `R4_M11_RECOVERY_COMPARISON.png` is a two-panel comparison. All source frames are preserved individually.

## Change boundary

New: `scripts/r4_m11_provider.gd`, `scripts/r4_m11_stage.gd`, `scenes/r4_m11_provider_review.tscn`, and `tests/r4_m11_provider_test.gd`, `tests/r4_m11_cross_process.gd`, `tests/r4_m11_capture.gd`. Existing gameplay physics and real item/event lists are untouched. QA permits/locks are **not** unforgeable across arbitrary same-process Godot scripts. No production power-loss guarantees are asserted.

See `reports/R4_M11_VERIFICATION.json` and `docs/R4_M11_PROVIDER_CLOSEOUT.md` for the full acceptance boundary.
