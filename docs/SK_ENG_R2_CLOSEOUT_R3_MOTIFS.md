# R2-M07 conditional closeout → R3-M00 spiral motifs

**2026-11-26.** Status: **CLOSED-QA** for deterministic layout, contextual joint/material/silhouette rules. **Not closed** for original-game integration, long-route physics or production art.

## Verified baseline
R2-M01 deterministic 4–6-screen routes; M02 real collider physics; M03 conservative spawning; M04 57/57 native edge landings for 3 four-screen seeds, with resets (not continuous play); M05 context-relevant visual joints; M06 four material families; M07 walkable-edge collision alignment and platform silhouettes. All evidence remains **standalone QA**. Protected S33 SCALE/ART ZIP is unchanged.

**Fresh closeout execution:** native Godot 4.7.2 M01 1,503/1,503, M02 143/143, M03 5,416/5,416, M06 72,630/72,630, M07 61,204/61,204, and R3 motif contract 23,548/23,548. **164,444/164,444 combined**. M04 and M05 native tests not rerun in this closeout; their previous evidence stays separate.

## Deferred and blocked
- D1/high: Continuous input-driven spawn-to-exit traversal and checkpoint reload (multiple seeds at 4, 5 and 6 screens).
- D2/high: Actual production item/event placement must fail closed for unverified routes.
- D3/medium: Distinguish cosmetic damage from real, nontraversable breaks in playtesting.
- D4/medium: Performance, reduced motion, biome art and human readability approval.
- B1: Original full playable SK source and standalone R2 full-archive remote custody not yet established. Do not overwrite or represent this QA as that project.

## Next spiral motif matrix
Four environmental palettes: stone, timber, relicwright, industrial. Six functions per palette: threshold, joint, cosmetic damage, wayfinding, character echo, material transition. Exactly 24 deterministic combinations. Every motif is **render-only**, no collision or spawn authority; never imply an unsupported walkable bridge. Character echo preserves Profile A bottom-center foot anchor.

A 1200×800 original procedural visual reference sheet is supplied in the **local standalone R3-M00 ZIP**, not in this GitHub commit.

### R3 Character Animation rotation
- **R3-M01:** test standing/crouch/recovery key poses in all four biome silhouettes, at multiple camera offsets.
- **R3-M02:** test running/jump/landing with the dynamic camera and texture filtering.
- **R3-M03:** cap scenery joint motion so it cannot distract from avatar action timing.
- **R3-M04:** reduced-motion variants and frame-time measurements.
- **R3-M05:** integrated vertical-slice proposal and explicit source/art integration blockers.

Each run publishes code, test counts, captures, known limitations and commit hashes; stop and defer where proof is absent.
