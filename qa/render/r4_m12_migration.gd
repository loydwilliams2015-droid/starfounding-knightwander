extends RefCounted
## R4-M12 non-destructive v1 transaction -> v2 isolated preview migration.
## No production write authority; original R4-M06 transaction on disk is untouched.
const TX = preload("res://scripts/r4_m06_transaction.gd")
const PROOF = preload("res://scripts/r4_m03_certificate.gd")
const FORMAT := "R4M12/qa_event_view/2"
const SOURCE_VERSION := 1
const TARGET_VERSION := 2
const SCOPE := "standalone QA only"

static func migrate(route: Dictionary, disk: Dictionary) -> Dictionary:
    if not disk.get("valid", false) or typeof(disk.get("record", null)) != TYPE_DICTIONARY:
        return {"passed": false, "reason": "no verified v1 transaction"}
    var old: Dictionary = disk["record"]
    if old.get("version", -1) != SOURCE_VERSION or old.get("scope", "") != SCOPE:
        return {"passed": false, "reason": "unsupported or unsafe source version"}
    if old.get("authorizes_gameplay_spawns", true):
        return {"passed": false, "reason": "source requested gameplay authority"}
    if not TX.validate_record(route, old)["passed"]:
        return {"passed": false, "reason": "invalid underlying v1 transaction"}
    var digest: Variant = disk.get("digest", null)
    if typeof(digest) != TYPE_STRING or digest.length() != 64:
        return {"passed": false, "reason": "missing authoritative transaction digest"}
    var ids: Array[String] = []
    for receipt in old["receipts"]:
        ids.append(str(receipt["id"]))
    var view: Dictionary = {
        "format": FORMAT, "version": TARGET_VERSION,
        "source_format": "R4M06/tx/1", "source_version": SOURCE_VERSION,
        "source_tx_digest": digest, "route_fingerprint": PROOF.fingerprint(route),
        "controller_id": PROOF.CONTROLLER_ID, "generation": int(old["generation"]),
        "pad": int(old["checkpoint"]["pad_index"]), "receipt_ids": ids,
        "star_fragments": int(old["inventory"]["star_fragments"]),
        "event_outcomes": old["event_outcomes"].duplicate(true),
        "scope": SCOPE, "production_spawn_authority": false,
        "writes_to_original_save": false, "migration_kind": "derived_read_only"
    }
    view["view_digest"] = canonical_digest(view)
    return {"passed": true, "view": view, "scope": SCOPE, "production_spawn_authority": false}

static func canonical_digest(view: Dictionary) -> String:
    var data: Dictionary = view.duplicate(true)
    data.erase("view_digest")
    return JSON.stringify(data, "", true).sha256_text()

static func validate(route: Dictionary, disk: Dictionary, candidate: Dictionary) -> Dictionary:
    var faults: Array[String] = []
    var authoritative: Dictionary = migrate(route, disk)
    if not authoritative.get("passed", false):
        return {"passed": false, "errors": ["invalid or untrusted v1 source"]}
    var expected: Dictionary = authoritative["view"]
    if candidate.get("format", "") != FORMAT or candidate.get("version", -1) != TARGET_VERSION:
        faults.append("invalid v2 format")
    if candidate.get("production_spawn_authority", true): faults.append("spawn authority violation")
    if candidate.get("writes_to_original_save", true): faults.append("migration tried to write source")
    if candidate.get("view_digest", "") != canonical_digest(candidate): faults.append("view checksum")
    if candidate != expected: faults.append("not exact authoritative v1 projection")
    return {"passed": faults.is_empty(), "errors": faults, "production_spawn_authority": false}
