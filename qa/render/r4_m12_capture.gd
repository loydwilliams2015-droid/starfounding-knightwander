extends SceneTree
const STAGE=preload("res://scenes/r4_m12_versioned_sink_review.tscn")
const PROVIDER=preload("res://scripts/r4_m12_provider.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
var shots:int=0
var failures:int=0
func frames(n:int)->void:
    for i in range(n):await process_frame
func display(s:Node2D,p:RefCounted,message:String)->void:
    var status:Dictionary=p.status()
    var generation:int=int(status.get("generation",0))
    var pending:int=int(status.get("pending",0))
    s.show_provider({"mode":message,"owns":p.owns(),"generation":generation,"pending":pending})
    s.show_gateway({"mode":message,"owner":"held" if p.owns() else "none","blocked":int(p.snapshot().get("denials",0))})
    s.show_unified({"status":message,"tx":generation,"ack":generation-pending,"lock":"held" if p.owns() else "none"})
    s.show_outbox({"status":message,"generation":generation-pending,"pending":pending,"lock":"held" if p.owns() else "none"})
    s.show_sandbox(p.sink_snapshot())
func shot(s:Node2D,name:String)->void:
    await frames(3)
    await RenderingServer.frame_post_draw
    var image:Image=s.get_viewport().get_texture().get_image()
    var path:String="res://captures/r4_m12_engine/"+name+".png"
    var code:int=image.save_png(path)
    if code==OK and image.get_width()==960 and image.get_height()==540:
        shots+=1
        print("R4_M12_CAPTURE ",name," 960x540")
    else:
        failures+=1
        push_error("R4 M12 screenshot invalid "+name)
func run()->void:
    var p=PROVIDER.new()
    if not p.configure("r4m11_test_r4m12_capture_41_4").get("passed",false):quit(1);return
    var lock:String=p._writer.outbox.lock_path()
    if DirAccess.dir_exists_absolute(lock):
        DirAccess.remove_absolute(lock+"/owner.txt")
        DirAccess.remove_absolute(lock)
    if not p.reset_test_only().get("passed",false):quit(2);return
    var s:Node2D=STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    await frames(20)
    p.attach(s)
    s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    display(s,p,"v1-to-v2 QA START")
    await shot(s,"00_ground_before_migration")
    if not p.acquire().get("passed",false):quit(3);return
    var entrance:Dictionary=await ENTRY.drive(s)
    if not entrance.get("passed",false):quit(4);return
    display(s,p,"FIRST NATIVE PAD")
    await shot(s,"01_first_pad_native")
    var prefix:Array=[]
    for target in [5,11,15]:
        var part:Dictionary=await SEG.segment(s,prefix.size(),target)
        if not part.get("passed",false):quit(5);return
        prefix.append_array(part["edges"])
        if not p.save_landing(entrance,prefix).get("passed",false):quit(6);return
        display(s,p,"v1 TX / v2 READ-ONLY / ACK PENDING")
        await shot(s,"02_pad05_v2_pending" if target==5 else "04_pad11_ack_pending" if target==11 else "07_pad15_pending")
        if not p.deliver_committed().get("passed",false):quit(7);return
        if target==11:
            var fault:Dictionary=p.deliver_sandbox("after_events")
            if not fault.get("rolled_back",false):quit(8);return
            display(s,p,"STAGED FAULT / ROLLED BACK")
            await shot(s,"05_pad11_fault_compensated")
        if not p.deliver_sandbox().get("passed",false):quit(9);return
        display(s,p,"v2 SINK VERIFIED / NO GAME REWARD")
        await shot(s,"03_pad05_ack_sink" if target==5 else "06_pad11_sink_delivered" if target==11 else "08_pad15_sink_delivered")
    s.demo.jump_queued=true
    await frames(5)
    if s.demo.actor.is_on_floor():quit(10);return
    display(s,p,"AIRBORNE / UNCHECKPOINTED")
    await shot(s,"09_airborne_not_saved")
    p.detach()
    s.queue_free()
    await frames(6)
    s=STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    await frames(20)
    p.attach(s)
    if not (await p.recover_bound_scene()).get("passed",false):quit(11);return
    if not p.deliver_sandbox().get("passed",false):quit(12);return
    display(s,p,"RELOADED v2 / NO DUPLICATES")
    await shot(s,"10_recovered_checkpoint")
    var end:Dictionary=await SEG.segment(s,15,s.route["pads"].size()-1)
    if not end.get("passed",false):quit(13);return
    s.set_reduced_motion(true)
    display(s,p,"FULL NATIVE ROUTE PASS / REDUCED MOTION")
    await shot(s,"11_final_reduced_motion")
    if not p.release():quit(14);return
    var result:Dictionary={"milestone":"R4-M12","screenshots":shots,"failures":failures,
        "resolution":[960,540],"renderer":"Godot 4.7.2 OpenGL / Mesa Xvfb",
        "native_route_completed":true,"versioned_source":1,"versioned_view":2,
        "production_gameplay_spawns":false,"scripted_qa":true}
    var f:FileAccess=FileAccess.open("res://reports/R4_M12_CAPTURE_SUMMARY.json",FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(result,"  ")+"\n")
        f.close()
    print("R4_M12_CAPTURE_RESULT shots=",shots," failures=",failures)
    quit(0 if failures==0 and shots==12 else 15)
func _initialize()->void:call_deferred("run")
