extends RefCounted
## R2-M03: deterministic jump-envelope proxy; NOT exhaustive native physics proof.
const SPEED := 230.0
const JUMP := -600.0
const GRAVITY := 1100.0
const DT := 1.0 / 60.0
const BODY_RADIUS := 13.0
const MAX_TICKS := 90

static func ballistic_transition(a: Dictionary, b: Dictionary) -> Dictionary:
    var start_y: float = float(a["y"]) - 9.0
    var goal_y: float = float(b["y"]) - 9.0
    var x0: float = float(a["x"])
    var x1: float = float(b["x"])
    var left: float = x1 - float(b["width"]) * 0.5 + BODY_RADIUS
    var right: float = x1 + float(b["width"]) * 0.5 - BODY_RADIUS
    # Favor interior aim: earlier left-edge solutions hit nearby raised pads.
    for move_ticks in range(40, MAX_TICKS + 1):
        var x: float = x0
        var y: float = start_y
        var vy: float = JUMP
        for tick in range(MAX_TICKS):
            var old_y: float = y
            if tick < move_ticks:
                x += SPEED * DT
            vy += GRAVITY * DT
            y += vy * DT
            if vy > 0.0 and old_y <= goal_y and y >= goal_y:
                if x >= left and x <= right and x > x0 + BODY_RADIUS * 2.0:
                    return {"passable":true,"move_ticks":move_ticks,"flight_ticks":tick+1,"land_x":x,"land_y":goal_y,"method":"bounded_ballistic_proxy_v1"}
                break
    return {"passable":false,"move_ticks":-1,"flight_ticks":-1,"method":"bounded_ballistic_proxy_v1"}

static func classify(route: Dictionary, geometric_validation: Dictionary) -> Dictionary:
    var pads: Array = route.get("pads",[])
    var edges: Array = route.get("edges",[])
    var statuses: Array[Dictionary] = []
    var reached: Dictionary = {0:true}
    var allowed: bool = geometric_validation.get("passed",false) and not pads.is_empty()
    var errors: Array[String] = []
    for edge in edges:
        var source: int = int(edge["from"])
        var target: int = int(edge["to"])
        var status: Dictionary = {"from":source,"to":target,"passable":false}
        if source>=0 and target>=0 and source<pads.size() and target<pads.size():
            status=ballistic_transition(pads[source],pads[target])
            status["from"]=source
            status["to"]=target
            if status["passable"] and reached.has(source):
                reached[target]=true
        if not status["passable"]:
            allowed=false
            errors.append("blocked link %d->%d"%[source,target])
        statuses.append(status)
    if reached.size()!=pads.size():
        allowed=false
        errors.append("disconnected route")
    return {"passable":allowed,"spawn_allowed":allowed,"edges":statuses,
            "reachable":reached,"errors":errors,"physics_certified":false}

static func safe_placements(route: Dictionary, assessment: Dictionary) -> Dictionary:
    var items: Array[Dictionary] = []
    var events: Array[Dictionary] = []
    # FAIL CLOSED: even one rejected link suppresses all chain spawns.
    if not assessment.get("passable",false) or not assessment.get("spawn_allowed",false):
        return {"items":items,"events":events,"blocked":true}
    for index in range(route["pads"].size()):
        if not assessment["reachable"].has(index):
            continue
        var pad: Dictionary = route["pads"][index]
        if index%3==2:
            items.append({"kind":"star","platform":index,"position":Vector2(pad["x"],pad["y"]-35.0)})
        if index%5==4:
            events.append({"kind":"event","platform":index,"position":Vector2(pad["x"],pad["y"]-38.0)})
    return {"items":items,"events":events,"blocked":false}
