extends RefCounted
## R2-M05 contextual articulation: attachment points must belong to actual pads.
## All classes are visual only. They never create a collision bridge.
const BRACE_MAX_GAP := 164.0
const BRACE_MAX_RISE := 25.0
const CABLE_MAX_GAP := 205.0
const CABLE_MAX_RISE := 85.0

static func classify_link(a: Dictionary, b: Dictionary, passable: bool) -> Dictionary:
    var p: Vector2 = Vector2(float(a["x"]),float(a["y"])+12.0)
    var q: Vector2 = Vector2(float(b["x"]),float(b["y"])+12.0)
    var dx: float = absf(q.x-p.x)
    var dy: float = absf(q.y-p.y)
    var kind := "disconnected"
    if passable:
        if dx <= BRACE_MAX_GAP and dy <= BRACE_MAX_RISE:
            kind = "hinged_brace"
        elif dx <= CABLE_MAX_GAP and dy <= CABLE_MAX_RISE:
            kind = "suspended_cable"
    return {"kind":kind,"a":p,"b":q,"length":dx,"rise":dy,
        "decorative":true,"collision":false,
        "has_rotor":kind=="hinged_brace","midair_rotor":false,
        "mechanical_implication":"anchored bracket" if kind=="hinged_brace" else "hanging cable" if kind=="suspended_cable" else "unconnected end caps"}

static func plan(route: Dictionary, assessment: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var pads: Array = route.get("pads",[])
    for edge in assessment.get("edges",[]):
        var i: int = int(edge.get("from",-1))
        var j: int = int(edge.get("to",-1))
        if i < 0 or j < 0 or i>=pads.size() or j>=pads.size():
            continue
        var description: Dictionary = classify_link(pads[i],pads[j],edge.get("passable",false))
        description["from"] = i
        description["to"] = j
        result.append(description)
    return result
