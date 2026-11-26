extends "res://scripts/r4_m02_stage.gd"
## Additive Q/A overlay: verified trace never becomes production spawn authority.
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
const MARKERS=preload("res://scripts/r4_m03_markers.gd")
var chain_certificate:Dictionary={"valid":false}
var chain_preview:Dictionary={"blocked":true,"gameplay_items":[],"gameplay_events":[]}
var native_trace:Dictionary={}
var edge_markers:Node2D
func _ready()->void:
    super._ready()
    edge_markers=Node2D.new()
    edge_markers.set_script(MARKERS)
    edge_markers.name="R4M03NativeRouteEvidenceVisuals"
    edge_markers.position=Vector2(DISTRICT_START,0)
    edge_markers.z_index=3
    demo.add_child(edge_markers)
    edge_markers.configure(route)
    r4_info.text="R4-M03 / S33 native chain QA | SPAWNS LOCKED"
func apply_native_evidence(entrance:Dictionary,trace:Dictionary)->Dictionary:
    # This helper is called only after a Godot physics test reports all landings.
    # It emits QA preview symbols, never actual pickups or authored events.
    native_trace=trace.duplicate(true)
    chain_certificate=PROOF.issue(route,entrance,trace)
    chain_preview=PROOF.preview_symbols(route,entrance,trace,chain_certificate)
    var accepted:bool=bool(chain_certificate.get("valid",false))
    edge_markers.show_native_trace(trace,accepted,chain_preview)
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
    placement_gate["reason"]="R4-M03 native path proof is QA-only; no gameplay spawn authority"
    r4_info.text="R4-M03 / %s | %d/%d native links | gameplay spawns LOCKED"%[
        "QA PATH PASS" if accepted else "UNVERIFIED",
        int(trace.get("completed",0)),route.get("edges",[]).size()]
    return {"qa_certificate":chain_certificate,"preview":chain_preview,
        "gameplay_spawns_blocked":placement_gate["blocked"]}
func chain_snapshot()->Dictionary:
    return {"route_fingerprint":PROOF.fingerprint(route),
        "native_certificate":chain_certificate.duplicate(true),
        "preview":chain_preview.duplicate(true),
        "actual_gameplay_placement":placement_gate.duplicate(true),
        "spawn_authority":false,"controller_unchanged":true,
        "qa_markers":edge_markers.native_edge_marks.size()}
