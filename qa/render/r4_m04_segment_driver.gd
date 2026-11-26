extends RefCounted
## Native S33 movement for one bounded leg range. Returns a prefix fragment.
const BASE=preload("res://scripts/r4_m03_chain_driver.gd")
static func segment(stage:Node2D,start:int,stop:int) -> Dictionary:
    var actor:CharacterBody2D=stage.demo.actor
    var pads:Array=stage.route["pads"]
    var out:Array[Dictionary]=[]
    var end:int=mini(stop,pads.size()-1)
    if start<0 or start>=end:return {"passed":false,"edges":out,"reason":"invalid segment bounds"}
    for i in range(start,end):
        var a:Dictionary=pads[i]
        var b:Dictionary=pads[i+1]
        var source_top:float=float(a["y"])-float(a["height"])*0.5
        var target_top:float=float(b["y"])-float(b["height"])*0.5
        var source_x:float=stage.DISTRICT_START+float(a["x"])
        var goal_x:float=stage.DISTRICT_START+float(b["x"])
        if not actor.is_on_floor() or absf(actor.global_position.y-source_top)>BASE.GROUND_TOLERANCE:
            Input.action_release("sk_right")
            return {"passed":false,"edges":out,"reason":"not grounded on source %d"%i}
        var launch_x:float=maxf(actor.global_position.x,source_x+BASE.LAUNCH_FORWARD)
        var approach:=0
        while actor.global_position.x<launch_x-2 and approach<35:
            Input.action_press("sk_right")
            await stage.get_tree().physics_frame
            approach+=1
            if not actor.is_on_floor():break
        Input.action_release("sk_right")
        if not actor.is_on_floor() or absf(actor.global_position.y-source_top)>BASE.GROUND_TOLERANCE:
            return {"passed":false,"edges":out,"reason":"left source during takeoff %d"%i}
        var takeoff:Vector2=actor.global_position
        stage.demo.jump_queued=true
        var air:=false
        var landed:=false
        var ticks:=0
        var reason:="timeout"
        for tick in range(BASE.MAX_PER_EDGE_TICKS):
            if actor.global_position.x<goal_x-BASE.STOP_BEFORE_TARGET:
                Input.action_press("sk_right")
            else:
                Input.action_release("sk_right")
            await stage.get_tree().physics_frame
            ticks=tick+1
            if not actor.is_on_floor():air=true
            if air and actor.is_on_floor():
                var yes_y:bool=absf(actor.global_position.y-target_top)<BASE.GROUND_TOLERANCE
                var yes_x:bool=absf(actor.global_position.x-goal_x)<=float(b["width"])*0.5-16
                landed=yes_y and yes_x
                reason="native target-pad landing" if landed else "unexpected landing"
                break
            if actor.global_position.y>460.0:
                reason="fell to ground"
                break
        Input.action_release("sk_right")
        if not landed:return {"passed":false,"edges":out,"reason":reason,"failed_from":i}
        out.append({"from":i,"to":i+1,"passable":true,"ticks":ticks,"launch":takeoff,
            "landing":actor.global_position,"actual_end":actor.global_position,"airborne":air,
            "reason":"native target-pad landing","source_top":source_top,"target_top":target_top})
    return {"passed":out.size()==end-start,"edges":out,"completed":out.size(),"end_index":end,
        "last_position":actor.global_position,"content_blocked":stage.placement_gate["blocked"]}
