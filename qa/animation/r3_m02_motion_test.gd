extends SceneTree
## R3-M02 isolated Godot test; expects a complete S33 Godot QA scene.
const STAGE = preload("res://scenes/sk_s25_visual_reintegration.tscn")
const CONTRAST = preload("res://scripts/r3_m02_contrast.gd")
var checks := 0
var failures := 0
func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("R3-M02: " + note)
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func run() -> void:
    var s = STAGE.instantiate()
    root.add_child(s)
    current_scene = s
    await frames(12)
    s.demo.actor.global_position = Vector2(1700,450)
    s.demo.actor.velocity = Vector2.ZERO
    await frames(12)
    check(s.demo.actor.is_on_floor(),"grounded setup")
    for biome in CONTRAST.BIOMES:
        s.demo.actor.global_position=Vector2(1700,450)
        s.demo.actor.velocity=Vector2.ZERO
        await frames(8)
        check(CONTRAST.set_biome(s,biome),"biome accepted "+biome)
        var before: Vector2=s.demo.actor.global_position
        var start_colliders: int=s.demo.actor.get_child_count()
        check(CONTRAST.snapshot(s)["art_valid"],"baseline art "+biome)
        Input.action_press("sk_right")
        await frames(26)
        Input.action_release("sk_right")
        check(s.demo.actor.global_position.x > before.x+60,"actual running "+biome)
        check(s.s29_camera_diagnostics()["lookahead_x"]>0,"camera anticipation "+biome)
        check(s.demo.art_driver.is_visual_valid(),"running art "+biome)
        s.demo.jump_queued=true
        await frames(5)
        check(not s.demo.actor.is_on_floor(),"airborne "+biome)
        check(s.demo.actor.velocity.y<0,"upward velocity "+biome)
        check(s.demo.art_driver.is_visual_valid(),"jump art "+biome)
        await frames(75)
        check(s.demo.actor.is_on_floor(),"landing "+biome)
        check(s.demo.adapter.pose_geometry_verified(),"landing collider "+biome)
        Input.action_press("sk_crouch")
        await frames(12)
        check(s.demo.adapter.crouched,"crouch "+biome)
        check(s.demo.art_driver.is_visual_valid(),"crouch art "+biome)
        Input.action_release("sk_crouch")
        await frames(12)
        check(not s.demo.adapter.crouched,"stand recovery "+biome)
        check(s.demo.art_driver.is_visual_valid(),"recovered art "+biome)
        check(s.demo.actor.get_child_count()==start_colliders,"actor tree unchanged "+biome)
        check(s.background_layers.size()==4,"four parallax layers "+biome)
        check(s.foreground.modulate.a<0.5,"decorative foreground subdued "+biome)
        check(CONTRAST.snapshot(s)["geometry_valid"],"geometry "+biome)
    check(not CONTRAST.set_biome(s,"nonexistent"),"unknown material rejected")
    print("R3_M02_RESULT checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize() -> void: call_deferred("run")
