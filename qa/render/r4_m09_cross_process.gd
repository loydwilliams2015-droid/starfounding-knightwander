extends SceneTree
const STAGE = preload("res://scenes/r4_m09_unified_writer_review.tscn")
const COORD = preload("res://scripts/r4_m09_coordinator.gd")
const ENTRY = preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG = preload("res://scripts/r4_m04_segment_driver.gd")
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
    checks+=1
    if not value:
        failures+=1
        push_error("R4_M09_CROSS_FAIL "+label)
func frames(n:int) -> void:
    for i in range(n): await physics_frame
func run()->void:
    var a:Array=OS.get_cmdline_user_args()
    var mode:String=str(a[0]) if a.size()>0 else "write"
    var seed:int=int(a[1]) if a.size()>1 else 41
    var screens:int=int(a[2]) if a.size()>2 else 4
    var c=COORD.new()
    c.configure("r4m09_kill_%d_%d"%[seed,screens])
    var s:Node2D=STAGE.instantiate()
    s.route_seed=seed
    s.route_screens=screens
    root.add_child(s)
    current_scene=s
    await frames(18)
    if mode=="probe":
        check(not c.acquire()["passed"],"another process holds lock")
        check(not c.guarded_commit(s,{},[])["passed"],"unowned checkpoint denied")
        check(not c.guarded_deliver_and_ack(s)["passed"],"unowned ACK denied")
    elif mode=="write":
        if DirAccess.dir_exists_absolute(c.outbox.lock_path()):
            DirAccess.remove_absolute(c.outbox.lock_path()+"/owner.txt")
            DirAccess.remove_absolute(c.outbox.lock_path())
        c.reset_test_only()
        check(c.acquire()["passed"],"cross-process writer acquired")
        s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
        s.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entrance:Dictionary=await ENTRY.drive(s)
        check(entrance["passed"],"native first pad")
        var first:Dictionary=await SEG.segment(s,0,5)
        check(first["passed"],"native segment first")
        var prefix:Array=first["edges"].duplicate(true)
        check(c.guarded_commit(s,entrance,prefix)["passed"],"TX genesis under shared lock")
        check(c.guarded_deliver_and_ack(s)["passed"],"genesis ACK under same lock")
        var middle:Dictionary=await SEG.segment(s,5,11)
        check(middle["passed"],"native segment middle")
        prefix.append_array(middle["edges"])
        check(c.guarded_commit(s,entrance,prefix)["passed"],"TX 2 committed, ACK deliberately pending")
        check(c.status(s.route)["pending"]==1,"one pending before external SIGKILL")
        print("R4_M09_READY_FOR_SIGKILL seed=",seed," screens=",screens," generation=2 pending=1")
        await create_timer(300).timeout
        check(false,"uninterrupted holder was expected to be SIGKILLed")
    elif mode=="read" or mode=="replay":
        check(c.acquire()["passed"],"fresh owner acquired after controlled lock cleanup")
        check(c.status(s.route)["valid"] and c.status(s.route)["generation"]==2,"transaction survives SIGKILL")
        check(c.status(s.route)["pending"]==(1 if mode=="read" else 0),"correct pending before delivery")
        var recovered:Dictionary=await c.recover_scene(s)
        check(recovered["passed"] and recovered["native_floor_confirmed"],"restore real collision contact")
        var ack:Dictionary=c.guarded_deliver_and_ack(s)
        check(ack["passed"] and ack.get("idempotent",false)==(mode=="replay"),"only one durable ACK across processes")
        check(c.status(s.route)["pending"]==0,"no pending receipts")
        if mode=="read":
            var tail:Dictionary=await SEG.segment(s,11,s.route["pads"].size()-1)
            check(tail["passed"],"native tail after terminated writer recovery")
        check(s.placement_gate["blocked"] and s.placement_gate["items"].is_empty(),"actual item spawn locked")
        check(c.release(),"successor lock released")
    else:
        check(false,"unsupported phase")
    print("R4_M09_CROSS phase=",mode," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
