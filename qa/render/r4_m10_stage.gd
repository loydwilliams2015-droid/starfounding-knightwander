extends "res://scripts/r4_m09_stage.gd"
## Visual-only owner/permit observability. All gameplay effect APIs stay locked.
var gate_hud: Label
var gate_state: Dictionary = {"mode":"mandatory in R4-M10", "blocked":0, "owner":"none"}
func _ready() -> void:
    super._ready()
    gate_hud = Label.new()
    gate_hud.name = "R4M10MandatoryGatewayHUD"
    gate_hud.position = Vector2(18, 149)
    gate_hud.add_theme_font_size_override("font_size", 12)
    gate_hud.add_theme_color_override("font_color", Color("c7e6c9"))
    motion_ui.add_child(gate_hud)
    r4_info.text = "R4-M10 mandatory local writer gateway | gameplay LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer != motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text = "STARFOUNDING KNIGHTWANDER / R4-M10 gateway QA"
    show_gateway(gate_state)
func show_gateway(value: Dictionary) -> void:
    gate_state = value.duplicate(true)
    if is_instance_valid(gate_hud):
        gate_hud.text = "Mandatory gate | owner %s | blocked direct %d | %s" % [
            str(value.get("owner", "none")), int(value.get("blocked", 0)),
            str(value.get("mode", "QA only"))]
    placement_gate["blocked"] = true
    placement_gate["items"] = []
    placement_gate["events"] = []
