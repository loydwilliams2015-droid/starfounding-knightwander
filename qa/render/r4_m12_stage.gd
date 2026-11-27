extends "res://scripts/r4_m11_stage.gd"
## Read-only preview state for a pure v2 migration and QA-only sink.
var sandbox_state: Dictionary = {}
var sink_hud: Label
func _ready() -> void:
    super._ready()
    sink_hud = Label.new()
    sink_hud.name = "R4M12VersionedSinkHUD"
    sink_hud.position = Vector2(18, 190)
    sink_hud.add_theme_font_size_override("font_size", 12)
    sink_hud.add_theme_color_override("font_color", Color("dceba9"))
    motion_ui.add_child(sink_hud)
    r4_info.text = "R4-M12 v1→v2 projection + isolated sink | GAMEPLAY LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer != motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text = "STARFOUNDING KNIGHTWANDER / R4-M12 QA migration"
    show_sandbox({"state":{"generation":0,"star_fragments":0,"ids":[]},"delivery_count":0})
func show_sandbox(data: Dictionary) -> void:
    sandbox_state = data.duplicate(true)
    if is_instance_valid(sink_hud):
        var state: Dictionary = data.get("state", {})
        sink_hud.text = "R4-M12 QA SINK v2 | gen %d | fragments %d | receipts %d | delivered %d" % [
            int(state.get("generation", 0)),int(state.get("star_fragments",0)),
            state.get("ids",[]).size(),int(data.get("delivery_count",0))]
    placement_gate["blocked"] = true
    placement_gate["items"] = []
    placement_gate["events"] = []
