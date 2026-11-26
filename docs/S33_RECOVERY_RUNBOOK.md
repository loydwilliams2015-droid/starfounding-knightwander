# S33 recovery runbook

**Canonical scope:** Starfounding Knightwander SCALE/ART *standalone QA*; not the original full game.

1. Retrieve `SK_SCALE_0_3_S32_patch.zip` and compare with `provenance/S33_SOURCE_MANIFEST.md` (SHA-256).
2. Use the Godot 4.7.2 Linux executable (or corresponding platform release).
3. Run `python3 qa/scale-art/tools/s33_restore_verify.py SK_SCALE_0_3_S32_patch.zip --godot /path/to/godot`.
4. Expect seven independent suites: S23, S27, S28, S29, S30, S31, S32. Report failures with exact test names; do not quietly replace a failed test with a source assertion.
5. For S33 full archive, inspect `S33_FILE_MANIFEST.json` (all 168 original source file SHA-256 digests) and `S33_VERIFICATION.json` (the checked native result).
6. Keep Godot's generated `.godot/` import cache out of source control. Retain source PNGs, scenes, GDScripts, manifests, and `.uid` files.

**Important:** The GitHub repo currently contains documentation/test source, not the full standalone QA tree. To complete high-fidelity cross-chat recovery, upload the exact S33 ZIP and confirm the remote blob's bytes, or import every tracked source asset and verify the file manifest. Do not overwrite the original full playable game.
