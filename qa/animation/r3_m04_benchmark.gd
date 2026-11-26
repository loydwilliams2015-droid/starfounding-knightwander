extends SceneTree
const STAGE = preload("res://scenes/r3_m04_accessibility.tscn")
const TRIAL_FRAMES := 160
const WARMUP_FRAMES := 30
func percentile(values: Array[float], q: float) -> float:
    var sorted: Array[float]=values.duplicate()
    sorted.sort()
    return sorted[clampi(int(ceil(float(sorted.size())*q))-1,0,sorted.size()-1)]
func frame_series(stage: Node2D, reduced: bool, label: String) -> Dictionary:
    Input.action_release("sk_right")
    stage.demo.actor.global_position=Vector2(1700.0,450.0)
    stage.demo.actor.velocity=Vector2.ZERO
    stage.set_reduced_motion(reduced)
    for i in range(WARMUP_FRAMES): await process_frame
    var prior: Dictionary=stage.fixtures.budget_snapshot()
    var prior_physics: int=stage.demo.physics_steps
    var elapsed_ms: Array[float]=[]
    var engine_ms: Array[float]=[]
    var fps_samples: Array[float]=[]
    for i in range(TRIAL_FRAMES):
        if i==10: Input.action_press("sk_right")
        if i==110: Input.action_release("sk_right")
        var start: int=Time.get_ticks_usec()
        await process_frame
        elapsed_ms.append(float(Time.get_ticks_usec()-start)/1000.0)
        engine_ms.append(float(Performance.get_monitor(Performance.TIME_PROCESS))*1000.0)
        fps_samples.append(float(Performance.get_monitor(Performance.TIME_FPS)))
    Input.action_release("sk_right")
    var post: Dictionary=stage.fixtures.budget_snapshot()
    var total: float=0.0
    for v in elapsed_ms: total+=v
    var cpu_ms_sum: float=0.0
    for v in engine_ms: cpu_ms_sum+=v
    return {"mode":label,"reduced_motion":reduced,"sample_frames":TRIAL_FRAMES,
        "elapsed_frame_p50_ms":percentile(elapsed_ms,0.50),
        "elapsed_frame_p95_ms":percentile(elapsed_ms,0.95),
        "elapsed_frame_mean_ms":total/TRIAL_FRAMES,
        "engine_process_p50_ms":percentile(engine_ms,0.5),
        "engine_process_p95_ms":percentile(engine_ms,0.95),
        "engine_process_mean_ms":cpu_ms_sum/TRIAL_FRAMES,
        "fps_monitor_median":percentile(fps_samples,0.5),
        "ornament_draws":int(post["draw_calls"])-int(prior["draw_calls"]),
        "ornament_process_callbacks":int(post["active_updates"])-int(prior["active_updates"]),
        "ornament_paused_callbacks":int(post["paused_updates"])-int(prior["paused_updates"]),
        "ornament_draw_cpu_ms":float(int(post["draw_cpu_us_total"])-int(prior["draw_cpu_us_total"]))/1000.0,
        "physics_steps":stage.demo.physics_steps-prior_physics,
        "actor_x":stage.demo.actor.global_position.x,"actor_on_floor":stage.demo.actor.is_on_floor(),
        "parallax_scales":str(stage.motion_snapshot()["parallax_scales"]),
        "camera_anticipation":stage.s29_lookahead_enabled}
func run() -> void:
    var s=STAGE.instantiate()
    root.add_child(s)
    current_scene=s
    for i in range(20): await process_frame
    s.set_r3_biome("industrial")
    var enabled: Dictionary=await frame_series(s,false,"decorative_motion_on")
    var suppressed: Dictionary=await frame_series(s,true,"reduced_motion_on")
    var again: Dictionary=await frame_series(s,false,"decorative_motion_restored")
    var output: Dictionary={
        "milestone":"R3-M04","engine":"Godot "+str(Engine.get_version_info().get("string","unknown")),
        "renderer":"OpenGL compatibility via Xvfb virtual display",
        "os":OS.get_name(),"resolution":"960x540",
        "frames_per_mode":TRIAL_FRAMES,
        "method":"Frame-to-frame wall elapsed and Godot TIME_PROCESS monitors; renderer workload included but not GPU profiling; unthrottled virtual display and host contention confound comparisons",
        "warming_frames":WARMUP_FRAMES,
        "modes":[enabled,suppressed,again],
        "fixture_count":s.fixtures.fixtures.size(),
        "performance_acceptance":"diagnostic only; no absolute FPS guarantee",
        "collision_modified":false,"spawn_authority":false,
        "result":"MEASURED"}
    var file:=FileAccess.open("res://reports/R3_M04_PERF_NATIVE.json",FileAccess.WRITE)
    if file==null:
        push_error("Unable to create measured native report")
        quit(1)
        return
    file.store_string(JSON.stringify(output,"  ")+"\n")
    file.close()
    print("R3_M04_PERF measures=3 frame_samples=",TRIAL_FRAMES*3," enabled_draws=",enabled["ornament_draws"]," reduced_draws=",suppressed["ornament_draws"]," restored_draws=",again["ornament_draws"])
    print("R3_M04_PERF frame_p95_ms on=",enabled["elapsed_frame_p95_ms"]," reduced=",suppressed["elapsed_frame_p95_ms"]," restored=",again["elapsed_frame_p95_ms"])
    quit(0)
func _initialize() -> void: call_deferred("run")
