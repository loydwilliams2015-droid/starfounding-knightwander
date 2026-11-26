extends SceneTree
const STAGE = preload("res://scenes/r4_m08_outbox_review.tscn")
const TX = preload("res://scripts/r4_m06_transaction.gd")
const ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
var screenshots: int = 0
var failures: int = 0
func frames(n: int) -> void:
    for i in range(n): await process_frame
func shot(stage: Node2D, label: String) -> void:
    await RenderingServer.frame_post_draw
    var image: Image = stage.get_viewport().get_texture().get_image()
    var path: String = "res://captures/r4_m08_engine/" + label + ".png"
    var code: int = image.save_png(path)
    if code == OK and image.get_width() == 960 and image.get_height() == 540:
        screenshots += 1
        print("R4_M08_CAPTURE ", label, " 960x540")
    else:
        failures += 1
func set_state(stage: Node2D, status: String, box: RefCounted, tx: RefCounted, lock_name: String) -> void:
    var current: Dictionary = tx.load_latest(stage.route)
    var gen: int = int(current.get("record", {}).get("generation", 0))
    var pending: Dictionary = box.pending(tx, stage.route)
    stage.show_outbox({"status":status,"generation":gen,
        "pending":pending.get("ids",[]).size() if pending.get("passed",false) else -1,
        "lock":lock_name})
func run() -> void:
    var tx = TX.new()
    tx.configure("r4m06_r4m08_visual_41_4")
    tx.reset_test_only()
    var box = OUTBOX.new()
    box.configure("r4m08_visual_41_4")
    if DirAccess.dir_exists_absolute(box.lock_path()):
        DirAccess.remove_absolute(box.lock_path()+"/owner.txt")
        DirAccess.remove_absolute(box.lock_path())
    box.reset_test_only()
    var adapter = ADAPTER.new()
    var s: Node2D = STAGE.instantiate()
    root.add_child(s)
    current_scene = s
    await frames(20)
    s.demo.actor.global_position = Vector2(s.DISTRICT_START+70,450)
    s.demo.actor.velocity = Vector2.ZERO
    await frames(12)
    s.show_outbox({"status":"LOCKED", "generation":0,"pending":0,"lock":"none"})
    await shot(s,"00_ground_no_receipts")
    if not box.acquire_writer().get("passed",false): quit(2); return
    var entry: Dictionary = await ENTRY.drive(s)
    if not entry["passed"]:quit(3);return
    s.show_outbox({"status":"NATIVE ENTRY", "generation":0,"pending":0,"lock":"held"})
    await shot(s,"01_first_pad_access")
    var prefix: Array = []
    for pad in [5,11,15]:
        var seg: Dictionary = await SEG.segment(s,prefix.size(),pad)
        if not seg["passed"]:quit(4);return
        prefix.append_array(seg["edges"])
        if not tx.commit_from_actor(s,entry,prefix)["passed"]:quit(5);return
        if not adapter.apply_verified(s,tx)["passed"]:quit(6);return
        set_state(s,"PENDING ACK",box,tx,"held")
        await frames(4)
        if pad == 5: await shot(s,"02_pad05_pending_ack")
        if pad == 11:
            var interrupted: Dictionary = box.acknowledge(s,tx,adapter,"verified_temp")
            if not interrupted.get("interrupted",false):quit(7);return
            set_state(s,"TEMP NOT COMMITTED",box,tx,"held")
            await frames(4)
            await shot(s,"04_pad11_pending_uncommitted")
        if not box.acknowledge(s,tx,adapter)["passed"]:quit(8);return
        set_state(s,"ACK COMMITTED",box,tx,"held")
        await frames(4)
        await shot(s,"03_pad05_ack_durable" if pad == 5 else "05_pad11_ack_durable" if pad == 11 else "06_pad15_ack_durable")
    s.demo.jump_queued = true
    await frames(5)
    if s.demo.actor.is_on_floor():quit(9);return
    set_state(s,"AIRBORNE; NO SAVE",box,tx,"held")
    await shot(s,"07_airborne_unsaved")
    s.queue_free()
    await frames(6)
    s = STAGE.instantiate()
    root.add_child(s)
    current_scene = s
    adapter.reset_for_new_scene()
    await frames(20)
    if not (await tx.recover_scene(s))["passed"]:quit(10);return
    if not adapter.apply_verified(s,tx)["passed"]:quit(11);return
    if not box.acknowledge(s,tx,adapter).get("idempotent",false):quit(12);return
    set_state(s,"RESTORED ACK",box,tx,"held")
    await frames(5)
    await shot(s,"08_reloaded_ack_no_duplicate")
    var end: Dictionary = await SEG.segment(s,15,s.route["pads"].size()-1)
    if not end["passed"]:quit(13);return
    s.set_reduced_motion(true)
    set_state(s,"ROUTE COMPLETE",box,tx,"held")
    await frames(5)
    await shot(s,"09_complete_reduced_motion")
    if not box.release_writer():quit(14);return
    var summary: Dictionary = {"milestone":"R4-M08", "native_images":screenshots,
        "failures":failures,"size":"960x540","native_route_finished":end["passed"],
        "qa_acks":3,"production_events":0,"scene_restored":true}
    var report: FileAccess = FileAccess.open("res://reports/R4_M08_CAPTURE_SUMMARY.json", FileAccess.WRITE)
    if report != null:
        report.store_string(JSON.stringify(summary,"  ")+"\n")
        report.close()
    print("R4_M08_CAPTURE_RESULT images=",screenshots," failures=",failures)
    quit(0 if failures == 0 and screenshots == 10 else 15)
func _initialize() -> void: call_deferred("run")
