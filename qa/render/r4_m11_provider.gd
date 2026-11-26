extends RefCounted
## R4-M11 single *recommended* QA persistence API. Clients do not need the
## legacy writer/ACK classes or R4-M10 coordinator. This is dependency hygiene,
## not an unforgeable security capability in Godot's shared scripting process.
const WRITER = preload("res://scripts/r4_m10_coordinator.gd")
const SCOPE := "standalone QA only"
var _writer: RefCounted
var _scene: Node2D
var _configured := false
var _namespace := ""
var _rejects := 0
var _observed_receipts: Dictionary = {}

func configure(name: String) -> Dictionary:
    if _configured or not name.is_valid_filename() or not name.begins_with("r4m11_"):
        return _deny("invalid or already configured QA namespace")
    _writer = WRITER.new()
    _namespace = name
    _writer.configure("r4m10_" + name)
    _configured = true
    return {"passed": true, "scope": SCOPE, "production_spawn_authority": false}

func attach(scene: Node2D) -> Dictionary:
    if not _configured or not is_instance_valid(scene) or not _safe_scene(scene):
        return _deny("unsafe scene binding")
    if _scene != null and is_instance_valid(_scene) and _scene != scene:
        return _deny("one live scene binding at a time")
    _scene = scene
    return {"passed": true, "production_spawn_authority": false}

func detach() -> void:
    _scene = null

func _safe_scene(scene: Node2D) -> bool:
    return scene.placement_gate.get("blocked", false) and \
        scene.placement_gate.get("items", []).is_empty() and \
        scene.placement_gate.get("events", []).is_empty()

func _ready_for_write() -> bool:
    return _configured and is_instance_valid(_scene) and _safe_scene(_scene) and _writer.owns()

func _deny(reason: String) -> Dictionary:
    _rejects += 1
    return {"passed": false, "reason": reason, "production_spawn_authority": false}

func acquire() -> Dictionary:
    if not _configured or not is_instance_valid(_scene) or not _safe_scene(_scene):
        return _deny("no safe bound scene")
    var r: Dictionary = _writer.acquire()
    r["production_spawn_authority"] = false
    return r

func release() -> bool:
    return _configured and _writer.release()

func owns() -> bool:
    return _configured and _writer.owns()

func save_landing(entrance: Dictionary, prefix: Array, fault: String = "none") -> Dictionary:
    if not _ready_for_write(): return _deny("single provider + writer lock required")
    if not ["none", "before_open", "partial_temp", "verified_temp"].has(fault):
        return _deny("unknown fault stage")
    var saved: Dictionary = _writer.guarded_commit(_scene, entrance, prefix, fault)
    saved["production_spawn_authority"] = false
    return saved

func deliver_committed(fault: String = "none") -> Dictionary:
    if not _ready_for_write(): return _deny("single provider + writer lock required")
    if not ["none", "before_open", "partial_temp", "verified_temp"].has(fault):
        return _deny("unknown acknowledgement stage")
    var result: Dictionary = _writer.guarded_deliver_and_ack(_scene, fault)
    result["production_spawn_authority"] = false
    # This duplicate-observation index is ephemeral and derived from the verified
    # outbox. It does NOT become a second authoritative gameplay ledger.
    if result.get("passed", false):
        var s: Dictionary = _writer.status(_scene.route)
        if s.get("valid", false) and s.get("pending", 1) == 0:
            _observed_receipts[str(s["generation"])] = true
    return result

func recover_bound_scene() -> Dictionary:
    if not _configured or not is_instance_valid(_scene) or not _safe_scene(_scene):
        return _deny("unsafe recovery binding")
    # Read-only recovery still requires native collision-floor confirmation.
    _writer.adapter.reset_for_new_scene()
    var r: Dictionary = await _writer.recover_scene(_scene)
    r["production_spawn_authority"] = false
    return r

func status() -> Dictionary:
    if not _configured or not is_instance_valid(_scene):
        return {"valid": false, "reason": "unbound", "production_spawn_authority": false}
    var row: Dictionary = _writer.status(_scene.route)
    row["production_spawn_authority"] = false
    return row

func snapshot() -> Dictionary:
    var row: Dictionary = status()
    row["provider"] = "R4-M11-single-QA-write-surface"
    row["bound"] = is_instance_valid(_scene)
    row["owns"] = owns()
    row["denials"] = _rejects
    row["observed_ack_generations"] = _observed_receipts.size()
    row["production_spawn_authority"] = false
    return row

func reset_test_only() -> Dictionary:
    if not _configured or owns() or not _namespace.begins_with("r4m11_test_"):
        return _deny("reset confined to unowned explicit QA test namespace")
    # Fail closed on stale locks. Operator must separately inspect the process
    # and explicitly clean a dead lock in an isolated test namespace.
    if DirAccess.dir_exists_absolute(_writer.outbox.lock_path()):
        return _deny("stale or live lock: manual verified cleanup required")
    _writer.reset_test_only()
    _observed_receipts.clear()
    return {"passed": true, "production_spawn_authority": false}

func request_real_item(_id: String) -> Dictionary:
    return _deny("no production gameplay item authority")

func request_real_event(_id: String) -> Dictionary:
    return _deny("no production gameplay event authority")
