extends SceneTree
## S32: camera-owner handoff, repeated crouch, input travel and mode idempotence.
const SCENE = preload("res://scenes/sk_s25_visual_reintegration.tscn")
var checks := 0
var failures := 0
func check(valid: bool, explanation: String) -> void:
    checks += 1
    if not valid:
        failures += 1
        push_error("S32 FAIL: " + explanation)
func frames(n: int) -> void:
    for i in range(n):
        await physics_frame
func run() -> void:
    var stage = SCENE.instantiate()
    root.add_child(stage)
    current_scene = stage
    await frames(12)
    stage.demo.actor.global_position = Vector2(1200, 450)
    stage.demo.actor.velocity = Vector2.ZERO
    await frames(8)
    check(stage.demo.actor.is_on_floor(), "grounded initial state")
    for i in range(6):
        stage.set_camera_tracking_phase(float(i) * 7.25 + 0.5, false)
        var manual = stage.s32_camera_ownership_snapshot()
        check(not manual.auto_horizontal, "horizontal automatic mode disabled %d" % i)
        check(not manual.auto_vertical, "vertical automatic mode disabled %d" % i)
        check(is_equal_approx(manual.offset.x, float(i)*7.25 + 0.5), "manual subpixel offset %d" % i)
        await frames(2)
        check(is_equal_approx(stage.camera.offset.x, manual.offset.x), "manual camera offset persists %d" % i)
        var before_pos = stage.demo.actor.global_position
        stage.set_s32_auto_camera_tracking(true)
        var automatic = stage.s32_camera_ownership_snapshot()
        check(automatic.auto_horizontal and automatic.auto_vertical, "automatic ownership restored %d" % i)
        check(automatic.offset == Vector2.ZERO, "manual offset cleared %d" % i)
        check(automatic.actor_position.distance_to(before_pos) < 0.01, "owner transition does not teleport actor %d" % i)
        Input.action_press("sk_right")
        await frames(12)
        Input.action_release("sk_right")
        check(stage.s29_camera_diagnostics().lookahead_x > 0.0, "lookahead updated after reenable %d" % i)
        Input.action_press("sk_crouch")
        await frames(3)
        check(stage.demo.adapter.crouched, "crouch preserved %d" % i)
        check(stage.demo.art_driver.is_visual_valid(), "art integrity %d" % i)
        Input.action_release("sk_crouch")
        await frames(5)
        check(not stage.demo.adapter.crouched, "stand recovery %d" % i)
        check(stage.demo.adapter.pose_geometry_verified(), "geometry integrity %d" % i)
    check(stage.background_layers.size() == 4, "four parallax layers retained")
    stage.set_s32_auto_camera_tracking(false)
    check(not stage.s29_lookahead_enabled and not stage.s30_vertical_enabled, "explicit disable")
    stage.set_s32_auto_camera_tracking(true)
    stage.set_s32_auto_camera_tracking(true)
    check(stage.s29_lookahead_enabled and stage.s30_vertical_enabled, "idempotent reenable")
    print("S32_RESULT checks=", checks, " failures=", failures)
    quit(0 if failures == 0 else 1)
func _initialize() -> void:
    call_deferred("run")
