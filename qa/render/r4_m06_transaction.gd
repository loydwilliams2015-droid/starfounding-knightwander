extends RefCounted
## R4-M06: one serialized checkpoint + QA event + QA inventory projection.
## Only the complete envelope is renamed into a two-slot journal. The journal
## is local QA evidence, not a power-loss-durable or authenticated save system.
const BASE=preload("res://scripts/r4_m04_checkpoint.gd")
const STRICT=preload("res://scripts/r4_m05_journal.gd")
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
const FORMAT="R4M06/tx/1"
const VERSION=1
const MAX_BYTES=500000
const QA_SCOPE="standalone QA only"
var folder: String=""

func configure(name:String)->void:
    assert(name.is_valid_filename() and name.begins_with("r4m06_"))
    folder=ProjectSettings.globalize_path("user://r4_m06/"+name)
    DirAccess.make_dir_recursive_absolute(folder)
func slot_path(generation:int)->String:
    return folder+("/slot_a.json" if generation%2==1 else "/slot_b.json")
func reset_test_only()->void:
    assert(folder.contains("/r4_m06/r4m06_"))
    for suffix in ["slot_a.json","slot_b.json","slot_a.json.tmp","slot_b.json.tmp"]:
        var path:String=folder+"/"+suffix
        if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

static func receipt_id(pad:int)->String:
    return "qa_observation_pad_%02d"%pad
static func projection(payload:Dictionary)->Dictionary:
    return {"pad":int(payload["checkpoint"]["pad_index"]),
        "star_fragments":int(payload["inventory"]["star_fragments"]),
        "event_outcomes":payload["event_outcomes"].duplicate(true),
        "generation":int(payload["generation"])}

static func validate_record(route:Dictionary,record:Dictionary)->Dictionary:
    var faults:Array[String]=[]
    if int(record.get("version",-1))!=VERSION:faults.append("version")
    if record.get("scope","")!=QA_SCOPE:faults.append("scope")
    if record.get("authorizes_gameplay_spawns",true):faults.append("spawn authority")
    if record.get("route_fingerprint","")!=PROOF.fingerprint(route):faults.append("route fingerprint")
    if record.get("controller_id","")!=PROOF.CONTROLLER_ID:faults.append("controller identity")
    var gen:int=int(record.get("generation",-1))
    if gen<1:faults.append("generation")
    var checkpoint:Variant=record.get("checkpoint",null)
    if typeof(checkpoint)!=TYPE_DICTIONARY:
        faults.append("checkpoint structure")
        return {"passed":false,"errors":faults}
    var ck:Dictionary=BASE.validate_payload(route,checkpoint)
    faults.append_array(ck["errors"])
    if checkpoint.get("generation",-1)!=gen:faults.append("checkpoint generation")
    if checkpoint.get("previous_digest","none")!=record.get("previous_digest",""):
        faults.append("checkpoint journal link")
    if checkpoint.get("authorizes_gameplay_spawns",true):faults.append("checkpoint spawn authority")
    var receipts:Variant=record.get("receipts",null)
    var outcomes:Variant=record.get("event_outcomes",null)
    var inventory:Variant=record.get("inventory",null)
    if typeof(receipts)!=TYPE_ARRAY or typeof(outcomes)!=TYPE_ARRAY or typeof(inventory)!=TYPE_DICTIONARY:
        faults.append("QA ledger structures")
        return {"passed":false,"errors":faults}
    if receipts.size()!=gen or outcomes.size()!=receipts.size():faults.append("receipt count")
    if inventory.size()!=1 or int(inventory.get("star_fragments",-1))!=receipts.size():
        faults.append("double-entry projection")
    var ids:Dictionary={}
    var last_pad:=0
    for i in range(receipts.size()):
        var rc:Variant=receipts[i]
        if typeof(rc)!=TYPE_DICTIONARY:
            faults.append("receipt structure")
            continue
        var pad:int=int(rc.get("pad",-1))
        var id:String=str(rc.get("id",""))
        if pad<=last_pad or pad>int(checkpoint.get("pad_index",-1)):
            faults.append("receipt ordering or future position")
        if id!=receipt_id(pad) or ids.has(id):faults.append("receipt identity/replay")
        if rc.get("delta",-1)!=1 or rc.get("qa_only",false)!=true or rc.get("outcome","")!="inspected":
            faults.append("unapproved QA effect")
        if i>=outcomes.size() or outcomes[i]!=id:faults.append("outcome receipt mismatch")
        ids[id]=true
        last_pad=pad
    if int(record.get("last_receipt_pad",-1))!=last_pad or last_pad!=int(checkpoint["pad_index"]):
        faults.append("checkpoint/receipt mismatch")
    return {"passed":faults.is_empty(),"errors":faults}

static func pack(record:Dictionary)->Dictionary:
    var raw:String=Marshalls.raw_to_base64(var_to_bytes(record))
    return {"format":FORMAT,"data":raw,"sha256":raw.sha256_text()}
static func unpack(route:Dictionary,envelope:Variant)->Dictionary:
    if typeof(envelope)!=TYPE_DICTIONARY or envelope.get("format","")!=FORMAT:
        return {"valid":false,"reason":"format"}
    var data:Variant=envelope.get("data",null)
    if typeof(data)!=TYPE_STRING or data.length()<12 or data.length()>MAX_BYTES:
        return {"valid":false,"reason":"data size"}
    if data.sha256_text()!=envelope.get("sha256",""):
        return {"valid":false,"reason":"checksum"}
    var bytes:PackedByteArray=Marshalls.base64_to_raw(data)
    if bytes.is_empty() or bytes.size()>MAX_BYTES:
        return {"valid":false,"reason":"decoded size"}
    var decoded:Variant=bytes_to_var(bytes)
    if typeof(decoded)!=TYPE_DICTIONARY:return {"valid":false,"reason":"payload type"}
    var audited:Dictionary=validate_record(route,decoded)
    if not audited["passed"]:return {"valid":false,"reason":"invariant","errors":audited["errors"]}
    return {"valid":true,"record":decoded,"digest":envelope["sha256"]}

static func read_file(route:Dictionary,path:String)->Dictionary:
    if not FileAccess.file_exists(path):return {"valid":false,"reason":"missing"}
    var f:FileAccess=FileAccess.open(path,FileAccess.READ)
    if f==null:return {"valid":false,"reason":"file read"}
    if f.get_length()>MAX_BYTES:
        f.close()
        return {"valid":false,"reason":"file limit"}
    var content:String=f.get_as_text()
    f.close()
    return unpack(route,JSON.parse_string(content))

func read_slot(route:Dictionary,slot:int)->Dictionary:
    var row:Dictionary=read_file(route,slot_path(slot))
    if row.get("valid",false):
        var gen:int=int(row["record"]["generation"])
        if posmod(gen,2)!=posmod(slot,2):
            return {"valid":false,"reason":"slot parity"}
        if gen==1 and row["record"].get("previous_digest","bad")!="":
            return {"valid":false,"reason":"genesis chain"}
        if gen>1 and str(row["record"].get("previous_digest","")).length()!=64:
            return {"valid":false,"reason":"previous digest absent"}
    return row

static func extends_record(newer:Dictionary,older:Dictionary)->bool:
    if int(newer["generation"])!=int(older["generation"])+1:return false
    var a:Dictionary=newer["checkpoint"]
    var b:Dictionary=older["checkpoint"]
    if int(a["pad_index"])<=int(b["pad_index"]):return false
    var prev:Array=b["prefix"]
    var new_prefix:Array=a["prefix"]
    if prev.size()>=new_prefix.size():return false
    for i in range(prev.size()):
        if prev[i]!=new_prefix[i]:return false
    if a["entrance"]!=b["entrance"]:return false
    var old_receipts:Array=older["receipts"]
    var new_receipts:Array=newer["receipts"]
    if new_receipts.size()!=old_receipts.size()+1:return false
    for i in range(old_receipts.size()):
        if old_receipts[i]!=new_receipts[i]:return false
    return true

func load_latest(route:Dictionary)->Dictionary:
    var candidates:Array[Dictionary]=[]
    for slot in [1,2]:
        var row:Dictionary=read_slot(route,slot)
        if row.get("valid",false):candidates.append(row)
    if candidates.is_empty():return {"valid":false,"reason":"no valid transaction","spawn_authority":false}
    candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
        return int(a["record"]["generation"])<int(b["record"]["generation"]))
    if candidates.size()==1:
        if int(candidates[0]["record"]["generation"])!=1:
            return {"valid":false,"reason":"orphaned non-genesis transaction","spawn_authority":false}
        return {"valid":true,"record":candidates[0]["record"],"digest":candidates[0]["digest"],
            "fallback":false,"spawn_authority":false}
    var old:Dictionary=candidates[0]
    var new:Dictionary=candidates[1]
    if int(new["record"]["generation"])==int(old["record"]["generation"])+1 and \
            new["record"].get("previous_digest","")==old["digest"] and extends_record(new["record"],old["record"]):
        return {"valid":true,"record":new["record"],"digest":new["digest"],
            "fallback":false,"spawn_authority":false}
    if int(old["record"]["generation"])==1:
        return {"valid":true,"record":old["record"],"digest":old["digest"],
            "fallback":true,"spawn_authority":false}
    return {"valid":false,"reason":"unlinked journal pair","spawn_authority":false}

func prepare(route:Dictionary,entry:Dictionary,prefix:Array,position:Vector2,pad:int)->Dictionary:
    var previous:Dictionary=load_latest(route)
    var has_slots:bool=FileAccess.file_exists(slot_path(1)) or FileAccess.file_exists(slot_path(2))
    if not previous.get("valid",false) and has_slots:
        return {"passed":false,"reason":"untrusted previous journal"}
    var gen:=1
    var parent:=""
    var receipts:Array=[]
    if previous.get("valid",false):
        var r:Dictionary=previous["record"]
        if int(r["checkpoint"]["pad_index"])>=pad:
            return {"passed":false,"reason":"duplicate or reversed checkpoint"}
        gen=int(r["generation"])+1
        parent=previous["digest"]
        receipts=r["receipts"].duplicate(true)
    if pad!=prefix.size():return {"passed":false,"reason":"prefix length"}
    var rc:Dictionary={"id":receipt_id(pad),"pad":pad,"delta":1,"outcome":"inspected","qa_only":true}
    receipts.append(rc)
    var outcomes:Array=[]
    for x in receipts:outcomes.append(x["id"])
    var checkpoint:Dictionary=BASE.make_payload(route,entry,prefix,position,gen,parent)
    var transaction:Dictionary={"version":VERSION,"scope":QA_SCOPE,"generation":gen,
        "previous_digest":parent,"controller_id":PROOF.CONTROLLER_ID,
        "route_fingerprint":PROOF.fingerprint(route),"checkpoint":checkpoint,
        "receipts":receipts,"last_receipt_pad":pad,"inventory":{"star_fragments":receipts.size()},
        "event_outcomes":outcomes,"authorizes_gameplay_spawns":false}
    var check:Dictionary=validate_record(route,transaction)
    if not check["passed"]:return {"passed":false,"reason":"invalid prepared transaction","errors":check["errors"]}
    return {"passed":true,"record":transaction,"envelope":pack(transaction)}

func commit_from_actor(stage:Node2D,entry:Dictionary,prefix:Array,fault_mode:String="none")->Dictionary:
    if not ["none","before_open","partial_temp","verified_temp"].has(fault_mode):
        return {"passed":false,"reason":"invalid fault mode"}
    if not stage.placement_gate.get("blocked",false) or not stage.placement_gate.get("items",[]).is_empty() or not stage.placement_gate.get("events",[]).is_empty():
        return {"passed":false,"reason":"gameplay world not safely locked"}
    if not stage.demo.actor.is_on_floor() or absf(stage.demo.actor.velocity.y)>1.0:
        return {"passed":false,"reason":"actor not stably grounded"}
    if not stage.demo.adapter.pose_geometry_verified():
        return {"passed":false,"reason":"actor geometry invalid"}
    var plan:Dictionary=prepare(stage.route,entry,prefix,stage.demo.actor.global_position,prefix.size())
    if not plan["passed"]:return plan
    var rec:Dictionary=plan["record"]
    var gen:int=int(rec["generation"])
    var target:String=slot_path(gen)
    var temp:String=target+".tmp"
    if fault_mode=="before_open":return {"passed":false,"interrupted":true,"stage":fault_mode}
    var f:FileAccess=FileAccess.open(temp,FileAccess.WRITE)
    if f==null:return {"passed":false,"reason":"cannot open temp file"}
    if fault_mode=="partial_temp":
        f.store_string('{"format":"R4M06/tx/1","data":"')
    else:
        f.store_string(JSON.stringify(plan["envelope"])+"\n")
    f.flush()
    f.close()
    if fault_mode!="none":return {"passed":false,"interrupted":true,"stage":fault_mode}
    var verified:Dictionary=read_file(stage.route,temp)
    if not verified.get("valid",false):return {"passed":false,"reason":"unverified temp"}
    if DirAccess.rename_absolute(temp,target)!=OK:
        return {"passed":false,"reason":"rename failed"}
    var disk:Dictionary=load_latest(stage.route)
    if not disk.get("valid",false) or int(disk["record"]["generation"])!=gen:
        return {"passed":false,"reason":"post-rename journal check failed"}
    # Project the entire all-or-nothing QA transaction only after commit verified.
    stage.apply_qa_projection(projection(disk["record"]))
    return {"passed":true,"generation":gen,"pad":prefix.size(),
        "inventory":disk["record"]["inventory"].duplicate(true),
        "event_outcomes":disk["record"]["event_outcomes"].duplicate(true),
        "authorizes_gameplay_spawns":false}

func recover_scene(stage:Node2D)->Dictionary:
    var saved:Dictionary=load_latest(stage.route)
    if not saved.get("valid",false):return {"passed":false,"reason":saved.get("reason","missing transaction")}
    var record:Dictionary=saved["record"]
    var recovered:Dictionary=await STRICT.restore_and_confirm(stage,record["checkpoint"])
    if not recovered.get("passed",false):return {"passed":false,"reason":"failed post-reload floor check"}
    stage.apply_qa_projection(projection(record))
    return {"passed":true,"pad":int(record["checkpoint"]["pad_index"]),
        "generation":record["generation"],"inventory":record["inventory"].duplicate(true),
        "event_outcomes":record["event_outcomes"].duplicate(true),
        "native_floor_confirmed":true,"authorizes_gameplay_spawns":false}
