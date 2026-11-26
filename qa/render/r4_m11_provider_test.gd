extends SceneTree
const STAGE = preload("res://scenes/r4_m11_provider_review.tscn")
const PROVIDER = preload("res://scripts/r4_m11_provider.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
const PROOF = preload("res://scripts/r4_m03_certificate.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("R4_M11_FAIL: " + label)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func create_stage(seed: int, screens: int) -> Node2D:
    var s: Node2D = STAGE.instantiate()
    s.route_seed = seed
    s.route_screens = screens
    root.add_child(s)
    current_scene = s
    return s
func run() -> void:
    var args: Array = OS.get_cmdline_user_args()
    var seed: int = int(args[0]) if args.size()>0 else 41
    var screens: int = int(args[1]) if args.size()>1 else 4
    var name: String = "r4m11_test_matrix_%d_%d" % [seed,screens]
    var p = PROVIDER.new()
    var contender = PROVIDER.new()
    check(p.configure(name)["passed"], "provider configured")
    check(contender.configure(name)["passed"], "contender configured")
    # Fault-recovery cleanup is explicitly scoped to the isolated test namespace.
    if DirAccess.dir_exists_absolute(p._writer.outbox.lock_path()):
        DirAccess.remove_absolute(p._writer.outbox.lock_path()+"/owner.txt")
        DirAccess.remove_absolute(p._writer.outbox.lock_path())
    check(p.reset_test_only()["passed"], "fresh test journal")
    var s: Node2D = create_stage(seed,screens)
    await frames(20)
    check(not p.save_landing({},[])["passed"], "unbound writer forbidden")
    check(p.attach(s)["passed"], "bind active scene")
    check(contender.attach(s)["passed"], "contender bind")
    check(not p.save_landing({},[])["passed"], "cannot commit without lock")
    check(not p.deliver_committed()["passed"], "cannot acknowledge without lock")
    check(not p.request_real_item("star")["passed"], "real reward permanently denied")
    check(not p.request_real_event("quest")["passed"], "real event permanently denied")
    check(not p.has_method("commit_from_actor"), "no raw writer method on public provider")
    check(not p.has_method("acknowledge"), "no raw ACK method on public provider")
    check(p.acquire()["passed"], "provider acquired writer lock")
    check(not contender.acquire()["passed"], "competing provider denied")
    check(not contender.save_landing({},[])["passed"], "competing TX denied")
    check(not contender.deliver_committed()["passed"], "competing ACK denied")
    check(not p._writer.tx.commit_from_actor(s,{},[])["passed"], "guarded underlying TX resists bare direct call")
    check(not p._writer.outbox.acknowledge(s,p._writer.tx,p._writer.adapter)["passed"], "guarded underlying ACK resists bare direct call")
    s.demo.actor.global_position = Vector2(s.DISTRICT_START + 70,450)
    s.demo.actor.velocity = Vector2.ZERO
    await frames(12)
    var entrance: Dictionary = await ENTRY.drive(s)
    check(entrance.get("passed",false) and entrance.get("last_grounded",false), "real knight entrance")
    var prefix: Array = []
    var generations: Array = [5,11,15]
    for target in generations:
        var piece: Dictionary = await SEG.segment(s,prefix.size(),target)
        check(piece.get("passed",false), "native route segment %d"%target)
        if not piece.get("passed",false): break
        prefix.append_array(piece["edges"])
        check(prefix.size()==target, "native prefix length %d"%target)
        var before: Dictionary = p.save_landing(entrance,prefix,"before_open")
        check(not before.get("passed",true) and before.get("interrupted",false), "fault injection before TX write %d"%target)
        var committed: Dictionary = p.save_landing(entrance,prefix)
        check(committed.get("passed",false) and committed.get("generation",0)==generations.find(target)+1, "committed through provider %d"%target)
        check(p.status().get("pending",-1)==1, "single pending receipt %d"%target)
        check(not p.save_landing(entrance,prefix).get("passed",true), "cannot commit with pending ACK %d"%target)
        var fail_ack: Dictionary = p.deliver_committed("partial_temp")
        check(not fail_ack.get("passed",true) and fail_ack.get("interrupted",false), "ACK partial file does not commit %d"%target)
        check(p.status().get("pending",-1)==1, "ACK still pending after interruption %d"%target)
        var done: Dictionary = p.deliver_committed()
        check(done.get("passed",false) and not done.get("idempotent",true), "ACK committed through provider %d"%target)
        check(p.status().get("pending",-1)==0, "ACK caught up %d"%target)
        check(p.deliver_committed().get("idempotent",false), "same ACK idempotent %d"%target)
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty() and s.placement_gate["events"].is_empty(), "spawn gate closed %d"%target)
        s.show_provider({"mode":"verified", "owns":p.owns(),"generation":committed["generation"],"pending":0})
        check(s.provider_status["generation"]==committed["generation"], "HUD reflects verified record %d"%target)
    check(prefix.size()==15,"three native segments")
    check(p.status().get("generation",-1)==3,"three transactions")
    check(p.snapshot()["observed_ack_generations"]==3,"adapter receipt generations observed once")
    check(p.release(),"provider relinquishes ownership")
    check(not p.save_landing(entrance,prefix)["passed"],"released provider cannot mutate")
    check(contender.acquire()["passed"],"contender can take ownership after release")
    check(contender.release(),"contender releases")
    p.detach()
    s.queue_free()
    await frames(8)
    s=create_stage(seed,screens)
    await frames(20)
    check(p.attach(s)["passed"],"new scene reattached")
    check(not p.deliver_committed()["passed"],"fresh scene cannot ACK without ownership")
    check(p.acquire()["passed"],"reopened scene holds lock")
    check(not p.deliver_committed()["passed"],"recovery must precede event delivery")
    var recovered: Dictionary = await p.recover_bound_scene()
    check(recovered.get("passed",false) and recovered.get("native_floor_confirmed",false), "checkpoint recovered and native floor verified")
    check(int(recovered.get("pad",-1))==15, "last checkpoint recovered")
    check(p.deliver_committed().get("idempotent",false), "recovered ACK is idempotent")
    var tail: Dictionary = await SEG.segment(s,15,s.route["pads"].size()-1)
    check(tail.get("passed",false),"native tail traversal")
    var evidence: Array = p._writer.tx.load_latest(s.route)["record"]["checkpoint"]["prefix"].duplicate(true)
    evidence.append_array(tail.get("edges",[]))
    var trace: Dictionary = {"passed":true,"completed":evidence.size(),"edges":evidence,
        "content_blocked":true,"controller":"S33 -410 impulse / 1050 gravity / 220 walk"}
    var certificate: Dictionary=PROOF.issue(s.route,entrance,trace)
    check(certificate.get("valid",false) and not certificate.get("authorizes_gameplay_spawns",true),"full route QA proof non-spawning")
    check(p.release(), "last lock released")
    # Stale locks are never stolen, even by a correctly configured provider.
    check(DirAccess.make_dir_absolute(p._writer.outbox.lock_path())==OK,"simulated stale lock created")
    var f=FileAccess.open(p._writer.outbox.lock_path()+"/owner.txt",FileAccess.WRITE)
    f.store_string("nonexistent-process-token\n")
    f.close()
    check(not p.acquire().get("passed",true),"stale lock rejected")
    check(not p.reset_test_only().get("passed",true),"reset refuses to steal stale lock")
    check(not contender.acquire().get("passed",true),"stale lock blocks competitor")
    check(DirAccess.remove_absolute(p._writer.outbox.lock_path()+"/owner.txt")==OK,"test manually removes owner file")
    check(DirAccess.remove_absolute(p._writer.outbox.lock_path())==OK,"test manually removes dead lock")
    check(p.acquire()["passed"],"explicit recovery allows a new owner")
    check(p.release(),"recovered owner releases")
    check(s.placement_gate["blocked"],"spawn gate never opened")
    var data: Dictionary={"milestone":"R4-M11","seed":seed,"screens":screens,"checks":checks,
        "failures":failures,"native_links":evidence.size(),"generations":3,"acked":3,
        "stale_lock_policy":"manual-test-only-no-automatic-theft","production_spawns":false}
    var fp=FileAccess.open("res://reports/R4_M11_PROVIDER_%d_%d.json"%[seed,screens],FileAccess.WRITE)
    if fp:
        fp.store_string(JSON.stringify(data,"  ")+"\n")
        fp.close()
    print("R4_M11_RESULT seed=",seed," screens=",screens," checks=",checks," failures=",failures," native_links=",evidence.size())
    quit(0 if failures==0 else 1)
func _initialize() -> void:
    call_deferred("run")
