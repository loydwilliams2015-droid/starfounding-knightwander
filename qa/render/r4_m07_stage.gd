extends "res://scripts/r4_m06_stage.gd"
## Isolated, read-only QA event adapter visualization; no world mutations.
var event_projection: Dictionary={"pad":-1,"generation":0,"fragments":0,"event_ids":[],"status":"NOT_APPLIED"}
var event_label: Label
func _ready()->void:
    super._ready()
    event_label=Label.new()
    event_label.name="R4M07IsolatedEventAdapterHUD"
    event_label.position=Vector2(18,87)
    event_label.add_theme_font_size_override("font_size",13)
    event_label.add_theme_color_override("font_color",Color("e1d29a"))
    motion_ui.add_child(event_label)
    r4_info.text="R4-M07 isolated event adapter | actual gameplay spawns LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer!=motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text="STARFOUNDING KNIGHTWANDER / R4-M07 event adapter QA"
    apply_event_projection(event_projection)
func apply_event_projection(value:Dictionary)->void:
    event_projection=value.duplicate(true)
    event_label.text="Isolated event view | pad %d | +%d | receipts %d | gen %d | %s"%[
        int(value.get("pad",-1)),int(value.get("fragments",0)),
        value.get("event_ids",[]).size(),int(value.get("generation",0)),
        str(value.get("status","NOT_APPLIED"))]
    # A display projection, never a command against game inventories or spawn APIs.
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
func adapter_snapshot()->Dictionary:
    return {"event":event_projection.duplicate(true),"checkpoint":qa_projection.duplicate(true),
        "spawns_locked":placement_gate["blocked"],"items":placement_gate["items"].size(),
        "events":placement_gate["events"].size(),"actor_floor":demo.actor.is_on_floor(),
        "controller":demo.adapter.pose_geometry_verified()}
