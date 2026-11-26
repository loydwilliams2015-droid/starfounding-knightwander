extends "res://scripts/r4_m01_stage.gd"
## R4-M02 additive real access footholds, occlusion-safe camera diagnostics.
const ACCESS=preload("res://scripts/r4_m02_access.gd")
const ACCESS_ART=preload("res://scripts/r4_m02_access_art.gd")
const VIS=preload("res://scripts/r4_m02_visibility.gd")
var ascent_plan: Dictionary={}
var ascent_bodies: Node2D
var ascent_art: Node2D
var access_verified := false
var visibility_guard_enabled := true
func _ready() -> void:
    super._ready()
    # Keep this a dedicated test layer rather than mutating R2's base generator.
    ascent_plan=ACCESS.design(route)
    assert(ACCESS.validate(ascent_plan,route)["passed"])
    ascent_bodies=Node2D.new()
    ascent_bodies.name="S33NativeAscentFootholds"
    ascent_bodies.position=Vector2(DISTRICT_START,0)
    demo.add_child(ascent_bodies)
    for rec in ascent_plan["steps"]:
        var body:=StaticBody2D.new()
        body.name="S33Step%02d"%int(rec["index"])
        body.position=Vector2(rec["x"],rec["y"])
        body.collision_layer=1
        body.collision_mask=0
        ascent_bodies.add_child(body)
        var collision:=CollisionShape2D.new()
        var shape:=RectangleShape2D.new()
        shape.size=Vector2(rec["width"],rec["height"])
        collision.shape=shape
        collision.one_way_collision=true
        body.add_child(collision)
    ascent_art=Node2D.new()
    ascent_art.name="AscentFootholdArt"
    ascent_art.position=Vector2(DISTRICT_START,0)
    ascent_art.z_index=0
    ascent_art.set_script(ACCESS_ART)
    demo.add_child(ascent_art)
    ascent_art.configure(ascent_plan)
    placement_gate["blocked"]=true
    placement_gate["items"]=[]
    placement_gate["events"]=[]
    placement_gate["reason"]="first-pad ascent footholds are QA-only; full chain not certified"
    r4_info.text="R4-M02 / native footholds | ALL GAMEPLAY SPAWNS LOCKED"
func preview_route_screen(index: int, lighting: String="diffuse") -> void:
    super.preview_route_screen(index,lighting)
    if is_instance_valid(r4_info) and index>=0 and index<route_screens:
        r4_info.text="R4-M02 %s / %s | S33 ascent QA | ALL SPAWNS LOCKED"%[JOINTS.material_at(float(index*GEN.SCREEN_WIDTH+260)),lighting]

func configure_camera_review(zoom_level: float, vertical_offset: float, horizontal_offset: float=0.0) -> void:
    # Camera only: no actor displacement or physics writes.
    camera.zoom=Vector2.ONE*clampf(zoom_level,0.80,1.35)
    set_s32_auto_camera_tracking(false)
    camera.offset=Vector2(horizontal_offset,vertical_offset)
    set_surface_separation(true)
func reset_camera_review() -> void:
    camera.zoom=Vector2.ONE
    set_s32_auto_camera_tracking(true)
func visibility_snapshot() -> Dictionary:
    return VIS.evaluate(self)
func ascent_snapshot() -> Dictionary:
    var native: Array[Dictionary]=[]
    for body in ascent_bodies.get_children():
        var collider: CollisionShape2D=body.get_child(0)
        native.append({"center":body.position,"width":collider.shape.size.x,
            "height":collider.shape.size.y,"top":body.position.y-collider.shape.size.y*0.5,
            "one_way":collider.one_way_collision})
    return {"plan":ascent_plan,"native":native,"s33_jump_unchanged":true,
        "content_blocked":placement_gate["blocked"],"items":placement_gate["items"].size(),
        "events":placement_gate["events"].size(),"ascent_verified":access_verified}
