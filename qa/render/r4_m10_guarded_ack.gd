extends "res://scripts/r4_m08_outbox.gd"
## ACK writes need a coordinated permit even if the writer lock is held.
var permit_ack: bool = false
var denied_direct_acks: int = 0
func _set_permit(value: bool) -> void:
    permit_ack = value
func acknowledge(stage: Node2D, tx: RefCounted, adapter: RefCounted, fault: String = "none") -> Dictionary:
    if not permit_ack or not holds_writer():
        denied_direct_acks += 1
        return {"passed": false, "reason": "R4-M10 mandatory acknowledgement gateway required", "spawn_authority": false}
    return super.acknowledge(stage, tx, adapter, fault)
