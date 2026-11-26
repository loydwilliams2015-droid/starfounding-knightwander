extends SceneTree
## S31 regression: repeated input reversals while parallax and camera tracking run.
const SCENE = preload("res://scenes/sk_s25_visual_reintegration.tscn")
var checks := 0
var errors := 0
func assert_ok(value: bool, description: String) -> void:
    checks += 1
    if not value:
        errors += 1
        push_error("S31: " + description)
func frames(n: int) -> void:
    for i in range(n):
        await physics_frame
func run() -> void:
    var stage = SCENE.instantiate()
    root.add_child(stage)
    current_scene = stage
    await frames(12)
    stage.demo.actor.global_position = Vector2(1200,450)
    stage.demo.actor.velocity = Vector2.ZERO
    await frames(8)
    assert_ok(stage.demo.actor.is_on_floor(), "start on unobstructed ground")
    for i in range(10):
        Input.action_press("sk_crouch")
        await frames(3)
        assert_ok(stage.demo.adapter.crouched, "crouch cycle %d" % i)
        assert_ok(stage.demo.adapter.pose_geometry_verified(), "collider cycle %d" % i)
        assert_ok(stage.demo.art_driver.is_visual_valid(), "sprite cycle %d" % i)
        Input.action_release("sk_crouch")
        await frames(5)
        assert_ok(not stage.demo.adapter.crouched, "stand recovery %d" % i)
    Input.action_press("sk_right")
    await frames(24)
    Input.action_release("sk_right")
    assert_ok(stage.s29_camera_diagnostics().lookahead_x > 0.0, "right direction anticipation")
    Input.action_press("sk_left")
    await frames(24)
    Input.action_release("sk_left")
    assert_ok(stage.s29_camera_diagnostics().lookahead_x < 0.0, "lookahead reverses")
    assert_ok(stage.background_layers.size() == 4, "parallax remains active")
    assert_ok(stage.demo.adapter.pose_geometry_verified(), "final collider")
    assert_ok(stage.demo.art_driver.is_visual_valid(), "final artwork")
    print("S31_RESULT checks=",checks," failures=",errors)
    quit(0 if errors == 0 else 1)
func _initialize() -> void:
    call_deferred("run")
