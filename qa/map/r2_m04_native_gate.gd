extends RefCounted
## Native evidence must correspond to every link on this exact route.
## Fail closed: a proxy pass is not authorization to spawn gameplay entities.
static func fingerprint(route: Dictionary) -> String:
    var raw := "%s|%s|%s" % [str(route.get("seed",-1)),str(route.get("screens",-1)),str(route.get("pads",[]))]
    return raw.sha256_text()

static func certificate(route: Dictionary, results: Array[Dictionary]) -> Dictionary:
    var expected: int = route.get("edges",[]).size()
    var valid: bool = expected > 0 and results.size() == expected
    var failed: Array[int] = []
    var seen: Dictionary = {}
    for outcome in results:
        var index: int = int(outcome.get("edge",-1))
        if index < 0 or index >= expected or seen.has(index):
            valid = false
        seen[index] = true
        if not outcome.get("landed_target",false) or not outcome.get("origin_grounded",false):
            valid = false
            failed.append(index)
    if seen.size() != expected:
        valid = false
    return {"native_pass":valid, "route_fingerprint":fingerprint(route),"expected_edges":expected,
        "tested_edges":results.size(),"failed_edges":failed,"origin":"godot_physics_probe"}

static func certified_placements(route: Dictionary, proxy: Dictionary, certificate_data: Dictionary, proposed: Dictionary) -> Dictionary:
    var allowed: bool = proxy.get("passable",false) and certificate_data.get("native_pass",false)
    allowed = allowed and certificate_data.get("route_fingerprint","") == fingerprint(route)
    allowed = allowed and int(certificate_data.get("expected_edges",-1)) == route.get("edges",[]).size()
    allowed = allowed and int(certificate_data.get("tested_edges",-1)) == route.get("edges",[]).size()
    if not allowed:
        return {"items":[],"events":[],"blocked":true,"reason":"native chain certificate missing or invalid"}
    return {"items":proposed.get("items",[]),"events":proposed.get("events",[]),"blocked":false,"reason":"entire native chain passed"}
