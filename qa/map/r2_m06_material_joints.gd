extends RefCounted
## R2-M06: material-specific joints are visual context, never physics.
const BASE = preload("res://qa/map/r2_m05_context_joints.gd")
const SCREEN_WIDTH := 960
const MATERIALS := ["stone","timber","relicwright","industrial"]
static func material_at(world_x: float) -> String:
    return MATERIALS[posmod(int(floor(world_x/float(SCREEN_WIDTH))),MATERIALS.size())]
static func classify(a: Dictionary,b: Dictionary,passable: bool,material: String) -> Dictionary:
    var structural: Dictionary = BASE.classify_link(a,b,passable)
    var result: Dictionary = structural.duplicate(true)
    result["material"]=material
    result["has_rotor"]=false
    result["midair_rotor"]=false
    result["decorative"]=true
    result["collision"]=false
    if not MATERIALS.has(material):
        result["kind"]="end_caps"
        result["material"]="unclassified"
    elif not passable or structural["kind"]=="disconnected":
        result["kind"]="end_caps"
    elif material=="stone":
        result["kind"]="stone_strata"
    elif material=="timber":
        result["kind"]="timber_lintel" if float(result["length"])<=164.0 and absf(float(result["rise"]))<=25.0 else "timber_brackets"
    elif material=="relicwright":
        result["kind"]="relic_cable"
    elif material=="industrial":
        result["kind"]="steel_hinge" if structural["kind"]=="hinged_brace" else "steel_cable"
        result["has_rotor"]=result["kind"]=="steel_hinge"
    return result
static func plan(route: Dictionary,assessment: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    var pads: Array=route.get("pads",[])
    for edge in assessment.get("edges",[]):
        var i: int=int(edge.get("from",-1))
        var j: int=int(edge.get("to",-1))
        if i<0 or j<0 or i>=pads.size() or j>=pads.size():
            continue
        var a: Dictionary=pads[i]
        var b: Dictionary=pads[j]
        var left_material: String=material_at(float(a["x"]))
        var right_material: String=material_at(float(b["x"]))
        var safe: bool=bool(edge.get("passable",false)) and left_material==right_material
        var joint: Dictionary=classify(a,b,safe,left_material)
        joint["from"]=i
        joint["to"]=j
        joint["transition"]=left_material!=right_material
        result.append(joint)
    return result
