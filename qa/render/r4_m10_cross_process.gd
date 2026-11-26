extends SceneTree
## Real process-termination boundary checks, not sudden power-loss tests.
const STAGE=preload("res://scenes/r4_m10_mandatory_writer_review.tscn")
const COORD=preload("res://scripts/r4_m10_coordinator.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
var checks:=0
var failures:=0
func check(value:bool, label:String)->void:
    checks+=1
    if not value:
        failures+=1
        push_error("R4_M10_CROSS_FAIL "+label)
func frames(n:int)->void:
    for i in range(n): await physics_frame
func run()->void:
    var args:Array=OS.get_cmdline_user_args()
    var mode:String=str(args[0]) if args.size()>0 else "probe"
    var seed:int=int(args[1]) if args.size()>1 else 41
    var screens:int=int(args[2]) if args.size()>2 else 4
    var c=COORD.new()
    var family:String=str(args[3]) if args.size()>3 else "tx" if mode.contains("tx_temp") else "ack"
    c.configure("r4m10_kill_%s_%d_%d"%[family,seed,screens])
    var s=STAGE.instantiate()
    s.route_seed=seed
    s.route_screens=screens
    root.add_child(s)
    current_scene=s
    await frames(20)
    if mode=="probe":
        check(not c.acquire()["passed"],"lock held or stale from another process")
        check(not c.guarded_commit(s,{},[])["passed"],"unowned TX denied")
        check(not c.guarded_deliver_and_ack(s)["passed"],"unowned ACK denied")
        check(not c.tx.commit_from_actor(s,{},[])["passed"],"direct TX denied even when no owner")
        check(not c.outbox.acknowledge(s,c.tx,c.adapter)["passed"],"direct ACK denied even when no owner")
    elif mode=="write_tx_temp" or mode=="write_ack_temp":
        if DirAccess.dir_exists_absolute(c.outbox.lock_path()):
            DirAccess.remove_absolute(c.outbox.lock_path()+"/owner.txt")
            DirAccess.remove_absolute(c.outbox.lock_path())
        c.reset_test_only()
        check(c.acquire()["passed"],"writer acquired strict gateway")
        s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
        s.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entrance:Dictionary=await ENTRY.drive(s)
        check(entrance["passed"],"native entrance")
        var first:Dictionary=await SEG.segment(s,0,5)
        check(first["passed"],"first native section")
        var prefix:Array=first["edges"].duplicate(true)
        check(c.guarded_commit(s,entrance,prefix)["passed"],"TX1 commits")
        check(c.guarded_deliver_and_ack(s)["passed"],"ACK1 commits")
        var second:Dictionary=await SEG.segment(s,5,11)
        check(second["passed"],"second native section")
        prefix.append_array(second["edges"])
        if mode=="write_tx_temp":
            var interrupted:Dictionary=c.guarded_commit(s,entrance,prefix,"verified_temp")
            check(interrupted.get("interrupted",false),"TX2 verified temporary not renamed")
            check(c.status(s.route)["generation"]==1 and c.status(s.route)["pending"]==0,"generation1 remains committed")
        else:
            check(c.guarded_commit(s,entrance,prefix)["passed"],"TX2 committed")
            var ack_fault:Dictionary=c.guarded_deliver_and_ack(s,"verified_temp")
            check(ack_fault.get("interrupted",false),"ACK2 verified temp not renamed")
            check(c.status(s.route)["generation"]==2 and c.status(s.route)["pending"]==1,"generation2 awaits ACK")
        check(not c.tx.commit_from_actor(s,entrance,prefix)["passed"],"direct writer cannot bypass owned lock")
        print("R4_M10_READY_FOR_SIGKILL phase=",mode," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
        await create_timer(300).timeout
        check(false,"writer expected external SIGKILL")
    elif mode=="resume_tx_temp" or mode=="resume_ack_temp" or mode=="replay":
        check(c.acquire()["passed"],"new process obtains lock after explicit cleanup")
        check(not c.tx.commit_from_actor(s,{},[])["passed"],"raw TX blocked with lock")
        check(not c.outbox.acknowledge(s,c.tx,c.adapter)["passed"],"raw ACK blocked with lock")
        var baseline:Dictionary=c.status(s.route)
        var expected_gen:int=1 if mode=="resume_tx_temp" else 2
        check(baseline["valid"] and baseline["generation"]==expected_gen,"expected committed generation survives")
        check(baseline["pending"]==(1 if mode=="resume_ack_temp" else 0),"expected pending ACK state")
        var restored:Dictionary=await c.recover_scene(s)
        check(restored["passed"] and restored["native_floor_confirmed"],"floor contact independently rechecked")
        var start_pad:int=int(restored["pad"])
        if mode=="resume_tx_temp":
            check(start_pad==5,"uncommitted TX2 was not published")
            var middle:Dictionary=await SEG.segment(s,5,11)
            check(middle["passed"],"redo section after discarded TX temp")
            var old:Dictionary=c.tx.load_latest(s.route)["record"]
            var prefix:Array=old["checkpoint"]["prefix"].duplicate(true)
            prefix.append_array(middle["edges"])
            check(c.guarded_commit(s,old["checkpoint"]["entrance"],prefix)["passed"],"successor TX2 committed")
            check(c.guarded_deliver_and_ack(s)["passed"],"successor ACK2 committed")
        elif mode=="resume_ack_temp":
            check(start_pad==11,"TX2 survives uncommitted ACK temp")
            check(c.guarded_deliver_and_ack(s)["passed"],"ACK2 delivered exactly once")
        else:
            check(start_pad==11,"replay restores final acknowledged transaction")
            check(c.guarded_deliver_and_ack(s).get("idempotent",false),"replay does not duplicate acknowledgement")
        check(c.status(s.route)["pending"]==0,"complete outbox acknowledgement")
        if mode!="replay":
            var tail:Dictionary=await SEG.segment(s,11,s.route["pads"].size()-1)
            check(tail["passed"],"native tail after real process termination")
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty() and s.placement_gate["events"].is_empty(),"gameplay authority locked")
        check(c.release(),"successor releases unified writer")
    else:
        check(false,"unknown mode")
    print("R4_M10_CROSS phase=",mode," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
