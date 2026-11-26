extends RefCounted
## Controller-specific staged ascent. Intent: real footholds, not a false visual bridge.
## Each step has a one-way collider and a visible top that matches its collision.
const GROUND_TOP := 450.0
const S33_JUMP := 410.0
const S33_GRAVITY := 1050.0
const SAFE_RISE := 55.0 # deliberately below idealized 80-unit lift
const STEP_WIDTH := 82.0
const STEP_HEIGHT := 14.0
static func design(route: Dictionary) -> Dictionary:
    if route.get("pads",[]).is_empty():
        return {"valid":false,"steps":[],"reason":"no first platform"}
    var pad: Dictionary=route["pads"][0]
    var top: float=float(pad["y"])-float(pad["height"])*0.5
    var rise: float=GROUND_TOP-top
    if rise<=0.0 or rise>230.0:
        return {"valid":false,"steps":[],"reason":"outside safe ascent envelope"}
    var segments: int=maxi(1,int(ceil(rise/SAFE_RISE)))
    # Real collision ladder. No items/events added by this planner.
    var steps: Array[Dictionary]=[]
    for i in range(1,segments):
        var x: float=float(pad["x"])-100.0+float(i-1)*48.0
        var y: float=GROUND_TOP-rise*float(i)/float(segments)
        steps.append({"index":i-1,"x":x,"y":y+STEP_HEIGHT*0.5,
            "width":STEP_WIDTH,"height":STEP_HEIGHT,"top_y":y,
            "collision_one_way":true,"material":"stone","spawn_authority":false})
    return {"valid":true,"steps":steps,"segments":segments,"highest_rise":rise/float(segments),
        "target_pad_top":top,"first_pad_index":0,"actor_jump":S33_JUMP,
        "actor_gravity":S33_GRAVITY,"certified":false,"spawns_allowed":false,
        "reason":"candidate must pass native continuous platform landings"}
static func validate(candidate: Dictionary, route: Dictionary) -> Dictionary:
    var faults: Array[String]=[]
    if not candidate.get("valid",false): faults.append("invalid plan")
    var steps: Array=candidate.get("steps",[])
    var old_top: float=GROUND_TOP
    for step in steps:
        var top: float=step["top_y"]
        if old_top-top>SAFE_RISE+0.01 or old_top-top<=0: faults.append("unsafe rise")
        if not is_equal_approx(step["y"]-step["height"]*0.5,top): faults.append("collider / top mismatch")
        if step.get("spawn_authority",true): faults.append("step authorized a spawn")
        old_top=top
    if candidate.get("valid",false) and candidate.get("target_pad_top",0.0) < old_top-SAFE_RISE-0.01: faults.append("last jump too high")
    if candidate.get("spawns_allowed",true): faults.append("spawn gate bypass")
    return {"passed":faults.is_empty(),"faults":faults,"steps":steps.size()}
