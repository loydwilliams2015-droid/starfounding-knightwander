extends Node2D
## R2-M02 physics-bearing route QA; does not modify S33.
const GEN = preload("res://scripts/r2_route_generator.gd")
var route: Dictionary
var player: CharacterBody2D
var world: Node2D
var camera: Camera2D
var screen_index := 0
var debug_seed := 41
var route_screens := 5
const WALK_SPEED := 230.0
const JUMP_SPEED := -600.0
const GRAVITY := 1100.0
const BODY_RADIUS := 13.0

func _ready() -> void:
    build(debug_seed, route_screens)

func build(seed: int, screens: int) -> void:
    if is_instance_valid(world):
        world.queue_free()
        world = null
    route = GEN.generate(seed, screens)
    assert(GEN.validate(route)["passed"])
    world = Node2D.new()
    world.name = "RouteColliders"
    add_child(world)
    for i in range(route["ground"].size()):
        var ground: Dictionary = route["ground"][i]
        make_solid("Ground%02d" % i, ground, false)
    for i in range(route["pads"].size()):
        var pad: Dictionary = route["pads"][i]
        make_solid("OneWayPad%02d" % i, pad, true)
    player = CharacterBody2D.new()
    player.name = "PhysicsProbe"
    player.collision_layer = 2
    player.collision_mask = 1
    player.floor_snap_length = 5.0
    player.position = route["spawn"]
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = BODY_RADIUS
    capsule.height = 64.0
    collision.shape = capsule
    player.add_child(collision)
    world.add_child(player)
    camera = Camera2D.new()
    camera.name = "PreviewCamera"
    camera.position = Vector2(480, 270)
    camera.enabled = true
    add_child(camera)
    queue_redraw()

func make_solid(body_name: String, item: Dictionary, one_way: bool) -> void:
    var body := StaticBody2D.new()
    body.name = body_name
    body.collision_layer = 1
    body.collision_mask = 2
    body.position = Vector2(item["x"],item["y"])
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(item["width"],item["height"])
    shape.shape = rect
    shape.one_way_collision = one_way
    body.add_child(shape)
    world.add_child(body)

func simulate_motion(horizontal: float, jumping: bool, delta: float) -> void:
    if player.is_on_floor() and jumping:
        player.velocity.y = JUMP_SPEED
    else:
        player.velocity.y += GRAVITY * delta
    player.velocity.x = horizontal * WALK_SPEED
    player.move_and_slide()

func _physics_process(delta: float) -> void:
    var axis := Input.get_axis("ui_left", "ui_right")
    simulate_motion(axis, Input.is_action_just_pressed("ui_accept"), delta)
    screen_index = clampi(int(player.position.x / GEN.SCREEN_WIDTH),0,route_screens-1)
    camera.position = Vector2(float(screen_index*GEN.SCREEN_WIDTH)+480,270)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0,0,route["width"],540),Color("172733"))
    for k in route["ground"]:
        draw_rect(Rect2(k["x"]-k["width"]*0.5,k["y"]-k["height"]*0.5,k["width"],k["height"]),Color("50646a"))
        draw_line(Vector2(k["x"]-k["width"]*0.5,450),Vector2(k["x"]+k["width"]*0.5,450),Color("b8c9ad"),4)
    for pad in route["pads"]:
        draw_rect(Rect2(pad["x"]-pad["width"]*0.5,pad["y"]-9,pad["width"],18),Color("93a5a1"))
        draw_line(Vector2(pad["x"]-pad["width"]*0.5,pad["y"]-9),Vector2(pad["x"]+pad["width"]*0.5,pad["y"]-9),Color("d9e5c7"),3)
    if is_instance_valid(player):
        draw_rect(Rect2(player.position.x-13,player.position.y-32,26,64),Color("f2bc73"))
        draw_circle(player.position+Vector2(0,-13),6,Color("35686d"))
