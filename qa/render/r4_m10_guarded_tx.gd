extends "res://scripts/r4_m06_transaction.gd"
## R4-M10 mandatory coordinator permit for this QA transaction writer.
## Only the new gateway's wrapper is allowed to persist checkpoints.
var gate: RefCounted
var permit_commit: bool = false
var denied_direct_writes: int = 0
func bind_gate(writer: RefCounted) -> void:
    gate = writer
func _set_permit(value: bool) -> void:
    permit_commit = value
func commit_from_actor(stage: Node2D, entry: Dictionary, prefix: Array, fault_mode: String = "none") -> Dictionary:
    if gate == null or not gate.holds_writer() or not permit_commit:
        denied_direct_writes += 1
        return {"passed": false, "reason": "R4-M10 mandatory transaction gateway required", "spawn_authority": false}
    return super.commit_from_actor(stage, entry, prefix, fault_mode)
