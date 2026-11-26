# Starfounding Knightwander — R3-M05 closeout / R4-M00 renderer handoff

**Build:** S33-derived *standalone* Godot 4.7.2 SCALE/ART QA, November 26, 2026. Not the full original playable game, nor the R2 procedural map.

## Run

On Linux with Godot 4.7.2: open this folder as a Godot project and import all source textures (the editor must finish its initial import). Launch the configured scene `scenes/r4_m00_render_review.tscn`. WASD/Arrow controls and character actions remain those of the underlying S33 source. Press `M` or click **Reduce motion** to suppress decorative rotation, parallax and camera anticipation. This setting is session-only.

The new script `scripts/r4_m00_stage.gd` inherits the R3-M04 accessibility layer, adds two visual-only lamps at fixtures visible in the S33 preview, and applies **four material palettes × two light roles**:

- Stone: cool neutral lamp; timber: warmer amber; relicwright: teal; industrial: steel-blue.
- `diffuse`: quiet fill; `beacon`: localized, brighter light. The actor reference textures and modulate are preserved.
- Lighting modes are *static* and compatible with reduced motion. They do not construct platforms, grant passability or spawn items/events.

## Automated checks

```sh
GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
"$GODOT" --headless --path . --editor --quit   # initial asset import
"$GODOT" --headless --path . --script res://tests/r3_m05_closeout_test.gd
"$GODOT" --headless --path . --script res://tests/r4_m00_render_contract_test.gd
python tests/run_r3_m05_closeout.py           # all 12 suites; edit GODOT path if necessary
```

For native capture on Linux, `xvfb-run -a -s '-screen 0 960x540x24' env GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy --script res://tests/r4_m00_capture.gd`.

Fresh evidence: **12/12 suites, 1,032/1,032 assertions**, plus nine Godot 960×540 native captures. Reversible UI, source texture identity, camera ownership, unchanged gameplay colliders, and prior S23–S32 motion regressions passed.

## Source custody / engineering gates

- R3 is **conditionally closed for standalone animation QA** (poses, controller-mediated motion, decorative hierarchy, accessibility).
- Original playable Starfounding Knightwander integration **not complete**.
- R2 full four-to-six-screen uninterrupted traversal, checkpoint recovery, and final gameplay item/event spawn authorization **open**.
- Actual R2 stone/timber/relicwright/industrial meshes **not yet integrated**. Captures use the same S33 urban debug backdrop with palette grades.
- Human art approval, authorized production character art, persistent reduced-motion preference, and hardware GPU profiling **open**.
- This archive is distinct from and does not modify the protected S33 source-custody archive.

See `docs/R3_M05_CLOSEOUT_R4_M00_HANDOFF.md` and `reports/R3_M05_R4_M00_VERIFICATION.json` for exact gates and evidence.