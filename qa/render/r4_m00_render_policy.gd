extends RefCounted
## R4-M00 formal rendering motif policy. Visual-only: never authorizes collision or spawns.
const BIOMES := ["stone", "timber", "relicwright", "industrial"]
const LIGHT_MODES := ["diffuse", "beacon"]
const COLORS := {
    "stone": Color("b6ced4"),
    "timber": Color("f4c28a"),
    "relicwright": Color("71dbd2"),
    "industrial": Color("b2cee8")
}
const BACKGROUNDS := {
    "stone": Color("b7c7c8"),
    "timber": Color("e1c6a3"),
    "relicwright": Color("9ed7d2"),
    "industrial": Color("b7c3ce")
}
const MAX_KEY_ENERGY := 0.95
const MIN_KEY_ENERGY := 0.18
const MAX_FILL_ENERGY := 0.62
static func resolve(biome: String, lighting: String) -> Dictionary:
    if not BIOMES.has(biome) or not LIGHT_MODES.has(lighting):
        return {"valid":false,"collision_added":false,"spawn_authority":false}
    var beacon: bool = lighting == "beacon"
    var key_energy: float = 0.93 if beacon else 0.23
    var fill_energy: float = 0.57 if beacon else 0.13
    return {"valid":true,"biome":biome,"lighting":lighting,
        "key_color":COLORS[biome],"fill_color":COLORS[biome].lerp(Color.WHITE,0.34),
        "key_energy":key_energy,"fill_energy":fill_energy,
        "background_color":BACKGROUNDS[biome],
        "light_count":2,"max_light_energy":MAX_KEY_ENERGY,
        "actor_tint":Color.WHITE,"lighting_animation":false,
        "collision_added":false,"spawn_authority":false,
        "reduced_motion_compatible":true}
static func validate(p: Dictionary) -> bool:
    if not p.get("valid",false): return false
    if p.get("collision_added",true) or p.get("spawn_authority",true): return false
    if not p.get("actor_tint",Color.BLACK).is_equal_approx(Color.WHITE): return false
    return p["key_energy"]>=MIN_KEY_ENERGY and p["key_energy"]<=MAX_KEY_ENERGY \
        and p["fill_energy"]>=0.10 and p["fill_energy"]<=MAX_FILL_ENERGY \
        and p.get("light_count",-1)==2
