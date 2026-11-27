extends SceneTree
## Three-process isolated v1→v2 / outbox / sink recovery fixture.
const STAGE=preload("res://scenes/r4_m12_versioned_sink_review.tscn")
const PROVIDER=preload("res://scripts/r4_m12_provider.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
var checks:=0
var failures:=0
func check(ok:bool,text:String)->void:
    checks+=1
    if not ok:failures+=1;push_error("R4_M12_CROSS_FAIL "+text)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func run()->void:
    var args:Array=OS.get_cmdline_user_args()
    var mode:String=str(args[0]) if args.size()>0 else "write"
    var seed:int=int(args[1]) if args.size()>1 else 41
    var screens:int=int(args[2]) if args.size()>2 else 4
    var provider=PROVIDER.new()
    var name:String="r4m11_test_r4m12_cross_%d_%d"%[seed,screens]
    check(provider.configure(name).get("passed",false),"configure")
    var lock:String=provider._writer.outbox.lock_path()
    if mode=="write":
        if DirAccess.dir_exists_absolute(lock):
            DirAccess.remove_absolute(lock+"/owner.txt")
            DirAccess.remove_absolute(lock)
        check(provider.reset_test_only().get("passed",false),"fresh journal")
    var scene:Node2D=STAGE.instantiate()
    scene.route_seed=seed
    scene.route_screens=screens
    root.add_child(scene)
    current_scene=scene
    await frames(20)
    check(provider.attach(scene).get("passed",false),"bind stage")
    if mode=="write":
        check(provider.acquire().get("passed",false),"lock acquired")
        scene.demo.actor.global_position=Vector2(scene.DISTRICT_START+70,450)
        scene.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entrance:Dictionary=await ENTRY.drive(scene)
        check(entrance.get("passed",false),"native entrance")
        var prefix:Array=[]
        for index in [5,11]:
            var piece:Dictionary=await SEG.segment(scene,prefix.size(),index)
            check(piece.get("passed",false),"native segment %d"%index)
            if not piece.get("passed",false):quit(1);return
            prefix.append_array(piece["edges"])
            check(provider.save_landing(entrance,prefix).get("passed",false),"saved source TX %d"%index)
            if index==5:
                check(provider.deliver_committed().get("passed",false),"genesis ACK")
                check(provider.deliver_sandbox().get("passed",false),"genesis sink delivery")
        check(provider.status()["generation"]==2 and provider.status()["pending"]==1,"gen2 committed but ACK pending")
        check(not provider.deliver_sandbox().get("passed",true),"sink rejects pending ACK")
        print("R4_M12_CROSS_READY seed=",seed," screens=",screens," checks=",checks," failures=",failures)
        while true:await process_frame
    elif mode=="recover":
        check(not provider.acquire().get("passed",true),"killed owner's stale lock prevents competing writer")
        check(DirAccess.dir_exists_absolute(lock),"stale lock remains after SIGKILL")
        # Test-only, operator-directed recovery: never use on real user data.
        check(DirAccess.remove_absolute(lock+"/owner.txt")==OK,"manual test lock token removal")
        check(DirAccess.remove_absolute(lock)==OK,"manual test stale directory removal")
        check(provider.acquire().get("passed",false),"new process acquired after explicit cleanup")
        check(not provider.deliver_sandbox().get("passed",true),"must first recover scene")
        var recovered:Dictionary=await provider.recover_bound_scene()
        check(recovered.get("passed",false) and recovered.get("native_floor_confirmed",false),"validated native checkpoint recovery")
        check(int(recovered.get("pad",-1))==11,"recover generation2 pad11")
        check(provider.v2_preview().get("view",{}).get("generation",0)==2,"deterministic v2 migration after process termination")
        check(provider.status().get("pending",-1)==1,"prior ACK still pending")
        check(not provider.deliver_sandbox().get("passed",true),"sink refuses pending event")
        check(provider.deliver_committed().get("passed",false),"acknowledge interrupted generation")
        check(provider.deliver_sandbox().get("passed",false),"apply verified v2 sandbox once")
        check(provider.sink_snapshot()["state"]["star_fragments"]==2,"recover complete read-only receipt list")
        check(provider.deliver_sandbox().get("idempotent",false),"no duplicate after delivery")
        check(provider.sink_snapshot()["delivery_count"]==1,"one projection publication in recovering process")
        var tail:Dictionary=await SEG.segment(scene,11,scene.route["pads"].size()-1)
        check(tail.get("passed",false),"native remainder under unchanged S33 physics")
        check(tail.get("completed",0)==scene.route["pads"].size()-12,"tail linked exactly")
        check(provider.release(),"recovery lock released")
    elif mode=="replay":
        check(provider.acquire().get("passed",false),"new replay process obtains writer")
        check((await provider.recover_bound_scene()).get("passed",false),"replay scene recovers floor")
        check(provider.deliver_committed().get("idempotent",false),"ACK already persisted; no duplicate ACK")
        check(provider.deliver_sandbox().get("passed",false),"derive v2 sink once from previous ACK")
        check(provider.deliver_sandbox().get("idempotent",false),"repeat sink replay idempotent")
        check(provider.sink_snapshot()["state"]["star_fragments"]==2,"no QA reward inflation on restart")
        check(provider.sink_snapshot()["delivery_count"]==1,"single in-memory reconstruction")
        check(scene.placement_gate["blocked"] and scene.placement_gate["items"].is_empty(),"gameplay content still locked")
        check(provider.release(),"replay lock released")
    else:check(false,"unknown mode")
    var filename:String="res://reports/R4_M12_CROSS_%s_%d_%d.json"%[mode,seed,screens]
    var f:FileAccess=FileAccess.open(filename,FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"mode":mode,"checks":checks,"failures":failures,
            "native_recovery":true,"production_spawns":false},"  ")+"\n")
        f.close()
    print("R4_M12_CROSS_RESULT mode=",mode," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
