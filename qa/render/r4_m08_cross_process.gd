extends SceneTree
const STAGE = preload("res://scenes/r4_m08_outbox_review.tscn")
const TX = preload("res://scripts/r4_m06_transaction.gd")
const ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
var checks: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("R4_M08_CROSS_FAIL " + label)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func run() -> void:
    var args: Array = OS.get_cmdline_user_args()
    var phase: String = str(args[0]) if args.size() > 0 else "write"
    var seed: int = int(args[1]) if args.size() > 1 else 41
    var screens: int = int(args[2]) if args.size() > 2 else 4
    var tag: String = "r4m08_cross_%d_%d"%[seed,screens]
    var tx = TX.new()
    tx.configure("r4m06_"+tag)
    var box = OUTBOX.new()
    box.configure(tag)
    var adapter = ADAPTER.new()
    var stage: Node2D = STAGE.instantiate()
    stage.route_seed = seed
    stage.route_screens = screens
    root.add_child(stage)
    current_scene = stage
    await frames(18)
    if phase == "write":
        tx.reset_test_only()
        box.reset_test_only()
        check(box.acquire_writer()["passed"], "writer lock acquired")
        stage.demo.actor.global_position=Vector2(stage.DISTRICT_START+70,450)
        stage.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entry: Dictionary = await ENTRY.drive(stage)
        check(entry["passed"], "native entrance")
        var one: Dictionary = await SEG.segment(stage,0,5)
        check(one["passed"], "native first links")
        var prefix: Array = one["edges"].duplicate(true)
        check(tx.commit_from_actor(stage,entry,prefix)["passed"], "TX gen1")
        check(adapter.apply_verified(stage,tx)["passed"], "event view gen1")
        check(box.acknowledge(stage,tx,adapter)["passed"], "ack gen1")
        var two: Dictionary = await SEG.segment(stage,5,11)
        check(two["passed"], "native second links")
        prefix.append_array(two["edges"])
        check(tx.commit_from_actor(stage,entry,prefix)["passed"], "TX gen2")
        check(adapter.apply_verified(stage,tx)["passed"], "event view gen2")
        check(box.pending(tx,stage.route)["ids"].size()==1, "gen2 pending before restart")
        check(box.release_writer(), "writer cleanly released")
    elif phase == "read" or phase == "replay":
        check(tx.load_latest(stage.route)["record"]["generation"]==2, "TX gen2 survived process exit")
        var rec: Dictionary = await tx.recover_scene(stage)
        check(rec["passed"] and rec["pad"]==11, "physical checkpoint restored")
        check(adapter.apply_verified(stage,tx)["passed"], "isolated projection redelivered")
        var pending: Dictionary = box.pending(tx,stage.route)
        check(pending["passed"], "outbox pending read validated")
        check(pending["ids"].size() == (1 if phase=="read" else 0), "right pending count across processes")
        check(box.acquire_writer()["passed"], "reader acquired fresh writer directory")
        var ack: Dictionary = box.acknowledge(stage,tx,adapter)
        check(ack["passed"] and ack.get("idempotent",false)==(phase=="replay"), "ack only once")
        check(box.pending(tx,stage.route)["ids"].is_empty(), "all receipts now acknowledged")
        check(box.release_writer(), "reader released owner lock")
        if phase=="read":
            var tail: Dictionary = await SEG.segment(stage,11,stage.route["pads"].size()-1)
            check(tail["passed"], "native continuation from durable checkpoint")
        check(stage.placement_gate["blocked"] and stage.placement_gate["items"].is_empty() and stage.placement_gate["events"].is_empty(), "no actual gameplay events")
    else:
        check(false,"bad phase")
    var report: Dictionary = {"phase":phase,"seed":seed,"screens":screens,"assertions":checks,"failures":failed,
        "tx_generation":2,"production_spawning":false}
    var fd: FileAccess = FileAccess.open("res://reports/R4_M08_CROSS_%s_%d_%d.json"%[phase,seed,screens], FileAccess.WRITE)
    if fd != null:
        fd.store_string(JSON.stringify(report,"  ")+"\n")
        fd.close()
    print("R4_M08_CROSS_RESULT phase=",phase," seed=",seed," screens=",screens," checks=",checks," failures=",failed)
    quit(0 if failed==0 else 1)
func _initialize() -> void: call_deferred("run")
