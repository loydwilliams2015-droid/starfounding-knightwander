extends "res://scripts/sk_s25_stage.gd"
## Additive QA stage; original S33 wrapper/controller untouched.
const FIXTURES = preload("res://scripts/r3_m03_fixture_hierarchy.gd")
const CONTRAST = preload("res://scripts/r3_m02_contrast.gd")
var fixtures: Node2D
func _ready() -> void:
    super._ready()
    fixtures=Node2D.new()
    fixtures.name="R3M03GroundedMotifs"
    fixtures.z_index=2
    fixtures.set_script(FIXTURES)
    demo.add_child(fixtures)
    demo.actor.z_index=9 # Character draws above foreground (8) and ornaments (2).
    fixtures.bind_stage(self)
    set_r3_biome("industrial")
    for ui_node in get_children():
        if ui_node is CanvasLayer:
            for label_node in ui_node.get_children():
                if label_node is Label and "STARFOUNDING" in label_node.text:
                    label_node.text="STARFOUNDING KNIGHTWANDER  /  R3-M03 animation hierarchy QA"
func set_r3_biome(value: String) -> bool:
    if not fixtures.set_biome(value):
        return false
    return CONTRAST.set_biome(self,value)
