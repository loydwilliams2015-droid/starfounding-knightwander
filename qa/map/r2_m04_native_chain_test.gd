extends SceneTree
## R2-M04 native link audit. Run seeds 0, 41, 77 independently.
## Full runnable scene + companion scripts live in the separately supplied R2-M04 ZIP.
const SAFE = preload("res://scripts/r2_chain_safety.gd")
const GATE = preload("res://scripts/r2_native_gate.gd")
const WORLD = preload("res://scenes/r2_physics_world.tscn")
var checks := 0
var failures := 0
func check(valid: bool, label: String) -> void:
    checks += 1
    if not valid:
        failures += 1
        push_error("R2M04: "+label)
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func run() -> void:
    var seed: int = int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size()>0 else 41
    var world = WORLD.instantiate()
    root.add_child(world)
    world.set_physics_process(false)
    await frames(5)
    world.build(seed,4)
    await frames(4)
    var proxy: Dictionary = SAFE.classify(world.route)
    var proposed: Dictionary = SAFE.safe_placements(world.route,proxy)
    var initial: Dictionary = GATE.certified_placements(world.route,proxy,{},proposed)
    check(initial["blocked"] and initial["items"].is_empty() and initial["events"].is_empty(),"missing certification blocks spawning")
    var results: Array[Dictionary] = []
    var passed_edges := 0
    for i in range(world.route["edges"].size()):
        var origin: Dictionary = world.route["pads"][i]
        var destination: Dictionary = world.route["pads"][i+1]
        var plan: Dictionary = SAFE.ballistic_transition(origin,destination)
        world.player.global_position=Vector2(origin["x"],origin["y"]-41.0)
        world.player.velocity=Vector2.ZERO
        world.simulate_motion(0.0,false,1.0/60.0)
        await frames(2)
        var grounded: bool = world.player.is_on_floor()
        var landed := false
        if grounded and plan.get("passable",false):
            for tick in range(90):
                world.simulate_motion(1.0 if tick < int(plan["move_ticks"]) else 0.0,tick==0,1.0/60.0)
                await frames(1)
                if tick>18 and world.player.is_on_floor() and absf(world.player.position.y-(destination["y"]-41.0))<5.0 and absf(world.player.position.x-destination["x"])<85.0:
                    landed=true
                    break
        if landed: passed_edges+=1
        results.append({"edge":i,"origin_grounded":grounded,"landed_target":landed})
        check(world.player.collision_mask==1,"collision preserved %d"%i)
    var cert: Dictionary=GATE.certificate(world.route,results)
    var allowed: Dictionary=GATE.certified_placements(world.route,proxy,cert,proposed)
    check(cert["native_pass"]==(passed_edges==results.size()),"certification matches landings")
    check(allowed["blocked"]==(passed_edges<results.size()),"all-chain gate")
    var wrong: Dictionary=cert.duplicate(true)
    wrong["route_fingerprint"]="invalid"
    check(GATE.certified_placements(world.route,proxy,wrong,proposed)["blocked"],"wrong route rejected")
    var incomplete: Array[Dictionary]=results.duplicate(true)
    incomplete.pop_back()
    check(not GATE.certificate(world.route,incomplete)["native_pass"],"missing edge rejected")
    var duplicate: Array[Dictionary]=results.duplicate(true)
    duplicate[0]["edge"]=1
    check(not GATE.certificate(world.route,duplicate)["native_pass"],"duplicate edge rejected")
    var failed: Array[Dictionary]=results.duplicate(true)
    failed[0]["landed_target"]=false
    var negative: Dictionary=GATE.certificate(world.route,failed)
    check(not negative["native_pass"],"failed landing rejected")
    check(GATE.certified_placements(world.route,proxy,negative,proposed)["blocked"],"failed edge removes all spawns")
    print("R2_M04_NATIVE seed=",seed," screens=4 inspected=",results.size()," landed=",passed_edges," missed=",results.size()-passed_edges," certificate=",cert["native_pass"])
    print("R2_M04_RESULT checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize() -> void: call_deferred("run")
