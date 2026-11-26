extends SceneTree
const STAGE = preload("res://scenes/r4_m10_mandatory_writer_review.tscn")
const COORD = preload("res://scripts/r4_m10_coordinator.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
const PROOF = preload("res://scripts/r4_m03_certificate.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("R4_M10_FAIL " + label)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func create_scene(seed: int, screens: int) -> Node2D:
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
    var name: String = "r4m10_matrix_%d_%d" % [seed,screens]
    var coord = COORD.new()
    var opponent = COORD.new()
    coord.configure(name)
    opponent.configure(name)
    if DirAccess.dir_exists_absolute(coord.outbox.lock_path()):
        # Test namespace only; failed earlier runs may have left a lock.
        DirAccess.remove_absolute(coord.outbox.lock_path()+"/owner.txt")
        DirAccess.remove_absolute(coord.outbox.lock_path())
    coord.reset_test_only()
    var s: Node2D = create_scene(seed,screens)
    await frames(20)
    check(s.placement_gate["blocked"],"initial gameplay spawn gate")
    check(not coord.status(s.route).get("valid",false),"no committed state at genesis")
    check(not coord.guarded_commit(s,{},[])["passed"],"cannot commit without writer ownership")
    check(not coord.guarded_deliver_and_ack(s)["passed"],"cannot ACK without ownership")
    check(coord.acquire()["passed"],"owner acquires unified writer")
    check(coord.owns(),"owner lock persisted")
    check(not coord.tx.commit_from_actor(s,{},[])["passed"],"raw TX writer denied even while holding lock")
    check(not coord.outbox.acknowledge(s,coord.tx,coord.adapter)["passed"],"raw ACK writer denied even while holding lock")
    check(not coord.acquire()["passed"],"duplicate acquire refused")
    check(not opponent.acquire()["passed"],"contending same-folder writer refused")
    check(not opponent.guarded_commit(s,{},[])["passed"],"competitor TX blocked")
    check(not opponent.guarded_deliver_and_ack(s)["passed"],"competitor ACK blocked")
    check(not opponent.release(),"competitor cannot release ownership")
    s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    var entry: Dictionary = await ENTRY.drive(s)
    check(entry["passed"] and entry["last_grounded"],"native entrance reached first elevated pad")
    var prefix: Array=[]
    for target in [5,11,15]:
        var piece: Dictionary=await SEG.segment(s,prefix.size(),target)
        check(piece["passed"],"native segment finished %d"%target)
        if not piece["passed"]:break
        prefix.append_array(piece["edges"])
        check(prefix.size()==target,"cumulative true native evidence %d"%target)
        check(not coord.tx.commit_from_actor(s,entry,prefix)["passed"],"direct checkpoint bypass denied despite ownership %d"%target)
        # Prove fail-closed TX mutation from a participant lacking lock.
        check(not opponent.guarded_commit(s,entry,prefix)["passed"],"competitor cannot TX pad %d"%target)
        var txbad: Dictionary=coord.guarded_commit(s,entry,prefix,"before_open")
        check(not txbad["passed"] and txbad.get("interrupted",false),"pre-open TX interruption %d"%target)
        var prior: Dictionary=coord.tx.load_latest(s.route)
        var prior_gen: int=prior["record"]["generation"] if prior.get("valid",false) else 0
        check(prior_gen==([5,11,15].find(target)),"interruption preserves predecessor TX gen %d"%target)
        var committed: Dictionary=coord.guarded_commit(s,entry,prefix)
        check(committed["passed"] and committed.get("coordination","")=="TX_COMMITTED_ACK_PENDING","TX under common lock %d"%target)
        check(s.qa_projection["generation"]==committed["generation"],"checkpoint event ledger coherent %d"%target)
        var status: Dictionary=coord.status(s.route)
        check(status["valid"] and status["pending"]==1,"exactly one receipt pending %d"%target)
        check(not coord.guarded_commit(s,entry,prefix)["passed"],"no second TX before ACK %d"%target)
        check(not opponent.guarded_deliver_and_ack(s)["passed"],"competitor cannot ACK %d"%target)
        check(not coord.outbox.acknowledge(s,coord.tx,coord.adapter)["passed"],"direct ACK bypass denied despite ownership %d"%target)
        var first: Dictionary=coord.guarded_deliver_and_ack(s,"partial_temp")
        check(not first["passed"] and first.get("interrupted",false),"partial ACK leaves no durable ACK %d"%target)
        check(coord.status(s.route)["pending"]==1,"still pending after partial temp %d"%target)
        var completed: Dictionary=coord.guarded_deliver_and_ack(s)
        check(completed["passed"] and not completed.get("idempotent",true),"ACK under common lock %d"%target)
        check(coord.status(s.route)["pending"]==0,"no pending receipt after ACK %d"%target)
        check(coord.guarded_deliver_and_ack(s).get("idempotent",false),"duplicate delivery idempotent %d"%target)
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty() and s.placement_gate["events"].is_empty(),"world effect authority locked %d"%target)
        s.show_unified({"status":"TX+ACK", "tx":committed["generation"],"ack":committed["generation"],"lock":"held"})
        check(s.unified_view["ack"]==committed["generation"],"scene HUD records unified state %d"%target)
    check(prefix.size()==15,"three complete native segments")
    var protected_status:Dictionary=coord.snapshot(s.route)
    check(protected_status["mandatory_in_r4m10"],"mandatory gateway explicitly registered")
    check(protected_status["direct_tx_denials"]>=4,"direct transaction denials counted")
    check(protected_status["direct_ack_denials"]>=4,"direct ACK denials counted")
    s.show_gateway({"mode":"three committed QA generations","owner":"held","blocked":protected_status["direct_tx_denials"]+protected_status["direct_ack_denials"]})
    check(s.gate_state["blocked"]>=8,"gateway HUD observes blocked bypasses")
    check(coord.status(s.route)["generation"]==3,"third TX and ACK in same journal protocol")
    check(coord.owns(),"owner lock retained through entire transaction and ACK sequence")
    check(not coord.adapter.request_real_item("star")["passed"],"production item API still denied")
    check(coord.release(),"owner releases shared lock")
    check(not coord.owns(),"shared lock gone")
    check(opponent.acquire()["passed"],"contender acquires only after release")
    check(opponent.owns(),"new writer owns exact same lock")
    check(not coord.guarded_commit(s,entry,prefix)["passed"],"old writer cannot commit after release")
    check(opponent.release(),"new writer cleanly releases lock")
    s.queue_free()
    await frames(7)
    s=create_scene(seed,screens)
    coord.adapter.reset_for_new_scene()
    await frames(20)
    check(not coord.guarded_deliver_and_ack(s)["passed"],"no ACK without lock after scene creation")
    check(not coord.tx.commit_from_actor(s,{},[])["passed"],"restored scene cannot directly mutate checkpoint")
    check(coord.acquire()["passed"],"fresh scene acquires lock")
    check(not coord.guarded_deliver_and_ack(s)["passed"],"unrestored checkpoint cannot be delivered")
    var recovered: Dictionary=await coord.recover_scene(s)
    check(recovered["passed"] and recovered["pad"]==15,"validated grounded checkpoint restoration")
    check(coord.guarded_deliver_and_ack(s).get("idempotent",false),"committed QA view reload ACKs once")
    check(coord.status(s.route)["pending"]==0,"recovery yields zero new pending receipts")
    var tail: Dictionary=await SEG.segment(s,15,s.route["pads"].size()-1)
    check(tail["passed"],"native route completion after unified writer recovery")
    var trace_edges: Array=coord.tx.load_latest(s.route)["record"]["checkpoint"]["prefix"].duplicate(true)
    trace_edges.append_array(tail["edges"])
    var trace: Dictionary={"passed":true,"completed":trace_edges.size(),"edges":trace_edges,
        "content_blocked":true,"controller":"S33 -410 impulse / 1050 gravity / 220 walk"}
    var cert:Dictionary=PROOF.issue(s.route,entry,trace)
    check(cert.get("valid",false) and not cert.get("authorizes_gameplay_spawns",true),"no spawn authority from route certificate")
    check(coord.release(),"final owner lock release")
    check(s.placement_gate["blocked"],"production authority still locked")
    var report:Dictionary={"milestone":"R4-M10","seed":seed,"screens":screens,
        "checks":checks,"failures":failures,"native_links":trace_edges.size(),"commits":3,
        "acknowledgements":3,"production_spawns":false,"shared_lock":true,"mandatory_gate":true,"direct_denials":coord.tx.denied_direct_writes+coord.outbox.denied_direct_acks}
    var fd:=FileAccess.open("res://reports/R4_M10_COORD_%d_%d.json"%[seed,screens],FileAccess.WRITE)
    if fd:
        fd.store_string(JSON.stringify(report,"  ")+"\n")
        fd.close()
    print("R4_M10_RESULT seed=",seed," screens=",screens," checks=",checks,
        " failures=",failures," native_links=",trace_edges.size()," commits=3 ack=3")
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
