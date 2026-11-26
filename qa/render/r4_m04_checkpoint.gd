extends RefCounted
## Standalone QA local checkpoint journal. Checksums detect damaged files, not hostile edits.
## In-game item/event authority is never derived from these records.
const PROOF=preload("res://scripts/r4_m03_certificate.gd")
const VERSION := 1
const MAX_TICK := 155
const TOLERANCE := 2.5
var folder: String=""

func configure(relative_name:String) -> void:
    assert(relative_name.is_valid_filename())
    folder=ProjectSettings.globalize_path("user://r4_m04/"+relative_name)
    DirAccess.make_dir_recursive_absolute(folder)

func slot_path(generation:int) -> String:
    return folder+("/slot_a.json" if generation%2==1 else "/slot_b.json")

static func audit_prefix(route:Dictionary, entry:Dictionary, prefix:Array, pad_index:int) -> Dictionary:
    var faults:Array[String]=[]
    var pads:Array=route.get("pads",[])
    var edges:Array=route.get("edges",[])
    if pads.is_empty() or edges.size()!=pads.size()-1:
        faults.append("invalid route topology")
        return {"passed":false,"errors":faults}
    if pad_index<0 or pad_index>=pads.size() or prefix.size()!=pad_index:
        faults.append("prefix length or checkpoint index invalid")
    if not entry.get("passed",false) or not entry.get("last_grounded",false) or typeof(entry.get("last_position",null))!=TYPE_VECTOR2:
        faults.append("native first pad entry unavailable")
    else:
        var first:Dictionary=pads[0]
        var p0:Vector2=entry["last_position"]
        if absf(p0.y-(float(first["y"])-float(first["height"])*0.5))>TOLERANCE:
            faults.append("invalid first pad foot")
    var prior:Vector2=entry.get("last_position",Vector2.ZERO)
    for i in range(prefix.size()):
        if typeof(prefix[i])!=TYPE_DICTIONARY:
            faults.append("malformed edge type %d"%i)
            continue
        var item:Dictionary=prefix[i]
        if i>=edges.size():
            faults.append("extra edge in prefix")
            break
        var src:Dictionary=pads[i]
        var dest:Dictionary=pads[i+1]
        if int(item.get("from",-1))!=i or int(item.get("to",-1))!=i+1:
            faults.append("edge order mismatch %d"%i)
            continue
        if not item.get("passable",false) or not item.get("airborne",false) or item.get("reason","")!="native target-pad landing":
            faults.append("non-native landing %d"%i)
        if typeof(item.get("launch",null))!=TYPE_VECTOR2 or typeof(item.get("landing",null))!=TYPE_VECTOR2 or typeof(item.get("actual_end",null))!=TYPE_VECTOR2:
            faults.append("missing or malformed trace coordinates %d"%i)
            continue
        var launch:Vector2=item["launch"]
        var landing:Vector2=item["landing"]
        var actual:Vector2=item["actual_end"]
        var sx:float=4000.0+float(src["x"])
        var dx:float=4000.0+float(dest["x"])
        var sy:float=float(src["y"])-float(src["height"])*0.5
        var dy:float=float(dest["y"])-float(dest["height"])*0.5
        if absf(launch.x-sx)>float(src["width"])*0.5-16.0 or absf(launch.y-sy)>TOLERANCE:
            faults.append("off-source launch %d"%i)
        if absf(landing.x-dx)>float(dest["width"])*0.5-16.0 or absf(landing.y-dy)>TOLERANCE:
            faults.append("off-target landing %d"%i)
        if landing.distance_to(actual)>0.01:
            faults.append("trace landing mismatch %d"%i)
        if i>0 and prior.distance_to(launch)>float(src["width"])*0.5:
            faults.append("noncontinuous source %d"%i)
        if int(item.get("ticks",-1))<1 or int(item.get("ticks",-1))>MAX_TICK:
            faults.append("edge timeout %d"%i)
        prior=landing
    return {"passed":faults.is_empty(),"errors":faults,"checked_edges":prefix.size()}

static func validate_payload(route:Dictionary,payload:Dictionary) -> Dictionary:
    var errors:Array[String]=[]
    if payload.get("version",-1)!=VERSION: errors.append("version")
    if payload.get("route_fingerprint","")!=PROOF.fingerprint(route):errors.append("route fingerprint")
    if payload.get("controller_id","")!=PROOF.CONTROLLER_ID:errors.append("controller")
    if int(payload.get("generation",0))<1:errors.append("generation")
    if int(payload.get("pad_index",-1))<0:errors.append("checkpoint index")
    if payload.get("authorizes_gameplay_spawns",true):errors.append("unauthorized spawn")
    if payload.get("scope","")!="standalone QA only":errors.append("scope")
    if payload.get("velocity",Vector2.ONE)!=Vector2.ZERO:errors.append("unsafe velocity")
    if not payload.get("grounded",false):errors.append("not grounded")
    var ix:int=int(payload.get("pad_index",-1))
    var pads:Array=route.get("pads",[])
    if ix>=0 and ix<pads.size() and typeof(payload.get("actor_position",null))==TYPE_VECTOR2:
        var pos:Vector2=payload["actor_position"]
        var pad:Dictionary=pads[ix]
        if absf(pos.y-(float(pad["y"])-float(pad["height"])*0.5))>TOLERANCE or absf(pos.x-(4000.0+float(pad["x"])))>float(pad["width"])*0.5-16.0:
            errors.append("unsafe checkpoint foot")
    else:errors.append("missing checkpoint foot")
    var auditable_entry:Dictionary={}
    var auditable_prefix:Array=[]
    if typeof(payload.get("entrance",null))==TYPE_DICTIONARY:
        auditable_entry=payload["entrance"]
    else:errors.append("invalid entrance structure")
    if typeof(payload.get("prefix",null))==TYPE_ARRAY:
        auditable_prefix=payload["prefix"]
    else:errors.append("invalid prefix structure")
    var audit:Dictionary=audit_prefix(route,auditable_entry,auditable_prefix,ix)
    errors.append_array(audit["errors"])
    if not payload.has("prefix_hash") or payload.get("prefix_hash","")!=str(auditable_prefix).sha256_text():
        errors.append("prefix digest")
    return {"passed":errors.is_empty(),"errors":errors,"checked_edges":audit.get("checked_edges",0)}

static func make_payload(route:Dictionary,entry:Dictionary,prefix:Array,position:Vector2,sequence:int,prior_digest:String) -> Dictionary:
    return {"version":VERSION,"route_fingerprint":PROOF.fingerprint(route),"controller_id":PROOF.CONTROLLER_ID,
        "generation":sequence,"previous_digest":prior_digest,"pad_index":prefix.size(),
        "actor_position":position,"velocity":Vector2.ZERO,"grounded":true,
        "entrance":entry.duplicate(true),"prefix":prefix.duplicate(true),"prefix_hash":str(prefix).sha256_text(),
        "scope":"standalone QA only","authorizes_gameplay_spawns":false}

static func pack_envelope(payload:Dictionary) -> Dictionary:
    var encoded:String=Marshalls.raw_to_base64(var_to_bytes(payload))
    return {"format":"R4M04/checkpoint/1","payload_b64":encoded,"digest":encoded.sha256_text()}

static func unwrap(route:Dictionary,envelope:Variant) -> Dictionary:
    if typeof(envelope)!=TYPE_DICTIONARY or envelope.get("format","")!="R4M04/checkpoint/1":
        return {"valid":false,"reason":"unknown envelope"}
    var encoded:Variant=envelope.get("payload_b64",null)
    if typeof(encoded)!=TYPE_STRING or encoded.length()<10 or encoded.sha256_text()!=envelope.get("digest",""):
        return {"valid":false,"reason":"damaged envelope digest"}
    var bytes:PackedByteArray=Marshalls.base64_to_raw(encoded)
    if bytes.size()>300000 or bytes.is_empty():return {"valid":false,"reason":"oversized or empty record"}
    var payload:Variant=bytes_to_var(bytes)
    if typeof(payload)!=TYPE_DICTIONARY:return {"valid":false,"reason":"invalid record variant"}
    var check:Dictionary=validate_payload(route,payload)
    if not check["passed"]:return {"valid":false,"reason":"payload invariant","errors":check["errors"]}
    return {"valid":true,"payload":payload,"digest":envelope["digest"]}

func inspect_slot(route:Dictionary,generation:int) -> Dictionary:
    var path:String=slot_path(generation)
    if not FileAccess.file_exists(path):return {"valid":false,"reason":"slot missing"}
    var source:FileAccess=FileAccess.open(path,FileAccess.READ)
    if source==null:return {"valid":false,"reason":"unreadable slot"}
    if source.get_length()>500000:
        source.close()
        return {"valid":false,"reason":"oversized slot"}
    var text:String=source.get_as_text()
    source.close()
    var json:Variant=JSON.parse_string(text)
    return unwrap(route,json)

func load_latest(route:Dictionary) -> Dictionary:
    var a:Dictionary=inspect_slot(route,1)
    var b:Dictionary=inspect_slot(route,2)
    var valid:Array[Dictionary]=[]
    for v in [a,b]:
        if v.get("valid",false):valid.append(v)
    if valid.is_empty():return {"valid":false,"reason":"no valid local checkpoint","slot_a":a.get("reason","ok"),"slot_b":b.get("reason","ok")}
    valid.sort_custom(func(x:Dictionary,y:Dictionary)->bool:return int(x["payload"]["generation"])>int(y["payload"]["generation"]))
    var chosen:Dictionary=valid[0]
    # Alternate slot chains: when both generations survive, reject an unlinked
    # newest record instead of treating a valid checksum as sufficient authority.
    if valid.size()==2:
        var older:Dictionary=valid[1]
        if int(chosen["payload"]["generation"])==int(older["payload"]["generation"])+1 and chosen["payload"]["previous_digest"]!=older["digest"]:
            chosen=older
    return {"valid":true,"payload":chosen["payload"],"digest":chosen["digest"],"fallback":chosen!=valid[0],
        "source":"local QA checkpoint; not production save authority"}

func commit(route:Dictionary,entry:Dictionary,prefix:Array,position:Vector2) -> Dictionary:
    var latest:Dictionary=load_latest(route)
    var generation:int=1
    var prior:String=""
    if latest.get("valid",false):
        var previous:Dictionary=latest["payload"]
        if prefix.size()<=int(previous["pad_index"]):
            return {"passed":false,"reason":"duplicate or regressing checkpoint index"}
        generation=int(previous["generation"])+1
        prior=latest["digest"]
    var payload:Dictionary=make_payload(route,entry,prefix,position,generation,prior)
    var checked:Dictionary=validate_payload(route,payload)
    if not checked["passed"]:return {"passed":false,"reason":"invariant rejected","errors":checked["errors"]}
    var envelope:Dictionary=pack_envelope(payload)
    var filename:String=slot_path(generation)
    var temporary:String=filename+".tmp"
    var file:FileAccess=FileAccess.open(temporary,FileAccess.WRITE)
    if file==null:return {"passed":false,"reason":"temporary write failed"}
    file.store_string(JSON.stringify(envelope)+"\n")
    file.flush()
    file.close()
    if inspect_temp(route,temporary)["valid"]!=true:
        DirAccess.remove_absolute(temporary)
        return {"passed":false,"reason":"temporary verification failed"}
    var err:int=DirAccess.rename_absolute(temporary,filename)
    if err!=OK:return {"passed":false,"reason":"atomic slot rename failed %d"%err}
    return {"passed":true,"generation":generation,"digest":envelope["digest"],"pad_index":prefix.size(),
        "authorizes_gameplay_spawns":false}

func inspect_temp(route:Dictionary,path:String) -> Dictionary:
    return unwrap(route,JSON.parse_string(FileAccess.get_file_as_string(path)))

static func restore_stage(stage:Node2D,record:Dictionary) -> Dictionary:
    var check:Dictionary=validate_payload(stage.route,record)
    if not check["passed"]:return {"passed":false,"errors":check["errors"]}
    # One explicit teleport at scene initialization is *checkpoint recovery*,
    # not proof of a native traversal edge. We verify floor physics afterwards.
    stage.demo.actor.global_position=record["actor_position"]
    stage.demo.actor.velocity=Vector2.ZERO
    stage.demo.jump_queued=false
    stage.placement_gate["blocked"]=true
    stage.placement_gate["items"]=[]
    stage.placement_gate["events"]=[]
    return {"passed":true,"checkpoint_pad":record["pad_index"],"needs_native_floor_confirmation":true,
        "authorizes_gameplay_spawns":false}
