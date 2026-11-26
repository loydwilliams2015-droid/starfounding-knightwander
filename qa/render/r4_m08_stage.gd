extends "res://scripts/r4_m07_stage.gd"
## Outbox and writer-lock indicators are observational QA; no real game rewards.
var outbox_label: Label
var outbox_view: Dictionary = {"status": "UNACKNOWLEDGED", "generation": 0, "pending": -1, "lock": "none"}
func _ready() -> void:
    super._ready()
    outbox_label = Label.new()
    outbox_label.name = "R4M08PersistentOutboxHUD"
    outbox_label.position = Vector2(18, 108)
    outbox_label.add_theme_font_size_override("font_size", 12)
    outbox_label.add_theme_color_override("font_color", Color("bedfe6"))
    motion_ui.add_child(outbox_label)
    r4_info.text = "R4-M08 persistent QA ACK | actual gameplay spawns LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer != motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text = "STARFOUNDING KNIGHTWANDER / R4-M08 outbox QA"
    show_outbox(outbox_view)
func show_outbox(state: Dictionary) -> void:
    outbox_view = state.duplicate(true)
    outbox_label.text = "Outbox %s | gen %d | pending %d | lock %s" % [
        str(state.get("status", "UNACKNOWLEDGED")), int(state.get("generation", 0)),
        int(state.get("pending", -1)), str(state.get("lock", "none"))]
    placement_gate["blocked"] = true
    placement_gate["items"] = []
    placement_gate["events"] = []
