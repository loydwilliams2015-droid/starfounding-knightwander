extends RefCounted
## Exact-route, controller-specific QA evidence only. SHA-256 detects accidental
## alteration/replay, it is NOT a signed attestation or a gameplay spawn permission.
const NATIVE_GATE=preload("res://scripts/r2_native_gate.gd")
const CONTROLLER_ID := "s33-410jump-1050gravity-220walk"
const TOP_TOLERANCE := 2.5
const END_INSET := 16.0
static func fingerprint(route: Dictionary) -> String:
    return NATIVE_GATE.fingerprint(route)
static func audit_trace(route: Dictionary, entrance: Dictionary, trace: Dictionary) -> Dictionary:
    var faults: Array[String]=[]
    var edges: Array=route.get("edges",[])
    var pads: Array=route.get("pads",[])
    var results: Array=trace.get("edges",[])
    if pads.is_empty() or edges.size()!=pads.size()-1:
        faults.append("route topology invalid")
    if not entrance.get("passed",false) or not entrance.get("last_grounded",false):
        faults.append("native ground-to-first-pad entrance not passed")
    if results.size()!=edges.size():faults.append("edge evidence count mismatch")
    if not trace.get("passed",false) or int(trace.get("completed",-1))!=edges.size():
        faults.append("native full chain incomplete")
    if not trace.get("content_blocked",false):faults.append("gameplay content must remain locked")
    if str(trace.get("controller",""))!="S33 -410 impulse / 1050 gravity / 220 walk":
        faults.append("wrong controller evidence")
    if pads.size()>0 and entrance.has("last_position"):
        var p0:Dictionary=pads[0]
        if absf(float(entrance["last_position"].y)-(float(p0["y"])-float(p0["height"])*0.5))>TOP_TOLERANCE:
            faults.append("entrance landing not on first route pad")
    for i in range(results.size()):
        var proof:Dictionary=results[i]
        if i>=edges.size():
            faults.append("extra native edge")
            continue
        var path:Dictionary=edges[i]
        var fr:int=int(path["from"])
        var to:int=int(path["to"])
        if int(proof.get("from",-1))!=fr or int(proof.get("to",-1))!=to:
            faults.append("edge identifier or order mismatch %d"%i)
            continue
        if fr<0 or to<0 or fr>=pads.size() or to>=pads.size():
            faults.append("out-of-range route index %d"%i)
            continue
        var src:Dictionary=pads[fr]
        var dst:Dictionary=pads[to]
        if not proof.get("passable",false) or not proof.get("airborne",false):
            faults.append("no native flight/landing %d"%i)
        if proof.get("reason","")!="native target-pad landing":
            faults.append("not an observed destination landing %d"%i)
        if not proof.has("launch") or not proof.has("landing") or not proof.has("actual_end"):
            faults.append("missing physical positions %d"%i)
            continue
        var launch:Vector2=proof["launch"]
        var landing:Vector2=proof["landing"]
        var end:Vector2=proof["actual_end"]
        var sx:float=float(src["x"])+4000.0
        var dx:float=float(dst["x"])+4000.0
        var s_top:float=float(src["y"])-float(src["height"])*0.5
        var d_top:float=float(dst["y"])-float(dst["height"])*0.5
        if absf(launch.y-s_top)>TOP_TOLERANCE or absf(launch.x-sx)>float(src["width"])*0.5-END_INSET:
            faults.append("launch not on source pad %d"%i)
        if absf(landing.y-d_top)>TOP_TOLERANCE or absf(landing.x-dx)>float(dst["width"])*0.5-END_INSET:
            faults.append("landing not within target pad %d"%i)
        if landing.distance_to(end)>0.01:faults.append("native end disagrees with landing %d"%i)
        if int(proof.get("ticks",-1))<1 or int(proof.get("ticks",-1))>155:
            faults.append("edge time outside bounded test %d"%i)
        if i>0 and not results[i-1].get("passable",false):
            faults.append("broken continuity %d"%i)
    return {"passed":faults.is_empty(),"errors":faults,"observed_edges":results.size(),
        "required_edges":edges.size(),"controller_id":CONTROLLER_ID,
        "route_fingerprint":fingerprint(route)}
static func issue(route: Dictionary, entrance: Dictionary, trace: Dictionary) -> Dictionary:
    var audit:Dictionary=audit_trace(route,entrance,trace)
    if not audit["passed"]:
        return {"valid":false,"errors":audit["errors"],"authorizes_gameplay_spawns":false}
    var physical_hash:String=str(trace["edges"]).sha256_text()
    return {"valid":true,"route_fingerprint":fingerprint(route),
        "controller_id":CONTROLLER_ID,"edge_count":trace["edges"].size(),
        "trace_hash":physical_hash,"evidence":"in-process Godot physics / S33 controller",
        "authorizes_gameplay_spawns":false,"scope":"standalone QA only",
        "all_native_pad_landings":true}
static func verify(route: Dictionary, entrance: Dictionary, trace: Dictionary, certificate: Dictionary) -> Dictionary:
    var faults: Array[String]=audit_trace(route,entrance,trace)["errors"].duplicate()
    if not certificate.get("valid",false):faults.append("certificate invalid")
    if certificate.get("route_fingerprint","")!=fingerprint(route):faults.append("route fingerprint mismatch")
    if certificate.get("controller_id","")!=CONTROLLER_ID:faults.append("controller identity mismatch")
    if int(certificate.get("edge_count",-1))!=route.get("edges",[]).size():faults.append("edge count mismatch")
    if certificate.get("trace_hash","")!=str(trace.get("edges",[])).sha256_text():
        faults.append("native trace changed since certificate issue")
    if certificate.get("authorizes_gameplay_spawns",true):faults.append("unauthorized gameplay spawn flag")
    if certificate.get("scope","")!="standalone QA only":faults.append("scope changed")
    return {"passed":faults.is_empty(),"errors":faults,"route_fingerprint":fingerprint(route),
        "controller_id":CONTROLLER_ID,"authorizes_gameplay_spawns":false}
static func preview_symbols(route: Dictionary, entrance: Dictionary, trace: Dictionary, certificate: Dictionary) -> Dictionary:
    var verification:Dictionary=verify(route,entrance,trace,certificate)
    var stars: Array[Dictionary]=[]
    var events: Array[Dictionary]=[]
    if verification["passed"]:
        for i in range(route["pads"].size()):
            var pad:Dictionary=route["pads"][i]
            if i%3==2:
                stars.append({"index":i,"world":Vector2(float(pad["x"])+4000.0,float(pad["y"])-45.0)})
            if i%5==4:
                events.append({"index":i,"world":Vector2(float(pad["x"])+4000.0,float(pad["y"])-53.0)})
    return {"preview_only":true,"stars":stars,"events":events,
        "blocked":true,"gameplay_items":[],"gameplay_events":[],"certificate_passed":verification["passed"]}
