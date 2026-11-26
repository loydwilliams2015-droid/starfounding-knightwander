# SK-ENG-R1-C03 — source custody handoff

**Scope:** standalone Godot SCALE/ART QA only. The original playable SK repository/project has not been recovered.

## Executed, local
- Repackaged actual S33 ZIP bytes into a user-downloadable custody bundle (not merely a manifest).
- C03 audit: ZIP CRC pass, exact S33 SHA-256 pass, **168/168 original source members** verified against the embedded per-file SHA-256 manifest; zero mismatches.
- Exact S33 SHA-256: `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`.
- Native 321/321 baseline remains **C02's** last fresh clean-import result; C03 makes no claim of an additional fresh native run.

## Outstanding remote acceptance
**BLOCKED.** The actual S33 ZIP has not yet been uploaded to GitHub or downloaded from a GitHub commit. The file `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip` is the intended binary custody destination.

The user can download the C03 bundle, extract `SK_SCALE_0_3_S33_patch.zip`, and upload it via the repository's GitHub browser file-upload interface. GitHub cannot interpret a written checksum as bytes.

Once it exists, obtain a fresh remote download, run:
```bash
python3 qa/scale-art/tools/r1_c03_verify_archive.py SK_SCALE_0_3_S33_patch.zip
```
Then clean-import with Godot 4.7.2 and run the seven suites (minimum acceptance **321/321**). Only then close R1 remote source custody and advance the engine spiral to R2 world/map.

**No feature expansion:** This phase changes source stewardship rather than the accepted camera/parallax/animation gameplay logic.
