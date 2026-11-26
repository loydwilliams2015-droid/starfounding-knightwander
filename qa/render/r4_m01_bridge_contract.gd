extends RefCounted
## R4-M01 explicit world/controller integration gate. No blanket R2 approvals.
## This does not issue native certificates or place gameplay entities.
const S33_JUMP_SPEED := 410.0
const S33_GRAVITY := 1050.0
const GROUND_TOP_Y := 450.0
static func maximum_ideal_lift(jump_speed: float = S33_JUMP_SPEED, gravity: float = S33_GRAVITY) -> float:
    return jump_speed*jump_speed/(2.0*gravity) if jump_speed>0 and gravity>0 else 0.0
static func first_pad_clearance(route: Dictionary) -> float:
    if route.get("pads",[]).is_empty(): return INF
    var pad: Dictionary=route["pads"][0]
    return GROUND_TOP_Y-(float(pad["y"])-float(pad["height"])*0.5)
static func fail_closed(route: Dictionary) -> Dictionary:
    return {"blocked":true,"items":[],"events":[],
        "reason":"S33 knight has no complete native physics certificate for this R2 map",
        "first_pad_rise":first_pad_clearance(route),
        "ideal_jump_lift":maximum_ideal_lift(),
        "first_pad_statically_reachable":maximum_ideal_lift() >= first_pad_clearance(route),
        "controller":"s33-220-horizontal-410-jump-1050-gravity",
        "native_certificate":false}
