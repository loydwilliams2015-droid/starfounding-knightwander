extends "res://scripts/r4_m10_stage.gd"
## Presentation only: no scene-specific persistence writer or gameplay spawns.
var provider_status: Dictionary = {"mode": "UNBOUND", "owns": false, "generation": 0, "pending": 0}
var provider_hud: Label
func _ready() -> void:
    super._ready()
    provider_hud = Label.new()
    provider_hud.name = "R4M11ProviderBoundaryHUD"
    provider_hud.position = Vector2(18, 169)
    provider_hud.add_theme_font_size_override("font_size", 12)
    provider_hud.add_theme_color_override("font_color", Color("c3d9ee"))
    motion_ui.add_child(provider_hud)
    r4_info.text = "R4-M11 single provider | QA checkpoints/events | GAMEPLAY LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer != motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text = "STARFOUNDING KNIGHTWANDER / R4-M11 provider QA"
    show_provider(provider_status)
func show_provider(value: Dictionary) -> void:
    provider_status = value.duplicate(true)
    if is_instance_valid(provider_hud):
        provider_hud.text = "R4-M11 provider | %s | TX %d ACK pending %d | owner %s" % [
            str(value.get("mode", "QA")), int(value.get("generation", 0)),
            int(value.get("pending", 0)), "yes" if value.get("owns", false) else "no"]
    placement_gate["blocked"] = true
    placement_gate["items"] = []
    placement_gate["events"] = []
