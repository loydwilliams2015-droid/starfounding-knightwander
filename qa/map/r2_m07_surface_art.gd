extends RefCounted
## R2-M07 material platform silhouettes: rendering only, never new physics.
const MATERIAL = preload("res://qa/map/r2_m06_material_joints.gd")
const KINDS := ["rock_shelf","timber_deck","relic_castle","steel_grating"]
static func describe(pad: Dictionary, index: int, link_ok: bool = true) -> Dictionary:
    var biome: String = MATERIAL.material_at(float(pad["x"]))
    var kind := "rock_shelf"
    match biome:
        "stone": kind = "rock_shelf"
        "timber": kind = "timber_deck"
        "relicwright": kind = "relic_castle"
        "industrial": kind = "steel_grating"
    var weathered: bool = posmod(index * 17 + int(floor(float(pad["x"]) / 31.0)), 7) < 3
    return {"index":index,"biome":biome,"kind":kind,
        "top_y":float(pad["y"])-float(pad["height"])*0.5,
        "left_x":float(pad["x"])-float(pad["width"])*0.5,
        "right_x":float(pad["x"])+float(pad["width"])*0.5,
        "weathered":weathered,"solid_surface":true,"link_ok":link_ok,
        "decorative":true,"collision_added":false,"spawn_authority":false,
        "passability_authority":false}
static func build(route: Dictionary, chain: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    var edge_ok: Dictionary={}
    for edge in chain.get("edges",[]):
        edge_ok[int(edge.get("from",-1))]=bool(edge.get("passable",false))
    for i in range(route.get("pads",[]).size()):
        result.append(describe(route["pads"][i],i,edge_ok.get(i,true)))
    return result
static func safe_visual_plan(route: Dictionary, chain: Dictionary) -> Dictionary:
    var art: Array[Dictionary]=build(route,chain)
    var errors: Array[String]=[]
    if art.size()!=route.get("pads",[]).size(): errors.append("cardinality mismatch")
    for i in range(art.size()):
        if not KINDS.has(art[i]["kind"]): errors.append("unknown style")
        if not is_equal_approx(float(art[i]["top_y"]),float(route["pads"][i]["y"])-9.0): errors.append("walkable top mismatch")
        if art[i]["collision_added"] or art[i]["spawn_authority"]: errors.append("visual authority violation")
    return {"valid":errors.is_empty(),"errors":errors,"art":art}
