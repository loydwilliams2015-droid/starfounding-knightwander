extends "res://scripts/r4_m04_checkpoint.gd"
## R4-M05 strengthened local QA journal reader. It verifies slot parity,
## the previous digest and the retained-prefix relationship. No crypto auth;
## neither file hashes nor test certificates authorize production spawns.

static func prefix_extends(new_record:Dictionary, old_record:Dictionary)->bool:
    if int(new_record.get("generation",-1))!=int(old_record.get("generation",-1))+1:
        return false
    if int(new_record.get("pad_index",-1))<=int(old_record.get("pad_index",-1)):
        return false
    var prior:Variant=old_record.get("prefix",null)
    var newer:Variant=new_record.get("prefix",null)
    if typeof(prior)!=TYPE_ARRAY or typeof(newer)!=TYPE_ARRAY or newer.size()<=prior.size():
        return false
    for k in range(prior.size()):
        if prior[k]!=newer[k]:return false
    return new_record.get("entrance",{})==old_record.get("entrance",{})

func inspect_slot(route:Dictionary,generation:int)->Dictionary:
    var checked:Dictionary=super.inspect_slot(route,generation)
    if not checked.get("valid",false):return checked
    var g:int=int(checked["payload"].get("generation",-1))
    if g<1 or posmod(g,2)!=posmod(generation,2):
        return {"valid":false,"reason":"record generation does not belong to this slot"}
    if g==1 and checked["payload"].get("previous_digest","notempty")!="":
        return {"valid":false,"reason":"genesis must not reference a previous digest"}
    if g>1 and str(checked["payload"].get("previous_digest","")).length()!=64:
        return {"valid":false,"reason":"non-genesis record missing prior digest"}
    return checked

func load_latest(route:Dictionary)->Dictionary:
    var a:Dictionary=inspect_slot(route,1)
    var b:Dictionary=inspect_slot(route,2)
    var good:Array[Dictionary]=[]
    if a.get("valid",false):good.append(a)
    if b.get("valid",false):good.append(b)
    if good.is_empty():
        return {"valid":false,"reason":"no valid checkpoint record","spawn_authority":false}
    good.sort_custom(func(x:Dictionary,y:Dictionary)->bool:
        return int(x["payload"]["generation"])<int(y["payload"]["generation"]))
    if good.size()==1:
        if int(good[0]["payload"]["generation"])!=1:
            # Strict downgrade: after the genesis slot is overwritten, losing a
            # second slot means the remaining generation is not independently linked.
            return {"valid":false,"reason":"orphaned non-genesis checkpoint","spawn_authority":false}
        return {"valid":true,"payload":good[0]["payload"],"digest":good[0]["digest"],
            "fallback":false,"verified_chain":true,"spawn_authority":false}
    var older:Dictionary=good[0]
    var newer:Dictionary=good[1]
    var expected:bool=int(newer["payload"]["generation"])==int(older["payload"]["generation"])+1
    var linked:bool=newer["payload"].get("previous_digest","")==older["digest"]
    var extended:bool=prefix_extends(newer["payload"],older["payload"])
    if expected and linked and extended:
        return {"valid":true,"payload":newer["payload"],"digest":newer["digest"],
            "fallback":false,"verified_chain":true,"spawn_authority":false}
    if int(older["payload"]["generation"])==1:
        return {"valid":true,"payload":older["payload"],"digest":older["digest"],
            "fallback":true,"verified_chain":true,"reason":"invalid newer journal link",
            "spawn_authority":false}
    return {"valid":false,"reason":"unlinked or reordered generation pair","spawn_authority":false}

func commit(route:Dictionary,entry:Dictionary,prefix:Array,position:Vector2)->Dictionary:
    # Do not restart at generation 1 while there are existing records that
    # do not form a verified chain. Recovery must be explicitly reset by caller.
    var previous:Dictionary=load_latest(route)
    if not previous.get("valid",false):
        if FileAccess.file_exists(slot_path(1)) or FileAccess.file_exists(slot_path(2)):
            return {"passed":false,"reason":"unverified existing journal; explicit reset required"}
    var result:Dictionary=super.commit(route,entry,prefix,position)
    result["authorizes_gameplay_spawns"]=false
    return result

func reset_test_only()->void:
    # Never call in production. Explicit test namespaces only.
    assert(folder.contains("/r4_m04/r4m05_"))
    for path in [slot_path(1),slot_path(2),slot_path(1)+".tmp",slot_path(2)+".tmp"]:
        if FileAccess.file_exists(path):DirAccess.remove_absolute(path)

func fault_probe(route:Dictionary,payload:Dictionary,mode:String)->Dictionary:
    # Controlled deterministic power-loss *simulation* at write boundaries.
    # Existing committed records remain unchanged by all pre-rename modes.
    if not ["before_open","partial_temp","verified_temp"].has(mode):
        return {"passed":false,"reason":"unsupported fault mode"}
    var current:Dictionary=load_latest(route)
    if not current.get("valid",false):return {"passed":false,"reason":"no baseline commit"}
    if mode=="before_open":return {"passed":true,"simulated_stage":mode}
    var generation:int=int(current["payload"]["generation"])+1
    var temp:String=slot_path(generation)+".tmp"
    var f:FileAccess=FileAccess.open(temp,FileAccess.WRITE)
    if f==null:return {"passed":false,"reason":"temp open failed"}
    if mode=="partial_temp":
        f.store_string("{\"format\":\"R4M04/checkpoint/1\",\"payload_b64\":\"")
    else:
        f.store_string(JSON.stringify(pack_envelope(payload))+"\n")
    f.flush()
    f.close()
    return {"passed":true,"simulated_stage":mode,"temp_file":temp,
        "committed_records_unchanged":true}

func commit_from_actor(stage:Node2D,entry:Dictionary,prefix:Array)->Dictionary:
    # No checkpoint can be issued from an airborne or transitioning actor, even
    # if the caller supplies an old valid saved position. This is QA scene-only.
    if not stage.placement_gate.get("blocked",false):
        return {"passed":false,"reason":"scene content authority was unexpectedly open"}
    if not stage.demo.actor.is_on_floor():
        return {"passed":false,"reason":"live actor is not grounded"}
    if absf(stage.demo.actor.velocity.y)>1.0:
        return {"passed":false,"reason":"live actor has vertical velocity"}
    if not stage.demo.adapter.pose_geometry_verified():
        return {"passed":false,"reason":"actor pose/collider geometry invalid"}
    return commit(stage.route,entry,prefix,stage.demo.actor.global_position)

static func restore_and_confirm(stage:Node2D,payload:Dictionary)->Dictionary:
    var restored:Dictionary=restore_stage(stage,payload)
    if not restored.get("passed",false):return restored
    # Godot's CharacterBody2D floor state must be observed after physics steps.
    for k in range(5):await stage.get_tree().physics_frame
    var p:CharacterBody2D=stage.demo.actor
    var good:bool=p.is_on_floor() and absf(p.global_position.y-payload["actor_position"].y)<2.0
    good=good and stage.placement_gate.get("blocked",false)
    good=good and stage.placement_gate.get("items",[]).is_empty() and stage.placement_gate.get("events",[]).is_empty()
    return {"passed":good,"checkpoint_pad":payload["pad_index"],"native_floor_confirmed":good,
        "authorizes_gameplay_spawns":false,"reason":"native floor recheck" if good else "unsafe restored collision state"}

