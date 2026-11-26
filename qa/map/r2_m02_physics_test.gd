extends SceneTree
const WORLD = preload("res://scenes/r2_physics_world.tscn")
const GEN = preload("res://scripts/r2_route_generator.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("R2_M02 FAIL: " + message)
func frames(n: int) -> void:
    for i in range(n):
        await physics_frame
func run() -> void:
    for screens in [4,5,6]:
        for seed in [0,1,41,77,99]:
            var route: Dictionary = GEN.generate(seed,screens)
            check(GEN.validate(route)["passed"], "route graph %d/%d"%[seed,screens])
            var world = WORLD.instantiate()
            root.add_child(world)
            world.set_physics_process(false)
            world.build(seed,screens)
            await frames(4)
            check(world.world.get_child_count()==screens*6+1,"physical collider count")
            check(world.player.collision_mask==1,"player collides with world")
            check(world.player.position.distance_to(route["spawn"])<1.0,"spawn reproducibility")
            for k in range(5):
                check(world.world.get_node("OneWayPad%02d"%k).get_child(0).one_way_collision,"one-way pad")
            world.queue_free()
            await frames(2)
    var sample = WORLD.instantiate()
    root.add_child(sample)
    sample.set_physics_process(false)
    await frames(12)
    check(sample.route["seed"]==41,"seed 41 stable")
    sample.simulate_motion(0.0,false,1.0/60.0)
    await frames(1)
    check(sample.player.is_on_floor(),"grounded before jump")
    sample.player.position=Vector2(180,418)
    sample.player.velocity=Vector2.ZERO
    sample.simulate_motion(0.0,false,1.0/60.0)
    await frames(1)
    var minimum_y: float = sample.player.position.y
    var landed_pad := false
    for tick in range(100):
        sample.simulate_motion(0.0,tick==0,1.0/60.0)
        await frames(1)
        minimum_y=minf(minimum_y,sample.player.position.y)
        if tick>20 and sample.player.is_on_floor() and sample.player.position.y < 395:
            landed_pad=true
            break
    check(minimum_y < 320.0,"real jump clears first platform height")
    check(landed_pad,"physically lands on first elevated pad")
    check(sample.player.position.y > 240 and sample.player.position.y < 330,"pad foot collision geometry")
    var previous_x=sample.player.position.x
    var pad2_landed := false
    for tick in range(110):
        sample.simulate_motion(1.0,tick==0,1.0/60.0)
        await frames(1)
        if tick>20 and sample.player.is_on_floor() and sample.player.position.x > previous_x+100:
            pad2_landed=true
            break
    check(sample.player.position.x>previous_x+100,"real motion traverses horizontal gap")
    check(pad2_landed,"second platform or safe ground landing")
    check(sample.player.position.x < sample.route["width"],"stays in generated world bounds")
    print("R2_M02_RESULT checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize() -> void:
    call_deferred("run")
