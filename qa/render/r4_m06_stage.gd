extends "res://scripts/r4_m05_stage.gd"
## R4-M06 QA projection only; actual gameplay pickups/events never spawn.
var qa_projection: Dictionary={"pad":-1,"star_fragments":0,"event_outcomes":[],"generation":0}
var transaction_label: Label
func _ready()->void:
    super._ready()
    transaction_label=Label.new()
    transaction_label.name="R4M06TransactionProjectionHUD"
    transaction_label.position=Vector2(18,64)
    transaction_label.add_theme_font_size_override("font_size",13)
    transaction_label.add_theme_color_override("font_color",Color("cdebd7"))
    motion_ui.add_child(transaction_label)
    r4_info.text="R4-M06 atomic checkpoint and QA event projection | GAMEPLAY LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer!=motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text="STARFOUNDING KNIGHTWANDER / R4-M06 transaction QA"
    apply_qa_projection({"pad":-1,"star_fragments":0,"event_outcomes":[],"generation":0})
func apply_qa_projection(data:Dictionary)->void:
    qa_projection=data.duplicate(true)
    transaction_label.text="QA atomic view | pad %d | fragments %d | outcomes %d | gen %d"%[
        int(qa_projection.get("pad",-1)),int(qa_projection.get("star_fragments",0)),
        qa_projection.get("event_outcomes",[]).size(),int(qa_projection.get("generation",0))]
    # These are a read-only preview projection, not inventory or real world events.
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
func transaction_snapshot()->Dictionary:
    return {"projection":qa_projection.duplicate(true),"spawn_locked":placement_gate["blocked"],
        "gameplay_items":placement_gate["items"].size(),"gameplay_events":placement_gate["events"].size(),
        "actor_floor":demo.actor.is_on_floor(),"controller_pose_valid":demo.adapter.pose_geometry_verified(),
        "camera_owned":camera.get_parent()==demo.actor}
