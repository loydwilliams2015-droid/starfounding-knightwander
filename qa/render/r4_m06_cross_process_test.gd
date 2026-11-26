extends SceneTree
const STAGE=preload("res://scenes/r4_m06_transaction_review.tscn")
const TX=preload("res://scripts/r4_m06_transaction.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
var checks:=0
var failures:=0
func test(ok:bool,msg:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("R4_M06_CROSS_FAIL "+msg)
func frames(n:int)->void:
    for i in range(n):await physics_frame
func run()->void:
    var args:Array=OS.get_cmdline_user_args()
    var mode:String=str(args[0]) if args.size()>0 else "write"
    var seed:int=int(args[1]) if args.size()>1 else 41
    var screens:int=int(args[2]) if args.size()>2 else 4
    var tx=TX.new()
    tx.configure("r4m06_cross_%d_%d"%[seed,screens])
    var s=STAGE.instantiate()
    s.route_seed=seed
    s.route_screens=screens
    root.add_child(s)
    current_scene=s
    await frames(18)
    if mode=="write":
        tx.reset_test_only()
        s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
        s.demo.actor.velocity=Vector2.ZERO
        await frames(12)
        var entry:Dictionary=await ENTRY.drive(s)
        test(entry["passed"],"native entry")
        var prefix:Array=[]
        for target in [5,11]:
            var piece:Dictionary=await SEG.segment(s,prefix.size(),target)
            test(piece["passed"],"native segment "+str(target))
            prefix.append_array(piece["edges"])
            test(tx.commit_from_actor(s,entry,prefix)["passed"],"atomic checkpoint "+str(target))
        test(s.qa_projection["star_fragments"]==2,"inventory matches two observed events")
        test(s.qa_projection["event_outcomes"].size()==2,"event outcomes committed")
        test(tx.load_latest(s.route)["record"]["checkpoint"]["pad_index"]==11,"latest checkpoint on disk")
        test(s.placement_gate["blocked"],"world content locked")
    elif mode=="read":
        var disk:Dictionary=tx.load_latest(s.route)
        test(disk.get("valid",false),"reopen committed two-slot record from previous process")
        if not disk.get("valid",false):quit(1);return
        test(int(disk["record"]["checkpoint"]["pad_index"])==11,"pad index durable across normal process exits")
        test(s.qa_projection["star_fragments"]==0,"new process has no prior projection until recovery")
        var rec:Dictionary=await tx.recover_scene(s)
        test(rec["passed"] and rec["native_floor_confirmed"],"validated native floor on reload")
        test(s.qa_projection["star_fragments"]==2,"inventory reconstructed exactly once")
        test(s.qa_projection["event_outcomes"].size()==2,"event history reconstructed")
        var tail:Dictionary=await SEG.segment(s,11,s.route["pads"].size()-1)
        test(tail["passed"],"native continuation from checkpoint across process boundary")
        var all:Array=disk["record"]["checkpoint"]["prefix"].duplicate(true)
        all.append_array(tail["edges"])
        var trace:Dictionary={"passed":true,"completed":all.size(),"edges":all,"content_blocked":true,
            "controller":"S33 -410 impulse / 1050 gravity / 220 walk"}
        var cert:Dictionary=PROOF.issue(s.route,disk["record"]["checkpoint"]["entrance"],trace)
        test(cert["valid"] and not cert["authorizes_gameplay_spawns"],"full route QA-only certificate")
        test(s.qa_projection["star_fragments"]==2 and s.placement_gate["blocked"],"tail traversal did not double-apply reward")
    else:
        test(false,"unknown mode")
    print("R4_M06_CROSS mode=",mode," seed=",seed," screens=",screens," checks=",checks," failures=",failures)
    quit(0 if failures==0 else 1)
func _initialize()->void:call_deferred("run")
