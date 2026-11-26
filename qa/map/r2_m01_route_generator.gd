extends RefCounted
## R2-M01 deterministic route generation; no global random generator.
const SCREEN_WIDTH := 960
const MAX_STEP_X := 190
const MAX_STEP_RISE := 72
const MIN_STEP_X := 130
const MAX_STEP_DROP := 72
static func next_uint(state: int) -> int:
    return int((state * 1664525 + 1013904223) % 4294967296)
static func generate(seed: int, screens: int = 5) -> Dictionary:
    if screens < 4 or screens > 6:
        return {"valid":false,"error":"screen count must be 4..6"}
    var state: int = seed & 0xffffffff
    var pads: Array[Dictionary] = []
    var flat: Array[Dictionary] = []
    for screen in range(screens):
        flat.append({"x":float(screen * SCREEN_WIDTH + SCREEN_WIDTH/2),"y":490.0,"width":float(SCREEN_WIDTH+8),"height":80.0})
    var y: int = 328
    for index in range(screens*5):
        state = next_uint(state)
        y = clampi(y + (int(state % 5)-2)*18, 280,350)
        var x: float = float(180+index*180)
        pads.append({"index":index,"x":x,"y":float(y),"width":196.0,"height":18.0,"screen":int(x/SCREEN_WIDTH)})
    var edges: Array[Dictionary] = []
    for i in range(pads.size()-1):
        edges.append({"from":i,"to":i+1})
    return {"valid":true,"seed":seed,"screens":screens,"width":screens*SCREEN_WIDTH,"ground":flat,"pads":pads,"edges":edges,"spawn":Vector2(110,418),"exit":Vector2(screens*SCREEN_WIDTH-110,418),"generator":"r2-m01-lcg-v1"}
static func validate(route: Dictionary) -> Dictionary:
    if not route.get("valid",false): return {"passed":false,"errors":["route invalid"]}
    var errors: Array[String] = []
    var screens: int = route["screens"]
    var pads: Array = route["pads"]
    var ground: Array = route["ground"]
    var edges: Array = route["edges"]
    if screens < 4 or screens > 6: errors.append("bad screen count")
    if ground.size()!=screens: errors.append("ground section count")
    if pads.size()!=screens*5: errors.append("pad count")
    if edges.size()!=pads.size()-1: errors.append("edge count")
    for i in range(ground.size()-1):
        var a: Dictionary = ground[i]
        var b: Dictionary = ground[i+1]
        if a["x"]+a["width"]*0.5 < b["x"]-b["width"]*0.5: errors.append("ground gap")
    var visited: Dictionary = {0:true}
    for edge in edges:
        var a_id: int = edge["from"]
        var b_id: int = edge["to"]
        if a_id < 0 or b_id < 0 or a_id>=pads.size() or b_id>=pads.size():
            errors.append("edge out of bounds")
            continue
        var a: Dictionary = pads[a_id]
        var b: Dictionary = pads[b_id]
        var dx: float = b["x"]-a["x"]
        var dy: float = b["y"]-a["y"]
        if dx < MIN_STEP_X or dx > MAX_STEP_X: errors.append("bad step X")
        if dy < -MAX_STEP_RISE or dy > MAX_STEP_DROP: errors.append("bad step Y")
        if visited.has(a_id): visited[b_id]=true
    if visited.size()!=pads.size(): errors.append("route disconnected")
    if route["spawn"].x<0 or route["exit"].x>route["width"]: errors.append("invalid endpoints")
    return {"passed":errors.is_empty(),"errors":errors,"reachable_nodes":visited.size(),"route_nodes":pads.size(),"screens":screens}
