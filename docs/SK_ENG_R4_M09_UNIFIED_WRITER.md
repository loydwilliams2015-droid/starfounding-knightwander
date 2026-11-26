# R4-M09 acceptance — unified participating-writer protocol

**Decision: PASS for standalone QA on November 26, 2026.**

The checkpoint model is an exact native S33 route landing history plus a local two-slot checkpoint/inventory/event QA record, an idempotent read-only adapter and an independent two-slot ACK journal. R4-M09 adds a coordinator requiring **one filesystem lock across transaction commit and subsequent ACK**, with an explicit blocker on committing a later transaction before the earlier one is acknowledged.

### Evidence / gates

1. No writer ownership → no checkpoint transaction and no ACK. Contender denied during ownership and after SIGKILL until test-only operator cleanup.
2. Grounded native actor and valid route+controller+receipt evidence required before commit. No change to S33 gravity, jump, camera or actual platform colliders.
3. Committed TX remains pending until valid ACK. Failed ACK temp writes do not advance durable ACK; replaying ACK is idempotent.
4. A separate process recovers a previously committed unACKed TX and continues native route traversal without duplicating a QA reward.
5. Actual item/event spawning is always locked. No production reward authority is conferred by any QA certificate.

New native tests 249/249; real termination and cross-process recovery 23/23; inherited 20 suites 7,338/7,338. Total 7,610/7,610 checks. Ten authentic Godot 960×540 engine renders.

**Limitations:** Participants can bypass the new lock by calling old core writer APIs directly. Same-machine `mkdir` is not cross-host consensus. An unclean shutdown leaves a stale lock requiring explicit operator review. No durable fsync barriers, physical power-loss proof, production authentication, external side-effect compensation or original-playable-game integration. This milestone is not production certified.
