# R4-M07 · Event adapter and checkpoint architecture gate

**Status:** PASS (bounded standalone QA). Date: November 26, 2026.

## Verified implementation
One authoritative-for-QA checkpoint journal contains route progress plus simulated reward receipts and inspected event outcomes. Only after journal validation and checkpoint projection restoration may `R4M07EventAdapter` materialize its isolated event view. A receipt ID is `qa_observation_pad_XX`; the adapter requires ordered unique IDs, matching event outcomes, a +1 balance per receipt, route/controller match, sequential generation, committed digest continuity, and an enabled gameplay-spawn *lock*. Repeated exact delivery does nothing. Faults drop staged private state; they never touch real inventory or events.

The adapter's projection is derived from the committed record, not a second independently persisted store. This design avoids double-reward risk on process restart, but is not general-purpose two-phase commit, exactly-once external side effects, or compensation of irreversible operations.

**Evidence:** three native route seed/screen configurations: 41/4, 4096/5, 800000/6; 177/177 assertions. Two real SIGKILL tests at pre-rename and post-commit phases, with separate native readers and route continuation: 28/28. Eighteen inherited suites: 7,184/7,184. Total 7,389/7,389, zero failures. Ten native Mesa/Xvfb OpenGL screenshots (not manually certified production art).

## Checkpoint model
Native landing evidence → route-and-controller validation → serialized checkpoint, ledger, events and generation checksum as one record → rotating A/B on-disk slots → revalidated recovery position and floor contact → reconstructed isolated event UI. QA transaction commit does not imply any production-spawn authorization.

## Explicit open obligations
There is no player death/respawn save-policy UX, no checkpoint persistence into the original full Godot game, no concurrent writer lease, no hostile-file authenticity guarantee, no real power-loss durability test, and no transaction boundary encompassing an external gameplay system. Original S33 source and protected archive remain unchanged. First production integration must define event source/ownership and an idempotent gameplay sink before enabling item or event spawning.
