extends RefCounted
## Input-driven native S33 controller traversal. No teleports between route links.
## Driving decisions do not issue a gameplay spawn certificate.
const MAX_PER_EDGE_TICKS := 155
const LAUNCH_FORWARD := 23.0
const STOP_BEFORE_TARGET := 8.0
const GROUND_TOLERANCE := 2.5

static func native_chain(stage: Node2D) -> Dictionary:
    var actor: CharacterBody2D = stage.demo.actor
    var pads: Array = stage.route["pads"]
    var events: Array[Dictionary] = []
    var edges: Array[Dictionary] = []
    var completed := 0
    for index in range(pads.size()-1):
        var a: Dictionary=pads[index]
        var b: Dictionary=pads[index+1]
        var source_top: float=float(a["y"])-float(a["height"])*0.5
        var destination_top: float=float(b["y"])-float(b["height"])*0.5
        var source_x: float=stage.DISTRICT_START+float(a["x"])
        var destination_x: float=stage.DISTRICT_START+float(b["x"])
        var result: Dictionary={"from":index,"to":index+1,"passable":false,"ticks":0,
            "launch":actor.global_position,"landing":Vector2.ZERO,"source_top":source_top,
            "target_top":destination_top,"reason":"timeout"}
        # Never accept a link if the previous edge did not land on its source.
        if not actor.is_on_floor() or absf(actor.global_position.y-source_top)>GROUND_TOLERANCE:
            result["reason"]="not grounded on source pad"
            edges.append(result)
            break
        # Approach takeoff within the actual pad. Preserve continuity after prior landing.
        var launch_x: float=maxf(actor.global_position.x,source_x+LAUNCH_FORWARD)
        var grounded_for := 0
        while actor.global_position.x < launch_x-2 and grounded_for < 35:
            Input.action_press("sk_right")
            await stage.get_tree().physics_frame
            grounded_for+=1
            if not actor.is_on_floor():break
        Input.action_release("sk_right")
        if not actor.is_on_floor() or absf(actor.global_position.y-source_top)>GROUND_TOLERANCE:
            result["reason"]="takeoff preparation exited source surface"
            edges.append(result)
            break
        var takeoff: Vector2=actor.global_position
        stage.demo.jump_queued=true
        var actually_airborne:=false
        var tick:=0
        var touchdown:=false
        for t in range(MAX_PER_EDGE_TICKS):
            if actor.global_position.x < destination_x-STOP_BEFORE_TARGET:
                Input.action_press("sk_right")
            else:
                Input.action_release("sk_right")
            await stage.get_tree().physics_frame
            tick=t+1
            if not actor.is_on_floor():actually_airborne=true
            if actually_airborne and actor.is_on_floor():
                var within_y:bool=absf(actor.global_position.y-destination_top)<GROUND_TOLERANCE
                var within_x:bool=absf(actor.global_position.x-destination_x)<=float(b["width"])*0.5-16.0
                if within_y and within_x:
                    touchdown=true
                    result["passable"]=true
                    result["landing"]=actor.global_position
                    result["reason"]="native target-pad landing"
                else:
                    result["reason"]="landed on another collider"
                break
            if actor.global_position.y>460.0:
                result["reason"]="fell to ground"
                break
        Input.action_release("sk_right")
        result["ticks"]=tick
        result["launch"]=takeoff
        result["airborne"]=actually_airborne
        result["actual_end"]=actor.global_position
        edges.append(result)
        if touchdown:
            completed+=1
            events.append({"type":"native_pad_landing","pad":index+1,"foot":actor.global_position})
        else:break
    Input.action_release("sk_right")
    var accepted:bool=completed==pads.size()-1
    return {"passed":accepted,"edges":edges,"completed":completed,"required":pads.size()-1,
        "first_failure":completed if not accepted else -1,"landings":events,
        "last_position":actor.global_position,"content_blocked":stage.placement_gate["blocked"],
        "controller":"S33 -410 impulse / 1050 gravity / 220 walk", "native_complete":accepted}
