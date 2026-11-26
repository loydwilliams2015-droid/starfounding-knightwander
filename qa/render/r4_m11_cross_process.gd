extends SceneTree
## Real SIGKILL process-boundary test. Only test harness performs stale cleanup.
const STAGE=preload("res://scenes/r4_m11_provider_review.tscn")
const PROVIDER=preload("res://scripts/r4_m11_provider.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,caption:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("R4_M11_CROSS_FAIL "+caption)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func run()->void:
    var args:Array=OS.get_cmdline_user_args()
    var mode:String=str(args[0]) if args.size()>0 else "probe"
    var phase:String=str(args[1]) if args.size()>1 else "tx"
    var seed:int=int(args[2]) if args.size()>2 else 41
    var screens:int=int(args[3]) if args.size()>3 else 4
    var p=PROVIDER.new()
    var name="r4m11_test_kill_%s_%d_%d"%[phase,seed,screens]
    check(p.configure(name)["passed"],"configure test provider")
    var s=STAGE.instantiate()
    s.route_seed=seed
    s.route_screens=screens
    root.add_child(s)
    current_scene=s
    await frames(20)
    check(p.attach(s)["passed"],"bind scene")
    if mode=="probe":
        check(not p.acquire().get("passed",true),"competing writer denied during live or stale lock")
        check(not p.save_landing({},[]).get("passed",true),"unowned transaction denied")
        check(not p.deliver_committed().get("passed",true),"unowned ACK denied")
        check(not p.reset_test_only().get("passed",true),"test reset does not steal lock")
    elif mode=="write":
        # Dedicated test namespace only. Previous aborted run cleanup is explicit.
        if DirAccess.dir_exists_absolute(p._writer.outbox.lock_path()):
            DirAccess.remove_absolute(p._writer.outbox.lock_path()+"/owner.txt")
            DirAccess.remove_absolute(p._writer.outbox.lock_path())
        check(p.reset_test_only()["passed"],"reset isolated test")
        check(p.acquire()["passed"],"acquire writer")
        s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
        s.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entry:Dictionary=await ENTRY.drive(s)
        check(entry.get("passed",false),"native first pad")
        var first:Dictionary=await SEG.segment(s,0,5)
        check(first.get("passed",false),"native first segment")
        var prefix:Array=first["edges"].duplicate(true)
        check(p.save_landing(entry,prefix).get("passed",false),"generation1 committed")
        check(p.deliver_committed().get("passed",false),"generation1 acknowledged")
        var second:Dictionary=await SEG.segment(s,5,11)
        check(second.get("passed",false),"native second segment")
        prefix.append_array(second["edges"])
        if phase=="tx":
            var interrupted:Dictionary=p.save_landing(entry,prefix,"verified_temp")
            check(interrupted.get("interrupted",false) and not interrupted.get("passed",true),"TX2 temp only")
            check(p.status().get("generation",-1)==1 and p.status().get("pending",-1)==0,"TX2 not visible")
        else:
            check(p.save_landing(entry,prefix).get("passed",false),"TX2 committed")
            var interrupted:Dictionary=p.deliver_committed("verified_temp")
            check(interrupted.get("interrupted",false) and not interrupted.get("passed",true),"ACK2 temp only")
            check(p.status().get("generation",-1)==2 and p.status().get("pending",-1)==1,"ACK2 pending")
        print("R4_M11_READY_FOR_SIGKILL phase=",phase," checks=",checks," failures=",failures)
        await create_timer(300.0).timeout
        check(false,"writer should have been externally killed")
    elif mode=="recover" or mode=="replay":
        check(p.acquire()["passed"],"writer lock manually released, then acquired")
        check(not p.save_landing({},[])["passed"],"bound but ungrounded TX rejected")
        var status:Dictionary=p.status()
        var expected:int=1 if phase=="tx" else 2
        check(status["valid"] and status["generation"]==expected,"correct last committed generation")
        check(status["pending"]==(0 if phase=="tx" else 1 if mode=="recover" else 0),"pending state correct")
        var recovery:Dictionary=await p.recover_bound_scene()
        check(recovery.get("passed",false) and recovery.get("native_floor_confirmed",false),"native floor verified")
        var start_pad:int=int(recovery.get("pad",-1))
        if mode=="replay":
            check(start_pad==11,"replay checkpoint on pad11")
            check(p.deliver_committed().get("idempotent",false),"replayed ACK idempotent")
        elif phase=="tx":
            check(start_pad==5,"invisible TX2 rolls back to pad5")
            var next:Dictionary=await SEG.segment(s,5,11)
            check(next.get("passed",false),"redo native segment")
            var previous:Dictionary=p._writer.tx.load_latest(s.route)["record"]["checkpoint"]
            var prefix:Array=previous["prefix"].duplicate(true)
            prefix.append_array(next["edges"])
            check(p.save_landing(previous["entrance"],prefix).get("passed",false),"TX2 committed after restart")
            check(p.deliver_committed().get("passed",false),"ACK2 committed after restart")
        else:
            check(start_pad==11,"pending ACK recovers from pad11")
            check(p.deliver_committed().get("passed",false),"ACK2 resumed once")
        check(p.status().get("pending",-1)==0,"no remaining pending receipts")
        if mode!="replay":
            var tail:Dictionary=await SEG.segment(s,11,s.route["pads"].size()-1)
            check(tail.get("passed",false),"complete native route after process death")
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty() and s.placement_gate["events"].is_empty(),"no gameplay spawn authority")
        check(p.release(),"release recovered writer")
    else:
        check(false,"unknown mode")
    print("R4_M11_CROSS mode=",mode," phase=",phase," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
