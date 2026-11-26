extends SceneTree
const STAGE = preload("res://scenes/r4_m00_render_review.tscn")
const POLICY = preload("res://scripts/r4_m00_render_policy.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("R4-M00 FAIL: "+label)
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func colliders(stage: Node2D) -> Array[String]:
    var out: Array[String] = []
    for node in stage.demo.get_children():
        if node is StaticBody2D:
            for sh in node.get_children():
                if sh is CollisionShape2D and sh.shape is RectangleShape2D:
                    out.append("%s|%s|%s"%[node.name,node.position,sh.shape.size])
    out.sort()
    return out
func run() -> void:
    var stage=STAGE.instantiate()
    root.add_child(stage)
    current_scene=stage
    await frames(15)
    var initial_colliders: Array[String]=colliders(stage)
    var initial_child_count: int=stage.demo.actor.get_child_count()
    var initial_lamp_locations: Array=stage.lights.map(func(l): return l.position)
    var initial_lamp_energy: Array=stage.lights.map(func(l): return l.energy)
    var initial_sprite_texture: Texture2D=stage.demo.adapter.visual.texture
    var initial_parallax: Array[Vector2]=[]
    for p in stage.background_layers: initial_parallax.append(p.scroll_scale)
    check(stage.r4_lights.size()==2,"two additional light sources")
    check(stage.lights.size()==2,"original two lamps retained")
    check(stage.camera.get_parent()==stage.demo.actor,"camera ownership")
    check(stage.r4_info.visible,"motif legend visible")
    check(POLICY.resolve("bogus","beacon")["valid"]==false,"reject unknown biome")
    check(POLICY.resolve("stone","unbounded")["valid"]==false,"reject unknown light mode")
    for b in POLICY.BIOMES:
        for mode in POLICY.LIGHT_MODES:
            var policy: Dictionary=POLICY.resolve(b,mode)
            check(POLICY.validate(policy),"policy bounds "+b+mode)
            check(policy["collision_added"]==false,"no physics authority "+b+mode)
            check(policy["spawn_authority"]==false,"no spawner authority "+b+mode)
            check(policy["lighting_animation"]==false,"static lights "+b+mode)
            check(policy["reduced_motion_compatible"],"reduced-motion compatible "+b+mode)
            check(stage.apply_render_motif(b,mode),"apply policy "+b+mode)
            await frames(3)
            var state: Dictionary=stage.r4_snapshot()
            check(state["biome"]==b and state["lighting"]==mode,"scene identity "+b+mode)
            check(is_equal_approx(state["key_energy"],policy["key_energy"]),"key energy "+b+mode)
            check(is_equal_approx(state["fill_energy"],policy["fill_energy"]),"fill energy "+b+mode)
            check(state["key_color"].is_equal_approx(policy["key_color"]),"key palette "+b+mode)
            check(state["fill_color"].is_equal_approx(policy["fill_color"]),"fill palette "+b+mode)
            check(stage.background_layers[0].modulate.is_equal_approx(policy["background_color"]),"background palette "+b+mode)
            check(state["actor_modulate"].is_equal_approx(Color.WHITE),"original actor contrast "+b+mode)
            check(stage.demo.adapter.visual.texture==initial_sprite_texture,"source art unchanged "+b+mode)
            check(stage.demo.art_driver.is_visual_valid(),"profile A pose valid "+b+mode)
            check(colliders(stage)==initial_colliders,"no geometry mutations "+b+mode)
            check(stage.demo.actor.get_child_count()==initial_child_count,"no actor topology mutation "+b+mode)
            check(state["original_light_positions"]==initial_lamp_locations,"original lamp positions "+b+mode)
            check(state["original_light_energies"]==initial_lamp_energy,"original lamp energy "+b+mode)
            check(stage.r4_info.text.contains(b) and stage.r4_info.text.contains(mode),"UI motif identity "+b+mode)
            check(state["camera_parent_unchanged"],"camera parent "+b+mode)
            check(not state["collision_added"] and not state["spawn_authority"],"no new authority "+b+mode)
            for light in stage.r4_lights:
                check(light.texture==stage.lights[0].texture,"reference texture reused "+b+mode)
            # Light modes are still valid under the R3 reduced-motion setting.
            stage.set_reduced_motion(true)
            await frames(3)
            check(stage.r4_snapshot()["reduced_motion"],"motion setting retained "+b+mode)
            check(is_equal_approx(stage.r4_lights[0].energy,policy["key_energy"]),"light unchanged while motion reduced "+b+mode)
            check(is_equal_approx(stage.r4_lights[1].energy,policy["fill_energy"]),"fill unchanged while motion reduced "+b+mode)
            check(not stage.s29_lookahead_enabled and not stage.s30_vertical_enabled,"camera motion disabled "+b+mode)
            for layer in stage.background_layers:
                check(layer.scroll_scale==Vector2.ZERO,"parallax frozen "+b+mode)
            stage.set_reduced_motion(false)
            await frames(3)
            for idx in range(stage.background_layers.size()):
                check(stage.background_layers[idx].scroll_scale==initial_parallax[idx],"parallax restored "+b+mode)
            check(stage.s29_lookahead_enabled and stage.s30_vertical_enabled,"camera restored "+b+mode)
    var before: Dictionary=stage.r4_snapshot()
    check(not stage.apply_render_motif("invalid","beacon"),"invalid material refused")
    check(not stage.apply_render_motif("stone","invalid"),"invalid lighting refused")
    check(stage.r4_snapshot()==before,"invalid inputs do not partially modify state")
    stage.apply_render_motif("stone","diffuse")
    stage.demo.actor.global_position=Vector2(1700,450)
    stage.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    check(stage.demo.actor.is_on_floor(),"native ground contact")
    var start_x: float=stage.demo.actor.global_position.x
    Input.action_press("sk_right")
    await frames(27)
    Input.action_release("sk_right")
    check(stage.demo.actor.global_position.x>start_x+60,"native running preserved")
    stage.demo.jump_queued=true
    await frames(5)
    check(not stage.demo.actor.is_on_floor(),"jump preserved")
    await frames(78)
    check(stage.demo.actor.is_on_floor(),"landing preserved")
    check(stage.demo.adapter.pose_geometry_verified(),"landing pose geometry")
    check(colliders(stage)==initial_colliders,"geometry retained after running")
    print("R4_M00_RESULT checks=",checks," failures=",failed)
    quit(0 if failed==0 else 1)
func _initialize() -> void: call_deferred("run")
