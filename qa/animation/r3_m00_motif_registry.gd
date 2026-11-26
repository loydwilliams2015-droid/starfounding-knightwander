extends RefCounted
## R2 closeout -> R3 handoff. Motifs describe semantic art cues, NOT physics or gameplay authority.
const BIOMES := ["stone", "timber", "relicwright", "industrial"]
const TYPES := ["threshold", "joint", "damage", "wayfinding", "character_echo", "transition"]
const PALETTES := {
    "stone": ["#415e66", "#8bb1a7", "#d5dcc5"],
    "timber": ["#5b453f", "#b88c59", "#e5c39a"],
    "relicwright": ["#344d5f", "#58b5b4", "#e8dbc2"],
    "industrial": ["#394753", "#9babb2", "#e2a66b"]
}
static func motif(biome: String, kind: String) -> Dictionary:
    if not BIOMES.has(biome) or not TYPES.has(kind):
        return {"valid": false, "collision_added": false, "spawn_authority": false}
    var motion: String = "none"
    if kind == "joint":
        motion = "pendulum" if biome == "relicwright" else "hinge" if biome == "industrial" else "none"
    elif kind == "character_echo":
        motion = "one-pose-hold"
    elif kind == "threshold":
        motion = "subtle-pulse" if biome == "relicwright" else "none"
    var glyph: String = ""
    match kind:
        "threshold": glyph = "portal / rim"
        "joint": glyph = "anchored connection"
        "damage": glyph = "scuff / fracture only"
        "wayfinding": glyph = "directional notch"
        "character_echo": glyph = "held key-pose accent"
        "transition": glyph = "material seam / end cap"
    return {"valid":true,"biome":biome,"kind":kind,"glyph":glyph,
        "palette":PALETTES[biome],"motion":motion,"collision_added":false,
        "spawn_authority":false,"passability_authority":false,
        "physics_claim":false,"r3_anchor":"foot-bottom-center",
        "reference":"profile-a" if kind == "character_echo" else "terrain-authored"}
static func plan_route(route: Dictionary, surface_plan: Array) -> Dictionary:
    var out: Array[Dictionary] = []
    if surface_plan.size() != route.get("pads",[]).size():
        return {"valid":false,"motifs":out,"errors":["source count mismatch"]}
    for i in range(surface_plan.size()):
        var s: Dictionary = surface_plan[i]
        var kind: String = TYPES[posmod(i + int(route.get("seed",0)), TYPES.size())]
        var m: Dictionary = motif(str(s.get("biome","")),kind)
        if not m.get("valid",false):
            return {"valid":false,"motifs":[],"errors":["unknown material"]}
        m["pad_index"] = i
        m["surface_top_y"] = s["top_y"]
        m["safe_to_spawn"] = false
        out.append(m)
    return {"valid":true,"motifs":out,"errors":[]}
