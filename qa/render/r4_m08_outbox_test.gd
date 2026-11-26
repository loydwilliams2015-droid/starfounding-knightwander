extends SceneTree
const STAGE = preload("res://scenes/r4_m08_outbox_review.tscn")
const TX = preload("res://scripts/r4_m06_transaction.gd")
const ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
const PROOF = preload("res://scripts/r4_m03_certificate.gd")
var checks: int = 0
var failures: int = 0
func check(good: bool, name: String) -> void:
    checks += 1
    if not good:
        failures += 1
        push_error("R4_M08_FAIL " + name)
func frames(n: int) -> void:
    for i in range(n): await physics_frame
func create_scene(seed: int, screens: int) -> Node2D:
    var scene: Node2D = STAGE.instantiate()
    scene.route_seed = seed
    scene.route_screens = screens
    root.add_child(scene)
    current_scene = scene
    return scene
func run() -> void:
    var args: Array = OS.get_cmdline_user_args()
    var seed: int = int(args[0]) if args.size() > 0 else 41
    var screens: int = int(args[1]) if args.size() > 1 else 4
    var tx = TX.new()
    tx.configure("r4m06_r4m08_matrix_%d_%d" % [seed, screens])
    tx.reset_test_only()
    var box = OUTBOX.new()
    box.configure("r4m08_matrix_%d_%d" % [seed, screens])
    if DirAccess.dir_exists_absolute(box.lock_path()):
        DirAccess.remove_absolute(box.lock_path() + "/owner.txt")
        DirAccess.remove_absolute(box.lock_path())
    box.reset_test_only()
    var second = OUTBOX.new()
    second.configure("r4m08_matrix_%d_%d" % [seed, screens])
    var adapter = ADAPTER.new()
    var stage = create_scene(seed, screens)
    await frames(20)
    check(stage.placement_gate["blocked"], "production gate locked")
    check(not box.pending(tx, stage.route)["passed"], "no transaction has no pending state")
    check(box.acquire_writer()["passed"], "owner acquired writer directory")
    check(box.holds_writer(), "owner persisted")
    check(not box.acquire_writer()["passed"], "double acquire denied")
    check(not second.acquire_writer()["passed"], "another writer denied")
    check(not second.release_writer(), "nonowner cannot release")
    check(not adapter.request_real_item("star")["passed"], "real item API still locked")
    stage.demo.actor.global_position = Vector2(stage.DISTRICT_START + 70, 450)
    stage.demo.actor.velocity = Vector2.ZERO
    await frames(12)
    var entrance: Dictionary = await ENTRY.drive(stage)
    check(entrance["passed"] and entrance["last_grounded"], "native entrance")
    var prefix: Array = []
    for pad in [5, 11, 15]:
        if pad >= stage.route["pads"].size(): continue
        var edge: Dictionary = await SEG.segment(stage, prefix.size(), pad)
        check(edge["passed"] and edge["edges"].size() == pad - prefix.size(), "native edge segment " + str(pad))
        if not edge["passed"]: break
        prefix.append_array(edge["edges"])
        var committed: Dictionary = tx.commit_from_actor(stage, entrance, prefix)
        check(committed["passed"], "whole transaction committed " + str(pad))
        check(adapter.apply_verified(stage, tx)["passed"], "adapter publishes verified QA projection " + str(pad))
        var pre: Dictionary = box.pending(tx, stage.route)
        check(pre["passed"] and pre["ids"].size() == 1, "exactly one pending unacknowledged receipt " + str(pad))
        check(not second.acknowledge(stage, tx, adapter)["passed"], "unlocked writer rejected")
        var previous: Dictionary = box.load_latest(tx, stage.route)
        for fault in ["before_write", "partial_temp", "verified_temp"]:
            var result: Dictionary = box.acknowledge(stage, tx, adapter, fault)
            check(result.get("interrupted", false) and not result["passed"], "intentional pre-rename abort " + fault)
            var now: Dictionary = box.load_latest(tx, stage.route)
            check(now.get("valid", false) == previous.get("valid", false), "pre-rename durable generation unchanged " + fault)
            if now.get("valid", false) and previous.get("valid", false):
                check(now["record"]["generation"] == previous["record"]["generation"], "no advanced ack " + fault)
        var ack: Dictionary = box.acknowledge(stage, tx, adapter)
        check(ack["passed"] and not ack.get("idempotent", true), "ack transaction " + str(pad))
        var latest: Dictionary = box.load_latest(tx, stage.route)
        check(latest["valid"] and latest["at_latest_generation"], "ack latest verified " + str(pad))
        check(latest["record"]["receipt_ids"].size() == committed["generation"], "ack has cumulative unique ids")
        var none: Dictionary = box.pending(tx, stage.route)
        check(none["passed"] and none["ids"].is_empty(), "no pending after ack")
        check(box.acknowledge(stage, tx, adapter).get("idempotent", false), "replayed ack idempotent")
        check(not box.acknowledge(stage, tx, adapter, "invalid")["passed"], "unknown fault rejected")
        check(stage.event_projection["fragments"] == committed["generation"], "read-only projection exact")
        stage.show_outbox({"status":"ACKNOWLEDGED", "generation":committed["generation"], "pending":0,"lock":"held"})
        check(stage.outbox_view["pending"] == 0, "visible HUD acknowledges zero pending")
        check(stage.placement_gate["blocked"] and stage.placement_gate["items"].is_empty() and stage.placement_gate["events"].is_empty(), "world remains locked")
    check(prefix.size() == 15, "native prefix reaches pad15")
    var persisted: Dictionary = box.load_latest(tx, stage.route)
    check(persisted["valid"] and persisted["record"]["generation"] == 3, "third generation ack")
    # Test tampering, including rewrapping with a valid public checksum.
    var ack_path: String = box.slot_path(3)
    var backup: String = FileAccess.get_file_as_string(ack_path)
    var tampered: Dictionary = persisted["record"].duplicate(true)
    tampered["receipt_ids"][0] = "forged_receipt"
    var f: FileAccess = FileAccess.open(ack_path, FileAccess.WRITE)
    f.store_string(JSON.stringify(OUTBOX.pack_envelope(tampered)) + "\n")
    f.close()
    check(not box.load_latest(tx, stage.route).get("valid", false), "forged valid-checksum ack fails verification")
    check(not box.pending(tx, stage.route)["passed"], "no pending delivery from broken journal")
    check(not box.acknowledge(stage, tx, adapter)["passed"], "tampered acknowledgement cannot be overwritten")
    f = FileAccess.open(ack_path, FileAccess.WRITE)
    f.store_string(backup)
    f.close()
    check(box.load_latest(tx, stage.route)["valid"], "restored exact acknowledgement")
    check(not box.acknowledge(stage, tx, adapter, "unlisted")["passed"], "fault domain bounded")
    # A new process/scene must reconstruct the original QA checkpoint before ACK.
    stage.queue_free()
    await frames(6)
    stage = create_scene(seed, screens)
    adapter.reset_for_new_scene()
    await frames(20)
    check(not box.acknowledge(stage, tx, adapter)["passed"], "ack refused before checkpoint restore")
    var resumed: Dictionary = await tx.recover_scene(stage)
    check(resumed["passed"] and resumed["pad"] == 15, "native restored floor pad15")
    check(not box.acknowledge(stage, tx, adapter)["passed"], "ack refused before view delivery")
    check(adapter.apply_verified(stage, tx)["passed"], "event projection reconstituted")
    check(box.acknowledge(stage, tx, adapter).get("idempotent", false), "same durable ACK does not multiply receipts")
    check(box.pending(tx, stage.route)["ids"].is_empty(), "pending remains empty across scene restart")
    var tail: Dictionary = await SEG.segment(stage, 15, stage.route["pads"].size() - 1)
    check(tail["passed"], "uninterrupted native final chain after checkpoint recovery")
    var merged: Array = tx.load_latest(stage.route)["record"]["checkpoint"]["prefix"].duplicate(true)
    merged.append_array(tail["edges"])
    var trace: Dictionary = {"passed": true, "completed": merged.size(), "edges": merged,
        "content_blocked": true, "controller": "S33 -410 impulse / 1050 gravity / 220 walk"}
    var cert: Dictionary = PROOF.issue(stage.route, entrance, trace)
    check(cert["valid"] and not cert["authorizes_gameplay_spawns"], "full native route certificate remains QA only")
    check(box.release_writer(), "lock owner released directory")
    check(not box.holds_writer(), "lock gone")
    check(second.acquire_writer()["passed"], "second writer may acquire only after release")
    check(second.release_writer(), "second writer may release own lock")
    check(stage.placement_gate["blocked"], "final spawn gate remains locked")
    var report: Dictionary = {"milestone":"R4-M08","seed":seed,"screens":screens,
        "assertions":checks,"failures":failures,"commits":[5,11,15],"acknowledgements":3,
        "native_elevated_links":merged.size(),"production_gameplay_spawns":false}
    var file: FileAccess = FileAccess.open("res://reports/R4_M08_OUTBOX_%d_%d.json" % [seed,screens], FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report, "  ") + "\n")
        file.close()
    print("R4_M08_RESULT seed=",seed," screens=",screens," checks=",checks," failures=",failures,
        " native_links=",merged.size()," committed=3 acknowledged=3")
    quit(0 if failures == 0 else 1)
func _initialize() -> void: call_deferred("run")
