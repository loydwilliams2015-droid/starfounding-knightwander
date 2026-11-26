# SK-ENG-R1-C04 — Remote ZIP discovered; exact Git object verified

**Date:** 2026-11-25. **Scope:** standalone Godot SCALE/ART QA, not the original playable Starfounding Knightwander game.

## Repository custody finding

The full ZIP was independently discovered in the recursive Git tree of `main` at repository **root**:

- `SK_SCALE_0_3_S33_patch.zip` (147,501 bytes)
- GitHub blob SHA-1: `e064e6024952b9de79d067ee85ba197ca513759e`
- Independently computed Git blob SHA-1 from original local ZIP bytes: **same hash**
- Local archive SHA-256: `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`
- ZIP CRC check: PASS; 172 ZIP entries
- 168 original source files in embedded manifest: **168/168 exact SHA-256 + byte-length matches**, zero missing

This provides Git-object byte-identity evidence for the upload. It does **not** mean the full ZIP was separately downloaded from GitHub and rehashed with SHA-256 in this run. Avoid describing the archive as the original full playable SK game.

## Fresh local recovery execution

Extracted the matched S33 archive into a disposable directory and imported it under **Godot 4.7.2**, exit status 0. Then ran the seven native standalone regression suites:

| Suite | Result |
|---|---:|
| S32 camera ownership | 76/76 |
| S31 repeated crouch/stand transitions | 46/46 |
| S30 jump-camera | 15/15 |
| S29 corridor traversal | 15/15 |
| S28 player-input movement | 22/22 |
| S27 camera/parallax | 128/128 |
| S23 animation/collider | 19/19 |
| **Total** | **321/321** |

All suite processes exited 0. These are local tests of the byte-identical ZIP, **not GitHub Actions logs**.

## Workflow correction and disposition

The previous custody workflow checked `qa/scale-art/archive/SK_SCALE_0_3_S33_patch.zip`; that directory is not the actual upload location. Corrected both trigger and validator input to **`SK_SCALE_0_3_S33_patch.zip`** on repository root.

**R1 remote artifact presence and Git blob match: PASS.**

**R1 fresh GitHub download with independent SHA-256, GitHub Actions success and full production-project integration: OPEN.** Do not claim those gates were executed.

**Next spiral candidate:** R2 world/map procedural route, gated on maintaining the S33 standalone source baseline. The original full project remains unavailable and separate. Any new map experiment must not overwrite this archive.
