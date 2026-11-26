# Cross-chat project handoff

**Repository:** `loydwilliams2015-droid/starfounding-knightwander`

**Integrity protocol:** Always retrieve the actual file content, repository commit ID and manifests before claiming a version is present. Chat statements are not Git backups. Check any S30 ZIP against the SHA-256 published under `provenance/`.

**Milestones:** S2–S24 focus on dedicated crouch sprites, Profile A key-pose animation and native engine QA. S25–S30 add an original layered-parallax demonstration scene, dynamic lighting, player-input motion, extended traversal, horizontal and vertical camera anticipation. S30 represents an independently verified *standalone* Godot QA scene, not the integrated full game.

**SCALE/ART references:** Mega Man X4 is primary for deliberate readable key poses and platforming precision; Dead Cells is secondary for animation continuity and atmosphere. Yoshi/Kirby/Tales of Phantasia influences are bracketed out of current grading.

**Provenance caveat:** S30 ZIP's hash and inventory are published, but the full ZIP/source tree must still be uploaded for an actual high-fidelity GitHub backup. Its source artwork is reference-only. Original game completeness and previously approved production art are not verified.

**Next integration process:** import complete original SK project separately from `qa/scale-art` without overwriting existing game systems; compare incoming assets byte-for-byte; run Godot 4.7.2 native regressions and capture tests; record the resulting commit hash and evidence.
