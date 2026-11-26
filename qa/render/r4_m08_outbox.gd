extends RefCounted
## R4-M08 bounded QA outbox / acknowledgement layer.
## ACK means a *read-only QA view* was published. It is NOT a gameplay event,
## an external delivery guarantee, a signed receipt, or a power-fail durable save.
const TX = preload("res://scripts/r4_m06_transaction.gd")
const ADAPTER = preload("res://scripts/r4_m07_event_adapter.gd")
const PROOF = preload("res://scripts/r4_m03_certificate.gd")
const FORMAT := "R4M08/qa_ack/1"
const SCOPE := "standalone QA only"
const MAX_BYTES := 220000
var folder: String = ""
var lock_token: String = ""

func configure(name: String) -> void:
    assert(name.is_valid_filename() and name.begins_with("r4m08_"))
    folder = ProjectSettings.globalize_path("user://r4_m08/" + name)
    DirAccess.make_dir_recursive_absolute(folder)

func slot_path(generation: int) -> String:
    return folder + ("/ack_a.json" if generation % 2 == 1 else "/ack_b.json")

func temp_path(generation: int) -> String:
    return slot_path(generation) + ".tmp"

func lock_path() -> String:
    return folder + "/single_writer.lock"

func acquire_writer() -> Dictionary:
    if lock_token != "":
        return {"passed": false, "reason": "already owns a lock"}
    # Atomic directory creation serializes participating writers on the same FS.
    # A crashed holder leaves a stale directory; never steal it automatically.
    var err: int = DirAccess.make_dir_absolute(lock_path())
    if err != OK:
        return {"passed": false, "reason": "writer lock exists or mkdir failed", "error": err}
    lock_token = str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec())
    var f: FileAccess = FileAccess.open(lock_path() + "/owner.txt", FileAccess.WRITE)
    if f == null:
        lock_token = ""
        return {"passed": false, "reason": "cannot record lock owner; manual cleanup required"}
    f.store_string(lock_token + "\n")
    f.flush()
    f.close()
    return {"passed": true, "owner": lock_token}

func holds_writer() -> bool:
    return lock_token != "" and DirAccess.dir_exists_absolute(lock_path()) and \
        FileAccess.file_exists(lock_path() + "/owner.txt") and \
        FileAccess.get_file_as_string(lock_path() + "/owner.txt").strip_edges() == lock_token

func release_writer() -> bool:
    if not holds_writer():
        return false
    var owner_path: String = lock_path() + "/owner.txt"
    if DirAccess.remove_absolute(owner_path) != OK:
        return false
    if DirAccess.remove_absolute(lock_path()) != OK:
        return false
    lock_token = ""
    return true

func reset_test_only() -> void:
    # Explicit test-only namespace. Not a production lock-recovery API.
    assert(folder.contains("/r4_m08/r4m08_"))
    assert(not DirAccess.dir_exists_absolute(lock_path()))
    for f in [slot_path(1),slot_path(2),temp_path(1),temp_path(2)]:
        if FileAccess.file_exists(f):
            DirAccess.remove_absolute(f)

static func committed_ids(record: Dictionary) -> Array[String]:
    var ids: Array[String] = []
    for receipt in record.get("receipts", []):
        ids.append(str(receipt["id"]))
    return ids

static func audit_ack(route: Dictionary, txrecord: Dictionary, digest: String, ack: Dictionary) -> Dictionary:
    var errors: Array[String] = []
    if int(ack.get("version", -1)) != 1: errors.append("version")
    if ack.get("scope", "") != SCOPE: errors.append("scope")
    if ack.get("gameplay_spawn_authority", true): errors.append("spawn authority")
    if ack.get("route_fingerprint", "") != PROOF.fingerprint(route): errors.append("route")
    if ack.get("controller_id", "") != PROOF.CONTROLLER_ID: errors.append("controller")
    if ack.get("transaction_digest", "") != digest: errors.append("transaction digest")
    if int(ack.get("generation", -1)) != int(txrecord.get("generation", -2)):
        errors.append("generation")
    if int(ack.get("pad_index", -1)) != int(txrecord.get("checkpoint", {}).get("pad_index", -2)):
        errors.append("checkpoint pad")
    if int(ack.get("generation", -1)) < 1: errors.append("zero generation")
    var ids: Variant = ack.get("receipt_ids", null)
    if typeof(ids) != TYPE_ARRAY:
        errors.append("receipt list missing")
    elif ids != committed_ids(txrecord):
        errors.append("receipt set, order or duplicates")
    if int(ack.get("generation", 0)) == 1 and ack.get("previous_ack_digest", "missing") != "":
        errors.append("genesis predecessor")
    if int(ack.get("generation", 0)) > 1 and str(ack.get("previous_ack_digest", "")).length() != 64:
        errors.append("non-genesis predecessor")
    return {"passed": errors.is_empty(), "errors": errors}

static func pack_envelope(record: Dictionary) -> Dictionary:
    var encoded: String = Marshalls.raw_to_base64(var_to_bytes(record))
    return {"format": FORMAT, "data": encoded, "sha256": encoded.sha256_text()}

static func unwrap(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY or value.get("format", "") != FORMAT:
        return {"valid": false, "reason": "envelope format"}
    var encoded: Variant = value.get("data", null)
    if typeof(encoded) != TYPE_STRING or encoded.length() < 10 or encoded.length() > MAX_BYTES:
        return {"valid": false, "reason": "envelope length"}
    if encoded.sha256_text() != value.get("sha256", ""):
        return {"valid": false, "reason": "envelope checksum"}
    var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
    if raw.is_empty() or raw.size() > MAX_BYTES:
        return {"valid": false, "reason": "decoded length"}
    var record: Variant = bytes_to_var(raw)
    if typeof(record) != TYPE_DICTIONARY:
        return {"valid": false, "reason": "variant type"}
    return {"valid": true, "record": record, "digest": value["sha256"]}

func read_path(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {"valid": false, "reason": "missing"}
    var f: FileAccess = FileAccess.open(path, FileAccess.READ)
    if f == null: return {"valid": false, "reason": "read error"}
    if f.get_length() > MAX_BYTES:
        f.close()
        return {"valid": false, "reason": "oversize"}
    var content: String = f.get_as_text()
    f.close()
    return unwrap(JSON.parse_string(content))

func read_slot(slot: int) -> Dictionary:
    var row: Dictionary = read_path(slot_path(slot))
    if not row.get("valid", false): return row
    var g: int = int(row["record"].get("generation", -1))
    if g < 1 or posmod(g, 2) != posmod(slot, 2):
        return {"valid": false, "reason": "generation / slot parity"}
    return row

func load_latest(tx: RefCounted, route: Dictionary) -> Dictionary:
    var txstate: Dictionary = tx.load_latest(route)
    if not txstate.get("valid", false):
        return {"valid": false, "reason": "source transaction invalid"}
    var rows: Array[Dictionary] = []
    for slot in [1, 2]:
        var row: Dictionary = read_slot(slot)
        if row.get("valid", false): rows.append(row)
    if rows.is_empty(): return {"valid": false, "reason": "no acknowledgement"}
    rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return int(a["record"]["generation"]) < int(b["record"]["generation"]))
    if rows.size() == 1 and int(rows[0]["record"]["generation"]) != 1:
        return {"valid": false, "reason": "orphaned acknowledgement"}
    var selected: Dictionary = rows[-1]
    if rows.size() == 2:
        var previous: Dictionary = rows[0]
        if int(selected["record"]["generation"]) != int(previous["record"]["generation"]) + 1 or \
            selected["record"].get("previous_ack_digest", "") != previous["digest"]:
            return {"valid": false, "reason": "acknowledgement chain broken"}
        var prev_ids: Array = previous["record"].get("receipt_ids", [])
        var new_ids: Array = selected["record"].get("receipt_ids", [])
        if new_ids.size() != prev_ids.size() + 1:
            return {"valid": false, "reason": "acknowledgement progression invalid"}
        for i in range(prev_ids.size()):
            if prev_ids[i] != new_ids[i]:
                return {"valid": false, "reason": "acknowledgement prefix mismatch"}
    # An ACK for an older TX is accepted only as a pending baseline, not as a
    # complete acknowledgement of the *newest* committed generation.
    var record: Dictionary = selected["record"]
    var txrec: Dictionary = txstate["record"]
    if int(record.get("generation", -1)) > int(txrec["generation"]):
        return {"valid": false, "reason": "future acknowledgement"}
    if int(record.get("generation", -1)) == int(txrec["generation"]):
        if not audit_ack(route, txrec, str(txstate["digest"]), record)["passed"]:
            return {"valid": false, "reason": "ack record does not match current transaction"}
    elif int(record.get("generation", -1)) != int(txrec["generation"]) - 1 or \
        txrec.get("previous_digest", "") != record.get("transaction_digest", ""):
        return {"valid": false, "reason": "stale ACK not predecessor of TX"}
    return {"valid": true, "record": record, "digest": selected["digest"],
        "at_latest_generation": int(record["generation"]) == int(txrec["generation"]),
        "spawn_authority": false}

func pending(tx: RefCounted, route: Dictionary) -> Dictionary:
    var committed: Dictionary = tx.load_latest(route)
    if not committed.get("valid", false): return {"passed": false, "reason": "source invalid"}
    var ids: Array[String] = committed_ids(committed["record"])
    var ack: Dictionary = load_latest(tx, route)
    if not ack.get("valid", false):
        if FileAccess.file_exists(slot_path(1)) or FileAccess.file_exists(slot_path(2)):
            return {"passed": false, "reason": "invalid ACK journal"}
        return {"passed": true, "ids": ids, "generation": committed["record"]["generation"], "acked": 0}
    var before: Array = ack["record"]["receipt_ids"]
    if before.size() > ids.size(): return {"passed": false, "reason": "future receipts"}
    for i in range(before.size()):
        if ids[i] != before[i]: return {"passed": false, "reason": "receipt drift"}
    return {"passed": true, "ids": ids.slice(before.size()), "generation": committed["record"]["generation"], "acked": before.size()}

func acknowledge(stage: Node2D, tx: RefCounted, adapter: RefCounted, fault: String = "none") -> Dictionary:
    if not ["none", "before_write", "partial_temp", "verified_temp"].has(fault):
        return {"passed": false, "reason": "unknown fault"}
    if not holds_writer(): return {"passed": false, "reason": "writer lock required"}
    if not stage.placement_gate.get("blocked", false) or \
        not stage.placement_gate.get("items", []).is_empty() or \
        not stage.placement_gate.get("events", []).is_empty():
        return {"passed": false, "reason": "gameplay gate not locked"}
    var committed: Dictionary = tx.load_latest(stage.route)
    if not committed.get("valid", false): return {"passed": false, "reason": "transaction unverified"}
    var record: Dictionary = committed["record"]
    var expected: Dictionary = TX.projection(record)
    if stage.qa_projection != expected:
        return {"passed": false, "reason": "checkpoint not restored"}
    var adapter_state: Dictionary = adapter.snapshot()
    var delivered: Dictionary = ADAPTER.from_record(record)
    if not delivered.get("passed", false): return {"passed": false, "reason": "bad QA receipts"}
    if adapter_state["projection"] != delivered["value"] or \
        stage.event_projection != delivered["value"] or \
        adapter_state["digest"] != committed["digest"]:
        return {"passed": false, "reason": "read-only adapter has not published this TX"}
    var prior: Dictionary = load_latest(tx, stage.route)
    if prior.get("valid", false) and prior.get("at_latest_generation", false):
        return {"passed": true, "idempotent": true, "generation": record["generation"], "spawn_authority": false}
    var has_slot: bool = FileAccess.file_exists(slot_path(1)) or FileAccess.file_exists(slot_path(2))
    if has_slot and not prior.get("valid", false):
        return {"passed": false, "reason": "cannot overwrite invalid ack history"}
    if prior.get("valid", false) and int(record["generation"]) != int(prior["record"]["generation"]) + 1:
        return {"passed": false, "reason": "ack generation skipped"}
    if not prior.get("valid", false) and int(record["generation"]) != 1:
        return {"passed": false, "reason": "missing genesis acknowledgement"}
    var ack: Dictionary = {"version": 1, "scope": SCOPE,
        "route_fingerprint": PROOF.fingerprint(stage.route), "controller_id": PROOF.CONTROLLER_ID,
        "transaction_digest": committed["digest"], "generation": record["generation"],
        "pad_index": record["checkpoint"]["pad_index"],
        "receipt_ids": committed_ids(record),
        "previous_ack_digest": str(prior.get("digest", "")), "gameplay_spawn_authority": false}
    if not audit_ack(stage.route, record, str(committed["digest"]), ack)["passed"]:
        return {"passed": false, "reason": "prepared acknowledgement invalid"}
    if fault == "before_write": return {"passed": false, "interrupted": true, "stage": fault}
    var path: String = temp_path(int(record["generation"]))
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null: return {"passed": false, "reason": "temp open failed"}
    if fault == "partial_temp":
        file.store_string('{"format":"R4M08/qa_ack/1","data":"')
    else:
        file.store_string(JSON.stringify(pack_envelope(ack)) + "\n")
    file.flush()
    file.close()
    if fault != "none": return {"passed": false, "interrupted": true, "stage": fault}
    if not read_path(path).get("valid", false): return {"passed": false, "reason": "temp invalid"}
    if DirAccess.rename_absolute(path, slot_path(int(record["generation"]))) != OK:
        return {"passed": false, "reason": "rename failed"}
    var after: Dictionary = load_latest(tx, stage.route)
    if not after.get("valid", false) or not after.get("at_latest_generation", false):
        return {"passed": false, "reason": "post-rename failed"}
    return {"passed": true, "idempotent": false, "generation": record["generation"],
        "acknowledged_ids": ack["receipt_ids"].size(), "spawn_authority": false}
