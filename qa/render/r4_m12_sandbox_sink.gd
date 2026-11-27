extends RefCounted
## In-memory sink ONLY. It has no file writer, world event or gameplay inventory API.
## For any acknowledged v1 TX, a v2 projected view is reconstructed and deduped.
const MIGRATION = preload("res://scripts/r4_m12_migration.gd")
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
const SCOPE := "standalone QA only"
var delivered: Dictionary = {"generation": 0, "pad": -1, "ids": [], "star_fragments": 0}
var last_source_digest: String = ""
var delivery_count: int = 0
var denied_count: int = 0
var rolled_back_count: int = 0

func _deny(reason: String) -> Dictionary:
    denied_count += 1
    return {"passed": false, "reason": reason, "production_spawn_authority": false}

func reset_on_new_scene() -> void:
    delivered = {"generation": 0, "pad": -1, "ids": [], "star_fragments": 0}
    last_source_digest = ""
    delivery_count = 0
    denied_count = 0
    rolled_back_count = 0

func apply_acknowledged(route: Dictionary, source: Dictionary, ack: Dictionary, view: Dictionary,
        holder: bool, safe_scene: bool, fault: String = "none") -> Dictionary:
    if not ["none", "after_inventory", "after_events", "before_publish"].has(fault):
        return _deny("unknown fault")
    if not holder or not safe_scene:
        return _deny("single provider ownership and locked game world required")
    if not MIGRATION.validate(route, source, view).get("passed", false):
        return _deny("unverified versioned migration")
    if not ack.get("valid", false) or not ack.get("at_latest_generation", false):
        return _deny("latest transaction not acknowledged")
    var ackrecord: Variant = ack.get("record", null)
    if typeof(ackrecord) != TYPE_DICTIONARY:
        return _deny("malformed acknowledgement")
    if ackrecord.get("transaction_digest", "") != view["source_tx_digest"] or \
            int(ackrecord.get("generation", -1)) != int(view["generation"]) or \
            ackrecord.get("receipt_ids", []) != view["receipt_ids"]:
        return _deny("ack evidence differs from transaction")
    if not OUTBOX.audit_ack(route, source["record"], str(source["digest"]), ackrecord).get("passed", false):
        return _deny("outbox acknowledgement invalid")
    var generation: int = int(view["generation"])
    if generation < int(delivered["generation"]):
        return _deny("stale generation")
    if generation == int(delivered["generation"]):
        if view["source_tx_digest"] != last_source_digest:
            return _deny("same generation has changed digest")
        return {"passed": true, "idempotent": true, "generation": generation,
            "production_spawn_authority": false}
    if int(delivered["generation"]) > 0 and generation != int(delivered["generation"]) + 1:
        return _deny("generation gap")
    var old_ids: Array = delivered["ids"]
    var new_ids: Array = view["receipt_ids"]
    if int(delivered["generation"]) > 0:
        if new_ids.size() != old_ids.size() + 1:
            return _deny("non-monotonic receipt count")
        for index in range(old_ids.size()):
            if old_ids[index] != new_ids[index]:
                return _deny("prior receipt altered")
    var candidate: Dictionary = delivered.duplicate(true)
    candidate["star_fragments"] = int(view["star_fragments"])
    if fault == "after_inventory":
        rolled_back_count += 1
        return {"passed": false, "rolled_back": true, "stage": fault, "production_spawn_authority": false}
    candidate["ids"] = new_ids.duplicate(true)
    if fault == "after_events":
        rolled_back_count += 1
        return {"passed": false, "rolled_back": true, "stage": fault, "production_spawn_authority": false}
    candidate["generation"] = generation
    candidate["pad"] = int(view["pad"])
    if fault == "before_publish":
        rolled_back_count += 1
        return {"passed": false, "rolled_back": true, "stage": fault, "production_spawn_authority": false}
    delivered = candidate
    last_source_digest = str(view["source_tx_digest"])
    delivery_count += 1
    return {"passed": true, "idempotent": false, "generation": generation,
        "receipt_count": new_ids.size(), "production_spawn_authority": false}

func snapshot() -> Dictionary:
    return {"state": delivered.duplicate(true), "delivery_count": delivery_count,
        "denied_count": denied_count, "rolled_back_count": rolled_back_count,
        "source_digest": last_source_digest, "production_spawn_authority": false}

func request_gameplay_item(_id: String) -> Dictionary:
    return _deny("sandbox sink has no real gameplay item authority")
func request_gameplay_event(_id: String) -> Dictionary:
    return _deny("sandbox sink has no real gameplay event authority")
