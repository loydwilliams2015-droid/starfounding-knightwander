extends "res://scripts/r4_m08_stage.gd"
## Observability only. This scene owns no transaction writer and issues no events.
var unified_writer_label: Label
var unified_view: Dictionary = {"status":"UNCOMMITTED","tx":0,"ack":0,"lock":"none"}
func _ready() -> void:
    super._ready()
    unified_writer_label = Label.new()
    unified_writer_label.name = "R4M09UnifiedWriterHUD"
    unified_writer_label.position = Vector2(18, 129)
    unified_writer_label.add_theme_font_size_override("font_size", 12)
    unified_writer_label.add_theme_color_override("font_color", Color("dceab7"))
    motion_ui.add_child(unified_writer_label)
    r4_info.text = "R4-M09 unified participating writers | gameplay spawns LOCKED"
    for layer in get_children():
        if layer is CanvasLayer and layer != motion_ui:
            for node in layer.get_children():
                if node is Label and "STARFOUNDING" in node.text:
                    node.text = "STARFOUNDING KNIGHTWANDER / R4-M09 writer QA"
    show_unified(unified_view)
func show_unified(status: Dictionary) -> void:
    unified_view = status.duplicate(true)
    unified_writer_label.text = "Writer %s | tx %d | ack %d | lock %s" % [
        str(status.get("status","UNCOMMITTED")),int(status.get("tx",0)),
        int(status.get("ack",0)),str(status.get("lock","none"))]
    placement_gate["blocked"] = true
    placement_gate["items"] = []
    placement_gate["events"] = []
