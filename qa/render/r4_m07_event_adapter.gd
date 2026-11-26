extends RefCounted
## R4-M07 local committed QA record -> idempotent read-only event projection.
## Compensates in-memory staging faults; does NOT roll back external effects.
const TX=preload("res://scripts/r4_m06_transaction.gd")
const MAX_RECEIPTS := 128
const QA_SCOPE := "standalone QA only"
var current:Dictionary={"pad":-1,"generation":0,"fragments":0,"event_ids":[],"status":"NOT_APPLIED"}
var committed_digest:String=""
var observed_apply_count:int=0
var compensated_faults:int=0

func reset_for_new_scene()->void:
    current={"pad":-1,"generation":0,"fragments":0,"event_ids":[],"status":"NOT_APPLIED"}
    committed_digest=""
    observed_apply_count=0
    compensated_faults=0

func snapshot()->Dictionary:
    return {"projection":current.duplicate(true),"digest":committed_digest,
        "apply_count":observed_apply_count,"compensated_faults":compensated_faults,
        "real_spawn_authority":false}

static func from_record(record:Dictionary)->Dictionary:
    # Never treat the receipt's 'qa_only' annotation as a gameplay command.
    var receipts:Array=record.get("receipts",[])
    var ids:Array[String]=[]
    var balance:int=0
    if receipts.size()>MAX_RECEIPTS:
        return {"passed":false,"reason":"too many receipts"}
    var seen:Dictionary={}
    for rc in receipts:
        if typeof(rc)!=TYPE_DICTIONARY or rc.get("qa_only",false)!=true:
            return {"passed":false,"reason":"not a QA receipt"}
        var id:String=str(rc.get("id",""))
        if seen.has(id) or rc.get("outcome","")!="inspected" or int(rc.get("delta",0))!=1:
            return {"passed":false,"reason":"replay or unapproved effect"}
        if id!=TX.receipt_id(int(rc.get("pad",-1))):
            return {"passed":false,"reason":"receipt identity mismatch"}
        ids.append(id)
        seen[id]=true
        balance+=1
    if balance!=int(record.get("inventory",{}).get("star_fragments",-1)):
        return {"passed":false,"reason":"ledger mismatch"}
    if record.get("event_outcomes",[])!=ids:
        return {"passed":false,"reason":"outcome mismatch"}
    return {"passed":true,"value":{"pad":int(record["checkpoint"]["pad_index"]),
        "generation":int(record["generation"]),"fragments":balance,
        "event_ids":ids,"status":"COMMITTED_QA"}}

func apply_verified(stage:Node2D,transaction:RefCounted,fault_mode:String="none")->Dictionary:
    if not ["none","after_inventory","after_events","before_publish"].has(fault_mode):
        return {"passed":false,"reason":"unknown fault mode"}
    if not stage.placement_gate.get("blocked",false) or             not stage.placement_gate.get("items",[]).is_empty() or             not stage.placement_gate.get("events",[]).is_empty():
        return {"passed":false,"reason":"production world gate was open"}
    var disk:Dictionary=transaction.load_latest(stage.route)
    if not disk.get("valid",false):
        return {"passed":false,"reason":"no verified committed transaction"}
    var record:Dictionary=disk["record"]
    if record.get("scope","")!=QA_SCOPE or record.get("authorizes_gameplay_spawns",true):
        return {"passed":false,"reason":"outside QA authority"}
    var audit:Dictionary=TX.validate_record(stage.route,record)
    if not audit["passed"]:
        return {"passed":false,"reason":"transaction invariants failed"}
    var expected:Dictionary=TX.projection(record)
    # A fresh scene must FIRST recover its checkpoint. Never apply receipts
    # merely because a journal exists on disk.
    if stage.qa_projection!=expected:
        return {"passed":false,"reason":"checkpoint projection has not been recovered"}
    var gen:int=int(record["generation"])
    var digest:String=str(disk["digest"])
    if gen<int(current["generation"]):
        return {"passed":false,"reason":"stale generation rollback denied"}
    if gen==int(current["generation"]):
        if digest==committed_digest and fault_mode=="none":
            return {"passed":true,"idempotent":true,"generation":gen,
                "real_spawn_authority":false}
        return {"passed":false,"reason":"same generation different digest or fault"}
    if current["generation"]>0 and (gen!=int(current["generation"])+1):
        return {"passed":false,"reason":"unobserved generation gap"}
    var candidate:Dictionary=from_record(record)
    if not candidate["passed"]:return candidate
    var next:Dictionary=candidate["value"]
    # Stage simulated side effects in private memory. On any failure, drop the
    # staged copy (compensation), leaving committed disk and live UI untouched.
    var staging:Dictionary=current.duplicate(true)
    staging["fragments"]=next["fragments"]
    if fault_mode=="after_inventory":
        compensated_faults+=1
        return {"passed":false,"compensated":true,"stage":"inventory"}
    staging["event_ids"]=next["event_ids"].duplicate()
    if fault_mode=="after_events":
        compensated_faults+=1
        return {"passed":false,"compensated":true,"stage":"events"}
    staging["pad"]=next["pad"]
    staging["generation"]=next["generation"]
    staging["status"]=next["status"]
    if fault_mode=="before_publish":
        compensated_faults+=1
        return {"passed":false,"compensated":true,"stage":"publish"}
    # Single outward read-only presentation update after all checks succeed.
    stage.apply_event_projection(staging)
    current=staging.duplicate(true)
    committed_digest=digest
    observed_apply_count+=1
    return {"passed":true,"idempotent":false,"generation":gen,
        "receipts":next["event_ids"].size(),"real_spawn_authority":false}

func request_real_item(_id:String)->Dictionary:
    return {"passed":false,"reason":"no production gameplay authority"}
func request_real_event(_id:String)->Dictionary:
    return {"passed":false,"reason":"no production gameplay authority"}
