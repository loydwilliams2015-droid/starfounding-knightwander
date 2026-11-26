extends "res://scripts/r4_m09_coordinator.gd"
## R4-M10 mandatory enforcement INSIDE this coordinator's writer objects.
## Legacy R4-M06/R4-M08 raw classes remain importable by earlier QA suites.
const GUARDED_TX = preload("res://scripts/r4_m10_guarded_tx.gd")
const GUARDED_ACK = preload("res://scripts/r4_m10_guarded_ack.gd")
const READER_ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
var gate_denials: int = 0
func configure(name: String) -> void:
    assert(name.is_valid_filename() and name.begins_with("r4m10_"))
    tx = GUARDED_TX.new()
    tx.configure("r4m06_" + name)
    outbox = GUARDED_ACK.new()
    outbox.configure("r4m08_" + name)
    tx.bind_gate(outbox)
    adapter = READER_ADAPTER.new()
    configured = true
func reset_test_only() -> void:
    assert(configured and not owns() and not DirAccess.dir_exists_absolute(outbox.lock_path()))
    assert(outbox.folder.contains("/r4_m08/r4m08_r4m10_"))
    tx.reset_test_only()
    outbox.reset_test_only()
func guarded_commit(stage: Node2D, entrance: Dictionary, prefix: Array, fault: String = "none") -> Dictionary:
    if not owns(): return _deny("mandatory gate: no writer ownership")
    tx._set_permit(true)
    var result: Dictionary = super.guarded_commit(stage, entrance, prefix, fault)
    tx._set_permit(false)
    return result
func guarded_deliver_and_ack(stage: Node2D, fault: String = "none") -> Dictionary:
    if not owns(): return _deny("mandatory gate: no writer ownership")
    outbox._set_permit(true)
    var result: Dictionary = super.guarded_deliver_and_ack(stage, fault)
    outbox._set_permit(false)
    return result
func snapshot(route: Dictionary) -> Dictionary:
    var data: Dictionary = super.snapshot(route)
    data["mandatory_in_r4m10"] = true
    data["direct_tx_denials"] = tx.denied_direct_writes
    data["direct_ack_denials"] = outbox.denied_direct_acks
    data["production_spawns"] = false
    return data
