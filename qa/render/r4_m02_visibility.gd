extends RefCounted
## Deterministic camera-space visibility diagnostics and correct draw ordering.
const VIEWPORT := Vector2(960,540)
const SAFE_EDGE := 48.0
const ACTOR_HALF := Vector2(32,38)
const CAMERA_ZOOMS := [0.85,1.0,1.25]
static func evaluate(stage: Node2D) -> Dictionary:
    var camera: Camera2D=stage.camera
    var viewport_size: Vector2=stage.get_viewport_rect().size
    var xform: Transform2D=stage.get_viewport().get_canvas_transform()
    var screen: Vector2=xform*stage.demo.actor.global_position
    var scaled: Vector2=ACTOR_HALF*camera.zoom
    var rect:=Rect2(screen-scaled,scaled*2.0)
    var safe:=Rect2(Vector2(SAFE_EDGE,SAFE_EDGE),viewport_size-Vector2.ONE*SAFE_EDGE*2.0)
    var visual_layers: Array[int]=[]
    for n in stage.route_backdrops: visual_layers.append(n.z_index)
    var draw_order_valid: bool = stage.terrain.z_index<stage.demo.actor.z_index and \
        stage.connections.z_index<stage.demo.actor.z_index and stage.foreground.z_index<stage.demo.actor.z_index
    for index in range(visual_layers.size()):
        if visual_layers[index]>=stage.terrain.z_index: draw_order_valid=false
    var occlusion_risk: bool=stage.foreground.modulate.a>0.55 or stage.background_layers[3].modulate.a>0.75
    return {"screen":screen,"rect":rect,"safe_area":safe,"within_safe_area":safe.encloses(rect),
        "draw_order_valid":draw_order_valid,"occlusion_risk":occlusion_risk,"zoom":camera.zoom,
        "camera_owner":camera.get_parent()==stage.demo.actor,
        "background_z":visual_layers,"ground_z":stage.terrain.z_index,
        "connections_z":stage.connections.z_index,"actor_z":stage.demo.actor.z_index,
        "collision_added":false,"spawn_authority":false}
