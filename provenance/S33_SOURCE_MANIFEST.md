# SK SCALE/ART S33 — verified recovery checkpoint

Source: canonical standalone S32 Godot QA package; **not** the original playable SK project.

- Exact source S32 ZIP SHA-256: `556bdb4e1370306cdbcfc3777bf24ec7b060fca5d772bd3eb24461c5b4437b0b`
- Local S33 ZIP SHA-256: `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`
- S33 ZIP member count: 172. ZIP CRC integrity: passed.
- Byte-level original source inventory: 168 files (full JSON manifest included within local S33 archive).
- Godot version: 4.7.2; imported from a **fresh temporary extraction**.
- Actual native results: S32 76/76, S31 46/46, S30 15/15, S29 15/15, S28 22/22, S27 128/128, S23 19/19; **321/321 checks** across seven suites.
- No approved final character art, original full-game integration, production optimization, or continuous gameplay capture certified.

## Cross-chat fidelity boundary

The full S33 archive remains a separate conversation artifact; its hash and validator **do not substitute for actual source bytes in GitHub**. The GitHub repository carries the verifier and exact provenance, but it is not yet a complete recoverable project clone.

Use `qa/scale-art/tools/s33_restore_verify.py` on the exact S32 ZIP. Do not claim success for a new artifact unless its SHA-256 and native test results match.

The complete S33 ZIP can be uploaded through GitHub's file-upload UI from a phone or by a trusted authenticated Git transport. Once uploaded, re-fetch and compare the SHA before marking the cross-chat backup complete.
