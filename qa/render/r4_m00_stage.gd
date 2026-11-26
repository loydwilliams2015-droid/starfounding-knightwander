extends "res://scripts/r3_m04_stage.gd"
## R4-M00: light/material motif review ONLY; keep S33 and R3 controller ownership.
const POLICY = preload("res://scripts/r4_m00_render_policy.gd")
var r4_lights: Array[PointLight2D] = []
var r4_biome: String = "industrial"
var r4_light_mode: String = "diffuse"
var r4_info: Label
var baseline_actor_modulate: Color
var baseline_original_lights: Array[float] = []
var baseline_original_positions: Array[Vector2] = []
func _ready() -> void:
    super._ready()
    baseline_actor_modulate = demo.actor.modulate
    for existing in lights:
        baseline_original_lights.append(existing.energy)
        baseline_original_positions.append(existing.position)
    # Reuse the existing, authored radial lamp texture. New lights are independent
    # of the actor and attached to scenery landmarks; they do not create gameplay bodies.
    for k in range(2):
        var local_light := PointLight2D.new()
        local_light.name = "R4SceneKey" if k==0 else "R4SceneFill"
        local_light.position = Vector2(1525,358) if k==0 else Vector2(1915,295)
        local_light.texture = lights[0].texture
        local_light.texture_scale = 1.6 if k==0 else 1.35
        local_light.energy = 0.23 if k==0 else 0.13
        local_light.z_index = 1
        demo.add_child(local_light)
        r4_lights.append(local_light)
    r4_info=Label.new()
    r4_info.name="R4LightingLegend"
    r4_info.position = Vector2(15,37)
    r4_info.add_theme_font_size_override("font_size",11)
    r4_info.add_theme_color_override("font_color",Color("e1eadb"))
    motion_ui.add_child(r4_info)
    apply_render_motif("industrial","diffuse")
    for ui_node in get_children():
        if ui_node is CanvasLayer and ui_node != motion_ui:
            for label_node in ui_node.get_children():
                if label_node is Label and "STARFOUNDING" in label_node.text:
                    label_node.text="STARFOUNDING KNIGHTWANDER / R3 closeout / R4 lighting QA"
func apply_render_motif(biome: String, lighting: String) -> bool:
    var p: Dictionary = POLICY.resolve(biome,lighting)
    if not POLICY.validate(p): return false
    if not set_r3_biome(biome): return false
    r4_biome=biome
    r4_light_mode=lighting
    r4_lights[0].color=p["key_color"]
    r4_lights[1].color=p["fill_color"]
    r4_lights[0].energy=p["key_energy"]
    r4_lights[1].energy=p["fill_energy"]
    background_layers[0].modulate=p["background_color"]
    # Character palette remains untouched; contrast priority exceeds glow styling.
    demo.actor.modulate=baseline_actor_modulate
    r4_info.text="R4 motif: %s / %s | player silhouette priority"%[biome,lighting]
    return true
func r4_snapshot() -> Dictionary:
    return {"biome":r4_biome,"lighting":r4_light_mode,
        "key_energy":r4_lights[0].energy,"fill_energy":r4_lights[1].energy,
        "key_color":r4_lights[0].color,"fill_color":r4_lights[1].color,
        "world_light_count":lights.size(),"preview_light_count":r4_lights.size(),
        "actor_modulate":demo.actor.modulate,"original_light_positions":lights.map(func(l): return l.position),
        "original_light_energies":lights.map(func(l): return l.energy),
        "collision_added":false,"spawn_authority":false,"reduced_motion":reduce_motion_enabled,
        "parallax_scales":motion_snapshot()["parallax_scales"],
        "camera_parent_unchanged":camera.get_parent()==demo.actor}
