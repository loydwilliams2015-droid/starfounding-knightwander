extends "res://scripts/r4_m04_stage.gd"
const STRICT=preload("res://scripts/r4_m05_journal.gd")
var recovery_audit:Dictionary={"valid":false}
func _ready()->void:
    super._ready()
    r4_info.text="R4-M05 journal recovery | QA only | items/events locked"
func report_recovery(record:Dictionary,verification:Dictionary)->void:
    recovery_audit=verification.duplicate(true)
    if verification.get("passed",false):
        mark_checkpoint(record)
    else:
        checkpoint_mode="REJECTED"
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
    r4_info.text="R4-M05 %s / pad %d | GAMEPLAY LOCKED"%[
        "RESTORED" if verification.get("passed",false) else "REJECTED",
        int(record.get("pad_index",-1))]
