# SK-ENG-R1-C05 — Archive relocation and source custody

**Date:** 2026-11-25. **Scope:** SCALE/ART standalone Godot QA S33. The original playable game is not part of this archived source.

## Executed GitHub change

- Moved `SK_SCALE_0_3_S33_patch.zip` from repository root to **`qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip`** using one Git tree/commit: `8a5e826fd9617ecb37d0c4ff827f4128ecedfff6`.
- Git tree lists exactly one file with that name, at the target path; the root file is absent.
- Original and relocated Git blob SHA-1: `e064e6024952b9de79d067ee85ba197ca513759e`; the move reused the existing blob without re-encoding the bytes.
- Recorded blob size: **147,501 bytes**.
- Independent local calculation of Git object hash from the original bytes matches the relocated GitHub tree entry.
- Local S33 archive SHA-256: `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`.
- Archive CRC: PASS; 172 entries; embedded original-source manifest **168/168 exact file lengths and SHA-256**, zero missing/mismatch.
- Updated `.github/workflows/scale-art-source-custody.yml` to trigger on the correct nested path and validate that same path.
- No game controller, camera, sprite, collision, parallax, or audio behavior was modified.

## Acceptance boundaries

**PASS:** Target path, source blob byte identity, root path removal, local exact archive + source integrity, corrected CI configuration.

**NOT YET VERIFIED:** A completed GitHub Actions workflow run, independent remote binary download with its own SHA-256, fresh native Godot tests from an independently cloned GitHub working tree, and original playable project integration. Last evidenced native suite remains R1-C04 **321/321** from the locally matched archive. Do not misstate these as new C05 test executions.

## Next spiral

The R1 remote placement gate is closed. The next work can schedule a fresh CI gate and bounded R2 seeded reachability prototype while keeping `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip` immutable as the validated S33 baseline. All new content must use a new path or branch.
