extends "res://scripts/r4_m03_stage.gd"
const CHECKPOINT=preload("res://scripts/r4_m04_checkpoint.gd")
var checkpoint_state:Dictionary={"valid":false}
var checkpoint_mode:String="UNCOMMITTED"
func _ready()->void:
    super._ready()
    checkpoint_mode="UNCOMMITTED"
    r4_info.text="R4-M04 CHECKPOINT QA | native journey | gameplay spawns LOCKED"
func mark_checkpoint(record:Dictionary) -> void:
    checkpoint_state=record.duplicate(true)
    checkpoint_mode="COMMITTED pad %d"%int(record.get("pad_index",-1))
    r4_info.text="R4-M04 %s | gameplay spawns LOCKED"%checkpoint_mode
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
func checkpoint_snapshot()->Dictionary:
    return {"mode":checkpoint_mode,"pad":checkpoint_state.get("pad_index",-1),
        "native_foot":demo.actor.global_position,"controller":CHECKPOINT.PROOF.CONTROLLER_ID,
        "gameplay_spawns_locked":placement_gate["blocked"],"items":placement_gate["items"].size(),
        "events":placement_gate["events"].size(),"camera_owned_by_actor":camera.get_parent()==demo.actor,
        "actor_art_valid":demo.art_driver.is_visual_valid(),"reduced_motion":reduce_motion_enabled}
