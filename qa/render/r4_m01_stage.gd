extends "res://scripts/r4_m00_stage.gd"
## R4-M01 integrates the real R2 generated colliders as a *separate QA district*.
## No changed S33 movement constants. R2 physics certificates do not authorize
## spawning with this different knight controller; all items/events fail closed.
const GEN = preload("res://scripts/r2_route_generator.gd")
const SAFE = preload("res://scripts/r2_chain_safety.gd")
const JOINTS = preload("res://scripts/r2_material_joints.gd")
const SURFACE = preload("res://scripts/r2_surface_art.gd")
const ART = preload("res://scripts/r4_m01_art.gd")
const BRIDGE = preload("res://scripts/r4_m01_bridge_contract.gd")
const DISTRICT_START := 4000.0
const STRATA_Z := [-12,-11,-10,-9]
const STRATA_SPEED_X := [0.03,0.16,0.38,0.70]
const STRATA_SPEED_Y := [0.03,0.10,0.24,0.50]
var route_seed := 41
var route_screens := 4
var route: Dictionary = {}
var proxy: Dictionary = {}
var art_plan: Array[Dictionary] = []
var joint_plan: Array[Dictionary] = []
var collision_root: Node2D
var terrain: Node2D
var connections: Node2D
var route_backdrops: Array[Parallax2D]=[]
var backdrop_art: Array[Node2D]=[]
var route_screen := 0
var placement_gate: Dictionary = {"blocked":true,"items":[],"events":[],"reason":"controller-mismatch/unverified"}
func _ready() -> void:
    super._ready()
    load_route(route_seed,route_screens)
    for k in range(4):
        var back:=Parallax2D.new()
        back.name="R2Stratum%d"%k
        back.z_index=STRATA_Z[k]
        back.scroll_scale=Vector2(STRATA_SPEED_X[k],STRATA_SPEED_Y[k])
        add_child(back)
        move_child(back,0)
        var art:=Node2D.new()
        art.set_script(ART)
        art.name="GeneratedStratum%d"%k
        art.position=Vector2(DISTRICT_START,0)
        art.configure(route,art_plan,joint_plan,2,k)
        back.add_child(art)
        route_backdrops.append(back)
        backdrop_art.append(art)
    preview_route_screen(0)
    # This is a material/lighting QA scene: the R2 map is still under separate
    # passability testing with S33 jump physics.
    r4_info.text += " | SPAWNS LOCKED - DIFFERENT CONTROLLER"
    var help:=Label.new()
    help.name="R4M01RouteControls"
    help.position=Vector2(14,507)
    help.text="F1-F4: inspect generated districts   |   M: reduce motion   |   SPACE: jump   |   A/D: move"
    help.add_theme_font_size_override("font_size",11)
    help.add_theme_color_override("font_color",Color("b8d5d5"))
    motion_ui.add_child(help)
func load_route(seed: int, screens: int) -> void:
    route=GEN.generate(seed,screens)
    assert(GEN.validate(route)["passed"])
    proxy=SAFE.classify(route)
    art_plan=SURFACE.build(route,proxy)
    joint_plan=JOINTS.plan(route,proxy)
    route_seed=seed
    route_screens=screens
    if is_instance_valid(collision_root):
        collision_root.queue_free()
        terrain.queue_free()
        connections.queue_free()
    collision_root=Node2D.new()
    collision_root.name="GeneratedR2CollisionDistrict"
    collision_root.position=Vector2(DISTRICT_START,0)
    demo.add_child(collision_root)
    for i in range(route["ground"].size()):
        _add_collider("R2Ground%02d"%i,route["ground"][i],false)
    for i in range(route["pads"].size()):
        _add_collider("R2Pad%02d"%i,route["pads"][i],true)
    terrain=Node2D.new()
    terrain.set_script(ART)
    terrain.name="R2GeneratedTerrain"
    terrain.z_index=0
    terrain.position=Vector2(DISTRICT_START,0)
    demo.add_child(terrain)
    terrain.configure(route,art_plan,joint_plan,0)
    connections=Node2D.new()
    connections.set_script(ART)
    connections.name="R2DecorativeConnections"
    connections.position=Vector2(DISTRICT_START,0)
    connections.z_index=1
    demo.add_child(connections)
    connections.configure(route,art_plan,joint_plan,1)
    placement_gate=BRIDGE.fail_closed(route)
func _add_collider(name: String, rec: Dictionary, one_way: bool) -> void:
    var block:=StaticBody2D.new()
    block.name=name
    block.position=Vector2(rec["x"],rec["y"])
    block.collision_layer=1
    block.collision_mask=0
    collision_root.add_child(block)
    var col:=CollisionShape2D.new()
    var rect:=RectangleShape2D.new()
    rect.size=Vector2(rec["width"],rec["height"])
    col.shape=rect
    col.one_way_collision=one_way
    block.add_child(col)
func _apply_reduce_motion(value: bool) -> void:
    super._apply_reduce_motion(value)
    if is_instance_valid(connections): connections.set_reduced_motion(value)
    for b in route_backdrops:
        b.scroll_scale=Vector2.ZERO if value else Vector2(STRATA_SPEED_X[route_backdrops.find(b)],STRATA_SPEED_Y[route_backdrops.find(b)])
func preview_route_screen(index: int, lighting: String="diffuse") -> void:
    if index<0 or index>=route_screens: return
    route_screen=index
    var world_x: float=DISTRICT_START+index*GEN.SCREEN_WIDTH+260.0
    demo.actor.global_position=Vector2(world_x,450.0)
    demo.actor.velocity=Vector2.ZERO
    camera.offset=Vector2.ZERO
    var mat: String=JOINTS.material_at(float(index*GEN.SCREEN_WIDTH+260))
    apply_render_motif(mat,lighting)
    for j in range(r4_lights.size()):
        r4_lights[j].position=Vector2(world_x+(-95 if j==0 else 160),380.0 if j==0 else 330.0)
    # No game-authoritative player movement, checkpoint or spawn content is changed.
    r4_info.text="R4-M01  %s / %s | R2 district | SPAWNS LOCKED"%[mat,lighting]
func route_snapshot() -> Dictionary:
    return {"seed":route_seed,"screens":route_screens,"generator":route.get("generator",""),
        "ground":route["ground"].size(),"pads":route["pads"].size(),"edges":route["edges"].size(),
        "colliders":collision_root.get_child_count(),"visual_terrain_z":terrain.z_index,
        "visual_connector_z":connections.z_index,"actor_z":demo.actor.z_index,
        "strata":route_backdrops.size(),"spawn_gate":placement_gate.duplicate(true),
        "r2_proxy_physics_certified":proxy.get("physics_certified",false),
        "s33_jump_speed":410.0,"s33_gravity":1050.0,"r2_reference_jump_speed":600.0,
        "camera_owner":camera.get_parent()==demo.actor,"reduced_motion":reduce_motion_enabled}

func _unhandled_input(event: InputEvent) -> void:
    super._unhandled_input(event)
    if event is InputEventKey and event.pressed and not event.echo:
        var key: int=event.keycode
        if key>=KEY_F1 and key<=KEY_F4:
            preview_route_screen(key-KEY_F1)
            get_viewport().set_input_as_handled()
