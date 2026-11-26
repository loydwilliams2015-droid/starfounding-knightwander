# SK-ENG-R4-M10 — Mandatory gateway boundary in standalone QA

**Acceptance: PASS, bounded.** All 7,694 native assertions across 3 new routes, 2 killed-writer recovery scenarios and 20 inherited suites passed. Ten native Godot captures plus comparison sheets. See `reports/R4_M10_VERIFICATION.json` and all native test scripts for reproducibility.

## Decision

The R4-M09 opt-in coordinator did not protect against direct calls to the R4-M06 checkpoint transaction writer while the same caller held the outbox lock. R4-M10 introduces guarded subclasses. Their overrides of `commit_from_actor` and `acknowledge` fail closed without BOTH ownership and a coordinator-issued short-lived operation permit. The R4-M10 coordinator instantiates these wrappers, never raw writer objects, and clears each permit immediately after the single synchronous write. It also enforces ACK completion before the next TX, preserves native route evidence, and keeps actual gameplay items/events locked.

## Executed failure and continuation cases

| Scenario | Observed committed state | Native continuation |
|---|---|---|
| TX2 prepared temporary file, then SIGKILL | TX1 + ACK1 | Redo 5→11, commit TX2 + ACK2; complete last 8 links |
| TX2 committed, ACK2 temp only, then SIGKILL | TX2, ACK1 | Restore pad 11, ACK2 once; complete route |

A competing process failed to acquire the lock while the writer was alive **and** when its lock directory remained after SIGKILL. An operator-only action cleared each isolated test lock. Successor sessions validated journal lineage and replayed ACK idempotently. These are process-termination tests and NOT physical power-loss tests.

## Restrictions

This is a deliberate **compatibility boundary**, not an unconditional claim of unbypassability: earlier direct writer scripts remain accessible, and trusted GDScript code could mutate the permit variables. The new API discourages accidental bypass, not adversarial behavior. Full production integration must replace those legacy entrypoints with an authority-owned dependency provider, decide on multi-process lock fencing and stale-lock adjudication, and prove fsync/directory durability. SHA-256 journals are not keyed authenticators; production reward authority and actual item/event spawning stay disabled.

## Next acceptance gate: R4-M11

Retire or seal legacy writer entrypoints for production-facing code, establish a single capability owner, and test duplicate delivery under concurrent producer/consumer contention. Decide whether the production game's expected semantics are checkpoint-local rollback or global exactly-once effects; do not assume the QA read-only adapter makes external effects atomic.
