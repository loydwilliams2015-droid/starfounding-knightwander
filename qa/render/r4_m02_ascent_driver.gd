extends RefCounted
## Input-only native QA driver; no actor teleports after initial spawn.
## It steers S33 movement actions; geometry, physics and collisions decide landings.
const MAX_TICKS := 500
const UP_LIMIT := 66.0 # below the S33 80-unit ballistic maximum
static func targets(stage: Node2D) -> Array[Dictionary]:
    var result: Array[Dictionary] = stage.ascent_plan["steps"].duplicate(true)
    var pad:Dictionary=stage.route["pads"][0]
    result.append({"index":result.size(),"x":pad["x"],
        "top_y":float(pad["y"])-float(pad["height"])*0.5,"kind":"first_R2_pad"})
    return result
static func drive(stage: Node2D) -> Dictionary:
    var p:CharacterBody2D=stage.demo.actor
    var pad_top:float=stage.ascent_plan["target_pad_top"]
    var milestones:Array[Dictionary]=[]
    var highest:float=p.global_position.y
    var jumps:=0
    var last_jump: int=-100
    var on_floor_before:bool=p.is_on_floor()
    var ready_targets: Array[Dictionary]=targets(stage)
    var goal_x:float=p.global_position.x
    var reached:=false
    for tick in range(MAX_TICKS):
        if p.is_on_floor() and p.global_position.y > pad_top+2 and tick-last_jump>22:
            var candidate:Dictionary={}
            for rec in ready_targets:
                var delta_y:float=p.global_position.y-float(rec["top_y"])
                if delta_y>5 and delta_y<=UP_LIMIT:
                    candidate=rec
                    break
            if not candidate.is_empty():
                goal_x=stage.DISTRICT_START+float(candidate["x"])
                stage.demo.jump_queued=true
                jumps+=1
                last_jump=tick
                milestones.append({"kind":"jump","tick":tick,"position":p.global_position,"goal":goal_x,"goal_top":candidate["top_y"]})
        if p.global_position.x<goal_x-3:
            Input.action_press("sk_right")
        else:
            Input.action_release("sk_right")
        await stage.get_tree().physics_frame
        highest=minf(highest,p.global_position.y)
        if p.is_on_floor() and not on_floor_before:
            milestones.append({"kind":"land","tick":tick,"position":p.global_position})
        on_floor_before=p.is_on_floor()
        if p.is_on_floor() and absf(p.global_position.y-pad_top)<2 and p.global_position.x>stage.DISTRICT_START+100.0:
            reached=true
            milestones.append({"kind":"success","tick":tick,"position":p.global_position})
            break
    Input.action_release("sk_right")
    return {"passed":reached,"jumps":jumps,"highest_y":highest,"milestones":milestones,
        "last_position":p.global_position,"last_grounded":p.is_on_floor(),
        "ticks":milestones[-1]["tick"] if reached else MAX_TICKS,
        "content_blocked":stage.placement_gate["blocked"]}
