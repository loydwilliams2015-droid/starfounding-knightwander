extends SceneTree
## Native S33 traversal and fail-closed v1->v2 migration/sandbox delivery QA.
const STAGE=preload("res://scenes/r4_m12_versioned_sink_review.tscn")
const PROVIDER=preload("res://scripts/r4_m12_provider.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
const MIGRATION=preload("res://scripts/r4_m12_migration.gd")
const SINK=preload("res://scripts/r4_m12_sandbox_sink.gd")
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("R4_M12_FAIL: "+label)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func create_stage(seed:int,screens:int)->Node2D:
    var scene:Node2D=STAGE.instantiate()
    scene.route_seed=seed
    scene.route_screens=screens
    root.add_child(scene)
    current_scene=scene
    return scene
func run()->void:
    var args:Array=OS.get_cmdline_user_args()
    var seed:int=int(args[0]) if args.size()>0 else 41
    var screens:int=int(args[1]) if args.size()>1 else 4
    var name:String="r4m11_test_r4m12_%d_%d"%[seed,screens]
    var p=PROVIDER.new()
    var rival=PROVIDER.new()
    check(not p.configure("untrusted_scope").get("passed",true),"reject foreign namespace")
    check(p.configure(name).get("passed",false),"configure isolated provider")
    check(rival.configure(name).get("passed",false),"configure rival")
    # Stale lock explicitly removed only within this disposable test scope.
    var old_lock:String=p._writer.outbox.lock_path()
    if DirAccess.dir_exists_absolute(old_lock):
        DirAccess.remove_absolute(old_lock+"/owner.txt")
        DirAccess.remove_absolute(old_lock)
    check(p.reset_test_only().get("passed",false),"clear isolated QA test state")
    var s:Node2D=create_stage(seed,screens)
    await frames(20)
    check(p.attach(s).get("passed",false),"bind scene")
    check(rival.attach(s).get("passed",false),"bind competing scene")
    check(not p.deliver_sandbox().get("passed",true),"sandbox cannot apply without lock")
    check(not p.v2_preview().get("passed",true),"nothing to migrate before first save")
    check(p.acquire().get("passed",false),"acquire single writer")
    check(not rival.acquire().get("passed",true),"competing writer denied")
    check(not rival.deliver_sandbox().get("passed",true),"competing delivery denied")
    check(not p.request_real_item("star").get("passed",true),"no production items")
    check(not p.request_real_event("quest").get("passed",true),"no production events")
    check(not p.sandbox_sink.request_gameplay_item("star").get("passed",true),"sink has no gameplay item method")
    check(not p.sandbox_sink.request_gameplay_event("quest").get("passed",true),"sink has no gameplay event method")
    s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    var entrance:Dictionary=await ENTRY.drive(s)
    check(entrance.get("passed",false) and entrance.get("last_grounded",false),"native entrance to first pad")
    var prefix:Array=[]
    for target in [5,11,15]:
        var piece:Dictionary=await SEG.segment(s,prefix.size(),target)
        check(piece.get("passed",false),"native segment %d"%target)
        if not piece.get("passed",false):break
        prefix.append_array(piece["edges"])
        check(prefix.size()==target,"source proof prefix length")
        var tx:Dictionary=p.save_landing(entrance,prefix)
        check(tx.get("passed",false),"persist v1 checkpoint %d"%target)
        var v2:Dictionary=p.v2_preview()
        check(v2.get("passed",false),"migrate verified v1 to v2 view")
        var v:Dictionary=v2.get("view",{})
        check(int(v.get("version",-1))==2 and v.get("format","")==MIGRATION.FORMAT,"v2 schema marker")
        check(v.get("writes_to_original_save",true)==false and not v.get("production_spawn_authority",true),"migrated view never writes or spawns")
        check(v.get("source_tx_digest","")==p._writer.tx.load_latest(s.route)["digest"],"source digest bound")
        check(v.get("controller_id","")==PROOF.CONTROLLER_ID,"controller unchanged")
        check(v.get("star_fragments",-1)==p.status()["generation"],"migrated inventory reconciles")
        var disk:Dictionary=p._writer.tx.load_latest(s.route)
        check(MIGRATION.validate(s.route,disk,v)["passed"],"exact deterministic conversion")
        check(MIGRATION.migrate(s.route,disk)["view"]==v,"idempotent non-mutating migration")
        var damaged:Dictionary=v.duplicate(true)
        damaged["star_fragments"]=999
        check(not MIGRATION.validate(s.route,disk,damaged)["passed"],"reject tampered inventory with stale checksum")
        damaged=v.duplicate(true)
        damaged["source_tx_digest"]="0".repeat(64)
        damaged["view_digest"]=MIGRATION.canonical_digest(damaged)
        check(not MIGRATION.validate(s.route,disk,damaged)["passed"],"checksum alone cannot forge source provenance")
        damaged=v.duplicate(true)
        damaged["production_spawn_authority"]=true
        damaged["view_digest"]=MIGRATION.canonical_digest(damaged)
        check(not MIGRATION.validate(s.route,disk,damaged)["passed"],"deny migrated production authority")
        check(not p.deliver_sandbox().get("passed",true),"sink cannot bypass pending acknowledgement")
        check(p.status().get("pending",-1)==1,"one durable pending receipt")
        var saved_preview:Dictionary=p.sink_snapshot()
        var acknowledged:Dictionary=p.deliver_committed()
        check(acknowledged.get("passed",false),"ACK committed before sink")
        for fault in ["after_inventory","after_events","before_publish"]:
            var dropped:Dictionary=p.deliver_sandbox(fault)
            check(not dropped.get("passed",true) and dropped.get("rolled_back",false),"stage discarded %s"%fault)
            check(p.sink_snapshot()["state"]==saved_preview["state"],"fault left live sink unchanged %s"%fault)
        var accepted:Dictionary=p.deliver_sandbox()
        check(accepted.get("passed",false) and not accepted.get("idempotent",true),"deliver acknowledged v2 view once")
        check(p.sink_snapshot()["state"]["star_fragments"]==p.status()["generation"],"sink fragments exactly one per receipt")
        check(p.sink_snapshot()["state"]["ids"].size()==p.status()["generation"],"sink receipts match current generation")
        check(s.sandbox_state["state"]["star_fragments"]==p.sink_snapshot()["state"]["star_fragments"],"HUD sees committed sandbox only")
        check(p.deliver_sandbox().get("idempotent",false),"duplicate delivery returns no effect")
        check(not p.deliver_sandbox("unknown_fault").get("passed",true),"invalid delivery fault denied")
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty() and s.placement_gate["events"].is_empty(),"all real content locked")
    check(prefix.size()==15,"completed three native checkpoint segments")
    check(p.sink_snapshot()["delivery_count"]==3,"exactly three sink projection publications")
    check(p.sink_snapshot()["rolled_back_count"]==9,"all nine staging failures compensated")
    check(not rival.deliver_sandbox().get("passed",true),"competitor still denied")
    check(p.release(),"owner released")
    check(not p.deliver_sandbox().get("passed",true),"no delivery without writer ownership")
    p.detach()
    s.queue_free()
    await frames(8)
    s=create_stage(seed,screens)
    await frames(20)
    check(p.attach(s).get("passed",false),"attach fresh scene")
    check(p.acquire().get("passed",false),"reopen writer")
    check(not p.deliver_sandbox().get("passed",true),"must recover checkpoint before receipt delivery")
    var recovered:Dictionary=await p.recover_bound_scene()
    check(recovered.get("passed",false) and recovered.get("native_floor_confirmed",false),"restore native floor safely")
    check(p.sink_snapshot()["state"]["generation"]==0,"fresh scene has no stale sink effects")
    check(p.deliver_sandbox().get("passed",false),"reconstruct v2 sandbox from persisted ACK after restart")
    check(p.sink_snapshot()["state"]["star_fragments"]==3,"replay reconstructed exactly three receipts")
    check(p.deliver_sandbox().get("idempotent",false),"replay again without duplicate")
    var tail:Dictionary=await SEG.segment(s,15,s.route["pads"].size()-1)
    check(tail.get("passed",false),"native tail traversal")
    var all:Array=p._writer.tx.load_latest(s.route)["record"]["checkpoint"]["prefix"].duplicate(true)
    all.append_array(tail.get("edges",[]))
    var evidence:Dictionary={"passed":true,"completed":all.size(),"edges":all,"content_blocked":true,
        "controller":"S33 -410 impulse / 1050 gravity / 220 walk"}
    var certificate:Dictionary=PROOF.issue(s.route,entrance,evidence)
    check(certificate.get("valid",false) and not certificate.get("authorizes_gameplay_spawns",true),"native full-chain certificate QA-only")
    check(p.release(),"final lock release")
    check(not MIGRATION.migrate(s.route,{"valid":false})["passed"],"cannot migrate unavailable source")
    var last:Dictionary=p.sink_snapshot()
    check(last["production_spawn_authority"]==false,"sink permanently non-production")
    var result:Dictionary={"milestone":"R4-M12","seed":seed,"screens":screens,
        "checks":checks,"failures":failures,"native_links":all.size(),
        "source_version":1,"view_version":2,"checkpoint_generations":3,
        "sink_deliveries":3,"sandbox_only":true,"power_loss_durable":false}
    var filename:String="res://reports/R4_M12_%d_%d.json"%[seed,screens]
    var f:FileAccess=FileAccess.open(filename,FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(result,"  ")+"\n")
        f.close()
    print("R4_M12_RESULT seed=",seed," screens=",screens," checks=",checks," failures=",failures," native_links=",all.size())
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
