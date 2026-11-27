extends "res://scripts/r4_m11_provider.gd"
## New sole documented R4-M12 front door for QA transaction, ACK, migration and sink.
## Underlying M06/M08 writers remain included for backward-compatible tests.
const MIGRATION = preload("res://scripts/r4_m12_migration.gd")
const SINK = preload("res://scripts/r4_m12_sandbox_sink.gd")
var sandbox_sink: RefCounted = SINK.new()
var preview_rejects: int = 0

func configure(name: String) -> Dictionary:
    if not name.begins_with("r4m11_test_r4m12_"):
        return {"passed": false, "reason": "R4-M12 isolated namespace required", "production_spawn_authority": false}
    return super.configure(name)

func v2_preview() -> Dictionary:
    if not _configured or not is_instance_valid(_scene) or not _safe_scene(_scene):
        preview_rejects += 1
        return {"passed": false, "reason": "no safe scene", "production_spawn_authority": false}
    var source: Dictionary = _writer.tx.load_latest(_scene.route)
    return MIGRATION.migrate(_scene.route, source)

func deliver_sandbox(fault: String = "none") -> Dictionary:
    if not _ready_for_write():
        preview_rejects += 1
        return {"passed": false, "reason": "single provider writer lock required", "production_spawn_authority": false}
    var source: Dictionary = _writer.tx.load_latest(_scene.route)
    var migrated: Dictionary = MIGRATION.migrate(_scene.route, source)
    if not migrated.get("passed", false):
        preview_rejects += 1
        return migrated
    var status_row: Dictionary = _writer.status(_scene.route)
    if not status_row.get("valid", false) or int(status_row.get("pending", -1)) != 0:
        preview_rejects += 1
        return {"passed": false, "reason": "outbox pending or invalid", "production_spawn_authority": false}
    if _scene.qa_projection != _writer.tx.projection(source["record"]):
        preview_rejects += 1
        return {"passed": false, "reason": "checkpoint not restored to scene", "production_spawn_authority": false}
    var ack: Dictionary = _writer.outbox.load_latest(_writer.tx, _scene.route)
    var result: Dictionary = sandbox_sink.apply_acknowledged(_scene.route, source, ack, migrated["view"],
        owns(), _safe_scene(_scene), fault)
    if result.get("passed", false) and _scene.has_method("show_sandbox"):
        _scene.show_sandbox(sandbox_sink.snapshot())
    return result

func recover_bound_scene() -> Dictionary:
    var recovered: Dictionary = await super.recover_bound_scene()
    if recovered.get("passed", false):
        sandbox_sink.reset_on_new_scene()
    return recovered

func sink_snapshot() -> Dictionary:
    return sandbox_sink.snapshot()

func snapshot() -> Dictionary:
    var row: Dictionary = super.snapshot()
    row["provider"] = "R4-M12-versioned-QA-projection"
    row["sink"] = sink_snapshot()
    row["versioned_source"] = "R4M06/tx/1"
    row["versioned_view"] = MIGRATION.FORMAT
    row["preview_denials"] = preview_rejects
    row["production_spawn_authority"] = false
    return row
