# Starfounding Knightwander — R4-M05 checkpoint lifecycle QA

**2026-11-26 | Godot 4.7.2 | Standalone S33/R2 test project** — not the full playable game.

## Run
Open `project.godot` with Godot 4.7.2 (allow the initial texture import), then run `scenes/r4_m05_checkpoint_review.tscn`.
Movement remains S33; F1–F4 district inspection and `M` reduced-motion retain their behavior.

```bash
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m05_fault_test.gd -- 41 4
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m05_fault_test.gd -- 800000 6
# Cross-process checkpoints require separate invocations:
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m05_cross_process_test.gd -- write 41 4
GODOT_SILENCE_ROOT_WARNING=1 godot --headless --fixed-fps 60 --path . --script res://tests/r4_m05_cross_process_test.gd -- read 41 4
```

## What changed
- Added a strict layered two-slot checkpoint reader: invalid slot parity, generation gaps, broken previous-digest links and altered historical prefixes fail closed rather than admitting a self-consistent but invalid record.
- A remaining non-genesis record alone is insufficient for recovery. This is a conservative **availability tradeoff**, not proof of crash durability.
- Commit from gameplay scene requires a live grounded, non-moving (vertically) S33 body, valid pose/collider geometry and a closed spawn gate. Checkpoint restore now includes native floor confirmation after a physics step.
- Simulated process interruptions at before-open, partial temp write and completely written pre-rename temp boundaries. They never replace committed files. No actual OS power cut/fsync guarantee is claimed.
- Six native route seeds across 4, 5 and 6 screens finish from a pad-15 checkpoint; two distinct-OS-process read/reopen demonstrations pass. Original R4-M04 and earlier S23–R4-M03 regressions checked.
- Nine actual 960×540 Godot screenshots and a review contact sheet and GIF. Gameplay pickups and events remain forbidden.

**Fresh verification:** **7,388 / 7,388 native assertions**, zero failures; source counts and per-suite log references in `reports/R4_M05_VERIFICATION.json`. The new suite contributes **276**; the separate-process reopen contributes **30**; R4-M02/M03/M04 regression suites contribute **1,610**; 13 inherited animation/camera/render suites contribute **5,472**. This count does not double-count clean-extraction reruns.

## Limitations
Files are stored under `user://r4_m04/r4m05_*` in local QA namespaces. Test setup deletes only its own named journal. A SHA-256 digest is an accidental-corruption check, not a secret MAC or signed save. Hostile edits with recomputed digests are outside this scope. No power-loss test, directory fsync, official game save schema, event transactions, manual UI, or production environment attestation. The S33 source ZIP is protected and unchanged; original playable-game integration remains open. **R4-M05 is a QA module, not a production save certification.**

**Next:** R4-M06 deterministic gameplay event authorization and checkpoint transaction boundary, after original-game integration and an explicit acceptance protocol; do not instantiate actual items/events from a QA-only path certificate.