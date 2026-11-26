extends SceneTree
const STAGE = preload("res://scenes/r3_m04_accessibility.tscn")
const FX = preload("res://scripts/r3_m04_fixture_hierarchy.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("R3-M04 FAIL "+label)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func snapshot_solids(s: Node2D) -> Dictionary:
    var bodies := 0
    var shapes := 0
    var rects: Array[String] = []
    for child in s.demo.get_children():
        if child is StaticBody2D:
            bodies += 1
            for collider in child.get_children():
                if collider is CollisionShape2D:
                    shapes += 1
                    if collider.shape is RectangleShape2D:
                        rects.append(str(child.position)+"|"+str(collider.shape.size))
    return {"bodies":bodies,"shapes":shapes,"rects":rects}
func run() -> void:
    var s = STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    await frames(12)
    var f = s.fixtures
    var base_colliders: Dictionary = snapshot_solids(s)
    var child_count: int = s.demo.actor.get_child_count()
    var base_poses = [s.demo.adapter.visual.current_asset_path(),s.demo.art_driver.overlay.texture.resource_path]
    var original_rates: Array[Vector2] = []
    for p in s.background_layers: original_rates.append(p.scroll_scale)
    check(s.motion_checkbox != null,"UI check button mounted")
    check(s.motion_checkbox.visible,"visible UI")
    check(s.motion_status != null,"status mounted")
    check(not s.motion_checkbox.button_pressed,"default animation enabled")
    check(s.motion_checkbox.text.contains("[M]"),"keyboard affordance displayed")
    check(f.fixtures.size()==7,"seven real-surface anchored fixtures")
    check(f.get_script().resource_path.ends_with("r3_m04_fixture_hierarchy.gd"),"M04 layer is active")
    check(not s.reduce_motion_enabled,"default setting false")
    check(s.motion_snapshot()["camera_follow"],"camera still attached to player")
    check(s.demo.art_driver.is_visual_valid(),"baseline art valid")
    s.demo.actor.global_position=Vector2(1660,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(10)
    check(s.demo.actor.is_on_floor(),"grounded at corridor")
    # Measure actual redraw suppression in reduced mode, after state settles.
    for biome in FX.BIOMES:
        check(s.set_r3_biome(biome),"biome available "+biome)
        s.set_reduced_motion(false)
        await frames(6)
        var active_start: int=f.draw_calls
        await frames(20)
        var active_draws: int=f.draw_calls-active_start
        check(active_draws>=5,"animated draws when enabled "+biome)
        check(not s.motion_checkbox.button_pressed,"UI and setting agree ON "+biome)
        s.motion_checkbox.button_pressed=true # exercise actual GUI signal
        await frames(3)
        check(s.reduce_motion_enabled,"GUI toggles accessible setting "+biome)
        check(s.motion_snapshot()["checked"],"GUI state snapshot "+biome)
        check(f.reduced_motion,"fixtures paused "+biome)
        check(not s.s29_lookahead_enabled and not s.s30_vertical_enabled,"camera anticipation disabled "+biome)
        for p in s.background_layers:
            check(p.scroll_scale==Vector2.ZERO,"parallax frozen "+biome)
        check(s.camera.offset==Vector2.ZERO,"camera offset neutralized "+biome)
        check(s.demo.art_driver.is_visual_valid(),"art unchanged in reduced mode "+biome)
        var frozen_phase: float=f.phase
        var frozen_angles: Array[float]=f.joint_angles.duplicate()
        var static_start: int=f.draw_calls
        await frames(25)
        var static_draws: int=f.draw_calls-static_start
        check(static_draws<=2,"no redundant fixture rendering in reduced mode "+biome)
        check(is_equal_approx(f.phase,frozen_phase),"fixture time frozen "+biome)
        check(f.joint_angles==frozen_angles,"rotation frozen "+biome)
        for level in f.levels:
            check(is_zero_approx(level),"activity zero in reduced mode "+biome)
        check(f.snapshot()["collision_added"]==false,"no fixture collision "+biome)
        # Toggle via the actual M input callback; ensure reversible.
        var key := InputEventKey.new()
        key.pressed=true
        key.keycode=KEY_M
        s._unhandled_input(key)
        await frames(4)
        check(not s.reduce_motion_enabled,"keyboard restores motion "+biome)
        check(not s.motion_checkbox.button_pressed,"button sync after shortcut "+biome)
        check(s.s29_lookahead_enabled and s.s30_vertical_enabled,"auto camera restored "+biome)
        for k in range(original_rates.size()):
            check(s.background_layers[k].scroll_scale==original_rates[k],"parallax exact restore "+biome)
        check(s.motion_status.text.contains("ACTIVE"),"status text restored "+biome)
    # Two rapid toggles preserve collider and source textures.
    s.set_reduced_motion(true)
    s.set_reduced_motion(false)
    await frames(6)
    check(snapshot_solids(s)==base_colliders,"platform collisions identical")
    check(s.demo.actor.get_child_count()==child_count,"actor topology unchanged")
    check(s.demo.adapter.visual.current_asset_path()==base_poses[0],"source art path unchanged")
    check(s.demo.art_driver.overlay.texture.resource_path==base_poses[1],"original overlay texture unchanged")
    check(f.budget_snapshot()["collision_added"]==false,"not a collision producer")
    check(f.budget_snapshot()["spawn_authority"]==false,"not a gameplay spawner")
    # Actual input-driven run, jump, crouch in reduced mode.
    s.set_reduced_motion(true)
    s.demo.actor.global_position=Vector2(1700,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(8)
    var start_x: float=s.demo.actor.global_position.x
    Input.action_press("sk_right")
    await frames(25)
    Input.action_release("sk_right")
    check(s.demo.actor.global_position.x>start_x+60,"actual movement preserved in reduce mode")
    check(s.demo.art_driver.is_visual_valid(),"running visual unchanged")
    s.demo.jump_queued=true
    await frames(5)
    check(not s.demo.actor.is_on_floor(),"actual jump preserved")
    check(s.demo.actor.velocity.y<0,"upward arc preserved")
    await frames(74)
    check(s.demo.actor.is_on_floor(),"ground landing preserved")
    Input.action_press("sk_crouch")
    await frames(12)
    check(s.demo.adapter.crouched,"crouch preserved")
    check(s.demo.adapter.pose_geometry_verified(),"crouch collider preserved")
    Input.action_release("sk_crouch")
    await frames(12)
    check(not s.demo.adapter.crouched,"stand recovery preserved")
    check(s.demo.art_driver.is_visual_valid(),"recovery visual preserved")
    check(s.motion_snapshot()["actor_physics_steps"]>100,"physics continues with reduced graphics")
    print("R3_M04_RESULT checks=",checks," failures=",failures," fixtures=",f.fixtures.size()," active_updates=",f.active_updates," paused_updates=",f.paused_updates," fixture_draws=",f.draw_calls)
    quit(0 if failures==0 else 1)
func _initialize() -> void: call_deferred("run")
