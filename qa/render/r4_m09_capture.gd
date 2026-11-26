extends SceneTree
const STAGE=preload("res://scenes/r4_m09_unified_writer_review.tscn")
const COORD=preload("res://scripts/r4_m09_coordinator.gd")
const ENTRY=preload("res://scripts/r4_m02_ascent_driver.gd")
const SEG=preload("res://scripts/r4_m04_segment_driver.gd")
var screenshots:=0
var failures:=0
func frames(n:int)->void:
    for i in range(n): await process_frame
func shot(stage:Node2D,label:String)->void:
    await RenderingServer.frame_post_draw
    var img:Image=stage.get_viewport().get_texture().get_image()
    var result:int=img.save_png("res://captures/r4_m09_engine/"+label+".png")
    if result==OK and img.get_width()==960 and img.get_height()==540:
        screenshots+=1
        print("R4_M09_CAPTURE ",label," 960x540")
    else:
        failures+=1
func status(stage:Node2D,coord:RefCounted,note:String)->void:
    var row:Dictionary=coord.status(stage.route)
    var gen:int=int(row.get("generation",0))
    var pending:int=int(row.get("pending",0))
    var ack:int=gen-1 if pending>0 else gen
    stage.show_outbox({"status":note,"generation":ack,"pending":pending,"lock":"held" if coord.owns() else "none"})
    stage.show_unified({"status":note,"tx":gen,"ack":ack,"lock":"held" if coord.owns() else "none"})
func run()->void:
    var c=COORD.new()
    c.configure("r4m09_visual_41_4")
    if DirAccess.dir_exists_absolute(c.outbox.lock_path()):
        DirAccess.remove_absolute(c.outbox.lock_path()+"/owner.txt")
        DirAccess.remove_absolute(c.outbox.lock_path())
    c.reset_test_only()
    var s=STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    await frames(18)
    s.demo.actor.global_position=Vector2(s.DISTRICT_START+70,450)
    s.demo.actor.velocity=Vector2.ZERO
    await frames(12)
    status(s,c,"NO WRITER")
    await shot(s,"00_ground_no_writer")
    if not c.acquire()["passed"]:quit(2);return
    var e:Dictionary=await ENTRY.drive(s)
    if not e["passed"]:quit(3);return
    status(s,c,"LOCK HELD | NATIVE")
    await shot(s,"01_first_pad_lock")
    var prefix:Array=[]
    for pad in [5,11,15]:
        var seg:Dictionary=await SEG.segment(s,prefix.size(),pad)
        if not seg["passed"]:quit(4);return
        prefix.append_array(seg["edges"])
        var committed:Dictionary=c.guarded_commit(s,e,prefix)
        if not committed["passed"]:quit(5);return
        status(s,c,"TX DURABLE | ACK OPEN")
        await frames(4)
        if pad==5:await shot(s,"02_pad05_tx_pending")
        if pad==11:
            var interrupted:Dictionary=c.guarded_deliver_and_ack(s,"verified_temp")
            if not interrupted.get("interrupted",false):quit(6);return
            status(s,c,"ACK TEMP | NOT COMMITTED")
            await frames(4)
            await shot(s,"04_pad11_ack_fault")
        var ack:Dictionary=c.guarded_deliver_and_ack(s)
        if not ack["passed"]:quit(7);return
        status(s,c,"TX+ACK VERIFIED")
        await frames(4)
        await shot(s,"03_pad05_shared_commit" if pad==5 else "05_pad11_shared_commit" if pad==11 else "06_pad15_shared_commit")
    s.demo.jump_queued=true
    await frames(5)
    if s.demo.actor.is_on_floor():quit(8);return
    status(s,c,"AIRBORNE | NO TX")
    await shot(s,"07_airborne_no_commit")
    s.queue_free()
    await frames(6)
    s=STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    c.adapter.reset_for_new_scene()
    await frames(20)
    if not (await c.recover_scene(s))["passed"]:quit(9);return
    if not c.guarded_deliver_and_ack(s).get("idempotent",false):quit(10);return
    status(s,c,"RECOVERED | NO REPLAY")
    await frames(5)
    await shot(s,"08_reloaded_idempotent")
    var tail:Dictionary=await SEG.segment(s,15,s.route["pads"].size()-1)
    if not tail["passed"]:quit(11);return
    s.set_reduced_motion(true)
    status(s,c,"FULL ROUTE QA PASS")
    await frames(5)
    await shot(s,"09_complete_reduced_motion")
    if not c.release():quit(12);return
    var report:Dictionary={"milestone":"R4-M09","native_images":screenshots,"failures":failures,
        "resolution":"960x540","native_route_completed":tail["passed"],"tx":3,"acks":3,
        "gameplay_spawns":false,"shared_writer":true}
    var fd:=FileAccess.open("res://reports/R4_M09_CAPTURE_SUMMARY.json",FileAccess.WRITE)
    if fd:
        fd.store_string(JSON.stringify(report,"  ")+"\n")
        fd.close()
    print("R4_M09_CAPTURE_RESULT images=",screenshots," failures=",failures)
    quit(0 if failures==0 and screenshots==10 else 13)
func _initialize()->void:call_deferred("run")
