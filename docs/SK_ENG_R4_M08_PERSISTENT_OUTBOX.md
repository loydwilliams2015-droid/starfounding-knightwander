# R4-M08 — Persistent read-only event acknowledgements

**Acceptance:** PASSED for standalone QA, 2026-11-26.

Our checkpoint is a **route-verified grounded state plus an exactly matched local QA ledger**. R4-M08 adds a *separate acknowledgement record*, but only after the R4-M07 display adapter has published the corresponding committed transaction. The delivery record is bound to the complete ordered receipt list, route identity, S33 controller identity, transaction SHA-256 digest, pad and generation. Retried acknowledgements are idempotent. Invalid, partial, unlinked and stale records cannot acknowledge newer receipts.

**Key distinctions:** 'Committed' describes the QA checkpoint transaction; 'delivered' describes an in-memory read-only projection; 'ACKed' describes an independently serialized metadata record. None of these authorizes a production game item, world event or externally irreversible action.

**Tests:** 285 new assertions over three native routes, 32 new assertions in a three-process write→reopen→replay scenario, and 7,243/7,243 inherited assertions (19 suites); total **7,560/7,560**. Three distinct process-lock probes passed, including real SIGKILL and stale lock retention. Ten real engine screenshots. The full runnable test suite, assets and report are supplied in the ZIP, not completely mirrored into GitHub.

**Intentional fail-closed limitations:** The directory lock is advisory to participating outbox writers only; it does NOT yet coordinate R4-M06 transaction writers. After a crash the lock is left stale for explicit operator recovery. Two-slot ACK history prefers rejecting ambiguous recovery over silently accepting incomplete state. No signed authentication, cross-host consensus, fsync barriers or live production-game transactions have been established. Protected S33 assets and the full playable original game remain unchanged.
