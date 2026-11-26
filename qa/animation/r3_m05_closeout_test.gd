extends SceneTree
const STAGE = preload("res://scenes/r4_m00_render_review.tscn")
const POLICY = preload("res://scripts/r4_m00_render_policy.gd")
var checks := 0
var failures := 0
func check(ok: bool, note: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("R3-M05 FAIL "+note)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func run() -> void:
    var stage=STAGE.instantiate()
    root.add_child(stage)
    current_scene=stage
    await frames(15)
    var demo=stage.demo
    var fixture=stage.fixtures
    var collider_state=demo.adapter.pose_geometry_verified()
    var actor_count=demo.actor.get_child_count()
    var reference_texture_path=demo.adapter.visual.current_asset_path()
    var  original_material=stage.r4_snapshot()["biome"]
    check(collider_state,"inherited collider reference")
    check(original_material=="industrial","default material")
    check(fixture.fixtures.size()==7,"fixture anchor count")
    check(stage.background_layers.size()==4,"parallax layer count")
    check(stage.r4_lights.size()==2,"new preview lights count")
    check(stage.lights.size()==2,"original lamps untouched")
    check(stage.camera.get_parent()==demo.actor,"actor retains camera")
    check(demo.art_driver.is_visual_valid(),"sprite contract")
    for material in POLICY.BIOMES:
        check(stage.apply_render_motif(material,"beacon"),"material rendering "+material)
        stage.set_reduced_motion(true)
        await frames(5)
        check(stage.reduce_motion_enabled,"accessible mode "+material)
        check(fixture.reduced_motion,"decorative motion stops "+material)
        check(stage.demo.art_driver.is_visual_valid(),"sprite remains valid "+material)
        check(demo.adapter.pose_geometry_verified(),"geometry independent of environment "+material)
        check(demo.actor.get_child_count()==actor_count,"actor composition unchanged "+material)
        check(demo.adapter.visual.current_asset_path()==reference_texture_path,"unchanged reference art "+material)
        check(stage.r4_snapshot()["camera_parent_unchanged"],"camera owner "+material)
        check(stage.r4_snapshot()["collision_added"]==false,"no new gameplay collision "+material)
        check(stage.r4_snapshot()["spawn_authority"]==false,"no spawn authority "+material)
        stage.set_reduced_motion(false)
        await frames(3)
        check(not stage.reduce_motion_enabled and stage.s29_lookahead_enabled,"normal mode restored "+material)
        check(fixture.snapshot()["collision_added"]==false,"fixtures visual only "+material)
    stage.set_reduced_motion(true)
    stage.demo.actor.global_position=Vector2(1700,450)
    stage.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    check(stage.demo.actor.is_on_floor(),"initial grounding")
    Input.action_press("sk_crouch")
    await frames(15)
    check(demo.adapter.crouched,"crouch preserved")
    check(demo.adapter.pose_geometry_verified(),"crouch clearance")
    Input.action_release("sk_crouch")
    await frames(15)
    check(not demo.adapter.crouched,"stand recovery")
    check(demo.adapter.pose_geometry_verified(),"standing clearance")
    check(demo.art_driver.is_visual_valid(),"visual recovery")
    check(stage.r4_snapshot()["reduced_motion"],"setting survives player motion")
    print("R3_M05_RESULT checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize() -> void: call_deferred("run")
