# SK-ENG-C01 — SCALE/ART closeout and spiral rotation

**Proposed closeout policy · 2026-11-25.** Scope: S2–S33 **standalone Godot SCALE/ART QA**, not the original playable SK game. Grounding: S33 clean-room verification (seven suites, 321/321 assertions); complete S33 ZIP bytes remain outside GitHub. [S33 provenance](../provenance/S33_SOURCE_MANIFEST.md).

## Decision rule
- **CLOSED-QA**: standalone native acceptance evidenced, not production certified.
- **CLOSED-PRODUCTION**: actual playable game integrated and independently accepted (none yet).
- **DEFERRED**: worthwhile, assigned a next engine and reentry gate.
- **BLOCKED**: required source, proof, or verified backup missing.
- **REJECTED**: deliberately excluded with append-only justification.

## Closeout ledger
| Item | Disposition | Return condition |
|---|---|---|
| Dedicated crouch texture, correct anchor, collider/headroom, input reversal | CLOSED-QA | Integrate separately into original game |
| Profile A key-pose timing, original reference sprites, atlas/GIF traceability | CLOSED-QA | Approved art + gameplay-scale review |
| Four-layer parallax, staged lighting and corridor traversal | CLOSED-QA | Original-game environment integration |
| Horizontal/vertical camera look-ahead and diagnostic handoff | CLOSED-QA | Original-game camera acceptance |
| Complete GitHub backed-up source/assets | BLOCKED | Upload actual ZIP or tree, download and compare SHA-256 |
| Original SK playable project integration | BLOCKED | Obtain original project, verify merge and regression |
| Final knight sprite and animation | DEFERRED | Approved artwork + human art review |
| Procedural route/world continuity | DEFERRED | Deterministic reachable 4–6-screen route |
| Production lighting/performance, event/magic, audio, UI, saves | DEFERRED | Domain vertical-slice test and production evidence |

## Five-run closeout
1. Freeze S33, inventory evidence and preserve all original-art provenance.
2. Back up **actual bytes**, verify GitHub download and source-tree SHA-256. If unavailable, leave BLOCKED.
3. Clean import in Godot 4.7.2; rerun S23/S27/S28/S29/S30/S31/S32 native suites, baseline **321/321**.
4. Check real Godot 960×540 screenshots, foot anchoring, silhouette, parallax scroll, crouch under ceiling; distinguish reference art from approved art.
5. Publish the ledger, decisions and acceptance evidence; advance to the spiral without reopening settled QA.

**Conditional QA exit** is allowed after evidence + decision ledger even while full remote backup is BLOCKED. Never call it a fully certified or recoverable game build.

## Spiral engine rotation — one bounded run each
| Round | Engine | Minimal acceptance |
|---|---|---|
| R1 | Repository / build / integration | Fresh clone restores all source and passes Godot tests |
| R2 | World / map / procedural | Seeded, validated 4–6-screen reachable route |
| R3 | Character animation / SCALE-ART | Profile A approved art, continuous foot anchor |
| R4 | Renderer / parallax / lighting | Representative layer readability + frame pacing |
| R5 | Camera / physics / input | Run/jump/crouch/reverse on continuous route |
| R6 | Events / puzzles / magic | One pickup → event → spell → consequence loop |
| R7 | Audio / UI feedback | One synchronized, accessible loop |
| R8 | Persistence / QA | Save, reload, replay, automated smoke test |

Each run: **one small change, native test, evidence capture, named open risk, commit hash, next engine**. On cycle two, raise integration depth from standalone to paired to integrated vertical slice. For an unverified source or failed regression, pause feature expansion at that engine's gate. Do not overwrite established parallax, procedural play, lighting or controls to make isolated QA pass.

**References:** Mega Man X4 is primary for decisive character poses and readability; Dead Cells secondary for animation and atmosphere. Yoshi, Kirby and Tales of Phantasia remain bracketed from current SCALE/ART grading.

**Immutable provenance:** Full S33 local ZIP SHA-256 `5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283`. The complete closeout program and machine-readable ledger are in the separately provided C01 ZIP, not implied to be in this repository.
