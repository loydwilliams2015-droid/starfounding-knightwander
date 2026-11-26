extends SceneTree
const STAGE = preload("res://scenes/r4_m00_render_review.tscn")
const POLICY = preload("res://scripts/r4_m00_render_policy.gd")
func frames(n: int) -> void:
    for i in range(n): await process_frame
func capture(stage: Node2D, label: String) -> bool:
    await RenderingServer.frame_post_draw
    var img: Image=stage.get_viewport().get_texture().get_image()
    var path="res://captures/r4_m00_engine/"+label+".png"
    var code=img.save_png(path)
    print("R4_M00_CAPTURE ",label," code=",code," size=",img.get_width(),"x",img.get_height())
    return code==OK and img.get_width()==960 and img.get_height()==540
func run() -> void:
    var stage=STAGE.instantiate()
    root.add_child(stage)
    current_scene=stage
    await frames(14)
    stage.demo.actor.global_position=Vector2(1700,450)
    stage.demo.actor.velocity=Vector2.ZERO
    var count:=0
    for b in POLICY.BIOMES:
        for mode in POLICY.LIGHT_MODES:
            stage.set_reduced_motion(false)
            stage.apply_render_motif(b,mode)
            await frames(8)
            if await capture(stage,b+"_"+mode): count+=1
    stage.set_reduced_motion(true)
    stage.apply_render_motif("relicwright","beacon")
    await frames(8)
    if await capture(stage,"relicwright_beacon_reduced_motion"): count+=1
    print("R4_M00_CAPTURE_RESULT captured=",count," expected=9")
    quit(0 if count==9 else 1)
func _initialize() -> void: call_deferred("run")
