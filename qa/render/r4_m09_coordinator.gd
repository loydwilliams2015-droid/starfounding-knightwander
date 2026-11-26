extends RefCounted
## R4-M09 participating-writer protocol for BOTH the R4-M06 TX and R4-M08 ACK.
## Same-directory mkdir lock is held across checkpoint commit AND acknowledgement.
## Legacy direct calls can bypass this adapter; this is bounded standalone QA.
const TX = preload("res://scripts/r4_m06_transaction.gd")
const ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
var tx: RefCounted
var outbox: RefCounted
var adapter: RefCounted
var configured: bool = false
var acquired_operations: int = 0
var rejected_operations: int = 0

func configure(name: String) -> void:
    assert(name.is_valid_filename() and name.begins_with("r4m09_"))
    tx = TX.new()
    tx.configure("r4m06_" + name)
    outbox = OUTBOX.new()
    outbox.configure("r4m08_" + name)
    adapter = ADAPTER.new()
    configured = true

func acquire() -> Dictionary:
    if not configured: return {"passed": false, "reason": "coordinator not configured"}
    return outbox.acquire_writer()

func owns() -> bool:
    return configured and outbox.holds_writer()

func release() -> bool:
    return configured and outbox.release_writer()

func reset_test_only() -> void:
    assert(configured and not owns() and not DirAccess.dir_exists_absolute(outbox.lock_path()))
    assert(outbox.folder.contains("/r4_m08/r4m08_r4m09_"))
    tx.reset_test_only()
    outbox.reset_test_only()

func _deny(reason: String) -> Dictionary:
    rejected_operations += 1
    return {"passed": false, "reason": reason, "spawn_authority": false}

func _world_safe(stage: Node2D) -> bool:
    return is_instance_valid(stage) and stage.placement_gate.get("blocked", false) and \
        stage.placement_gate.get("items", []).is_empty() and \
        stage.placement_gate.get("events", []).is_empty()

func status(route: Dictionary) -> Dictionary:
    if not configured: return {"valid": false, "reason": "not configured"}
    var committed: Dictionary = tx.load_latest(route)
    if not committed.get("valid", false):
        return {"valid": false, "reason": "no committed or valid transaction", "has_writer": owns(), "gameplay_locked": true}
    var pending: Dictionary = outbox.pending(tx, route)
    if not pending.get("passed", false):
        return {"valid": false, "reason": "outbox invalid", "has_writer": owns(), "gameplay_locked": true}
    return {"valid": true, "generation": committed["record"]["generation"],
        "pad": committed["record"]["checkpoint"]["pad_index"],
        "pending": pending["ids"].size(), "pending_ids": pending["ids"].duplicate(),
        "has_writer": owns(), "gameplay_locked": true,
        "scope": "standalone QA only"}

func guarded_commit(stage: Node2D, entrance: Dictionary, prefix: Array, fault: String = "none") -> Dictionary:
    if not owns(): return _deny("unified writer lock required for TX")
    if not _world_safe(stage): return _deny("gameplay world authority opened")
    var prior: Dictionary = tx.load_latest(stage.route)
    if prior.get("valid", false):
        var pending: Dictionary = outbox.pending(tx, stage.route)
        if not pending.get("passed", false): return _deny("invalid ACK lineage")
        if not pending["ids"].is_empty(): return _deny("previous TX must be ACKed before next TX")
    var result: Dictionary = tx.commit_from_actor(stage, entrance, prefix, fault)
    if result.get("passed", false):
        acquired_operations += 1
        result["coordination"] = "TX_COMMITTED_ACK_PENDING"
        result["spawn_authority"] = false
    return result

func guarded_deliver_and_ack(stage: Node2D, fault: String = "none") -> Dictionary:
    if not owns(): return _deny("unified writer lock required for ACK")
    if not _world_safe(stage): return _deny("gameplay world authority opened")
    var disk: Dictionary = tx.load_latest(stage.route)
    if not disk.get("valid", false): return _deny("source TX invalid")
    var delivered: Dictionary = adapter.apply_verified(stage, tx)
    if not delivered.get("passed", false): return _deny("adapter did not verify committed QA projection")
    var result: Dictionary = outbox.acknowledge(stage, tx, adapter, fault)
    if result.get("passed", false):
        acquired_operations += 1
        result["coordination"] = "QA_DELIVERED_AND_ACKED"
        result["spawn_authority"] = false
    return result

func recover_scene(stage: Node2D) -> Dictionary:
    # Recovery only reads journals and verifies the native floor; no writer needed.
    if not _world_safe(stage): return _deny("unsafe world authority on recovery")
    return await tx.recover_scene(stage)

func snapshot(route: Dictionary) -> Dictionary:
    var s: Dictionary = status(route)
    s["writes"] = acquired_operations
    s["denials"] = rejected_operations
    s["production_spawns"] = false
    return s
