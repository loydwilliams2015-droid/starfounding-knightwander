extends Node2D
## R3-M03 — constrained visual activity around the player.
## Fixtures are grounded in existing StaticBody2D collider geometry; draw only.
const BIOMES := ["stone", "timber", "relicwright", "industrial"]
const NEAR_RADIUS := 260.0
const FAR_RADIUS := 500.0
const NEAR_ACTIVITY_FLOOR := 0.08
const FAR_ACTIVITY_CAP := 1.0
const ACTIVITY_RESPONSE := 8.0
const MAX_DECORATIVE_OPACITY := 0.47
const INDUSTRIAL_RATE := 0.35 # radians/sec at maximum activity
const TIMBER_SWAY := 1.6 # world pixels
const RELIC_PULSE := 0.09 # modulation only

var stage: Node2D
var biome: String = "industrial"
var reduced_motion: bool = false
var phase: float = 0.0
var fixtures: Array[Dictionary] = []
var levels: Array[float] = []
var last_player_x: float = 0.0

func bind_stage(target: Node2D) -> void:
    stage = target
    last_player_x = stage.demo.actor.global_position.x
    fixtures.clear()
    # Read authoritative collision geometry without changing it.
    for child in stage.demo.get_children():
        if not child is StaticBody2D:
            continue
        var collision: CollisionShape2D = null
        for part in child.get_children():
            if part is CollisionShape2D and part.shape is RectangleShape2D:
                collision = part
                break
        if collision == null:
            continue
        var rectangle: RectangleShape2D = collision.shape
        var top_y: float = child.position.y - rectangle.size.y * 0.5
        if absf(top_y-450.0)<0.5 and rectangle.size.x>=850:
            # Bolted access panel below the *existing* ground top, no bridge.
            var x: float = child.position.x + 245.0
            fixtures.append({"anchor":Vector2(x,top_y),"surface_top":top_y,
                "platform_x":child.position.x,"platform_width":rectangle.size.x,"grounded":true,
                "kind":"ground_fastener"})
        elif top_y < 320.0 and rectangle.size.x < 200.0:
            fixtures.append({"anchor":Vector2(child.position.x,top_y),"surface_top":top_y,
                "platform_x":child.position.x,"platform_width":rectangle.size.x,"grounded":false,
                "kind":"underside_support"})
    levels.resize(fixtures.size())
    for k in range(levels.size()):
        levels[k] = 0.0
    queue_redraw()

func set_biome(value: String) -> bool:
    if not BIOMES.has(value):
        return false
    biome = value
    queue_redraw()
    return true

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    queue_redraw()

static func static_activity(distance: float, actor_busy: bool, motion_reduced: bool) -> float:
    if motion_reduced:
        return 0.0
    var t: float = clampf((distance-NEAR_RADIUS)/(FAR_RADIUS-NEAR_RADIUS),0.0,1.0)
    var floor: float = NEAR_ACTIVITY_FLOOR if actor_busy else 0.25
    return lerpf(floor,FAR_ACTIVITY_CAP,t)

func actor_is_busy() -> bool:
    if stage==null or stage.demo==null:
        return false
    return not stage.demo.actor.is_on_floor() or stage.demo.adapter.crouched or absf(stage.demo.actor.velocity.x)>2.0

func predicted_activity(index: int, actor_pos: Vector2, busy: bool) -> float:
    var fixture: Dictionary = fixtures[index]
    return static_activity(fixture["anchor"].distance_to(actor_pos),busy,reduced_motion)

func _process(delta: float) -> void:
    if stage==null or not is_instance_valid(stage.demo.actor):
        return
    var a: Vector2=stage.demo.actor.global_position
    var busy: bool=actor_is_busy()
    phase+=minf(delta,0.1)
    var blend: float = 1.0-exp(-ACTIVITY_RESPONSE * delta)
    for k in range(fixtures.size()):
        var target: float=predicted_activity(k,a,busy)
        levels[k]=lerpf(levels[k],target,blend)
    last_player_x=a.x
    queue_redraw()

func max_angular_speed() -> float:
    return INDUSTRIAL_RATE

func phase_displacement(index: int) -> float:
    if reduced_motion or index<0 or index>=fixtures.size():
        return 0.0
    match biome:
        "timber": return sin(phase*1.1)*TIMBER_SWAY*levels[index]
        "relicwright": return sin(phase*1.4)*RELIC_PULSE*levels[index]
        "industrial": return phase * INDUSTRIAL_RATE * levels[index]
    return 0.0

func snapshot() -> Dictionary:
    var values: Array[float]=[]
    for l in levels: values.append(l)
    return {"biome":biome,"fixtures":fixtures.size(),"levels":values,
        "reduced_motion":reduced_motion,"fixture_kinds":fixtures.map(func(f): return f["kind"]),
        "collision_added":false,"spawn_authority":false,
        "max_opacity":MAX_DECORATIVE_OPACITY,"industrial_rate":INDUSTRIAL_RATE}

func _draw() -> void:
    for k in range(fixtures.size()):
        var f: Dictionary=fixtures[k]
        var pos: Vector2=f["anchor"]
        var level: float=levels[k]
        var muted: Color=Color("8fa6a5",MAX_DECORATIVE_OPACITY)
        var highlight: Color=Color("c6d5c5",MAX_DECORATIVE_OPACITY * 0.85)
        match biome:
            "stone":
                # Fracture stratum, physically on the existing top edge.
                draw_line(pos+Vector2(-24,5),pos+Vector2(26,5),muted,3.0)
                draw_line(pos+Vector2(-12,6),pos+Vector2(-17,18),muted,2.0)
                draw_line(pos+Vector2(14,6),pos+Vector2(21,14),muted,2.0)
            "timber":
                # Stationary timber bracket with small rope tassel motion.
                draw_line(pos+Vector2(-24,6),pos+Vector2(-24,31),muted,4.0)
                draw_line(pos+Vector2(24,6),pos+Vector2(24,31),muted,4.0)
                draw_line(pos+Vector2(-24,29),pos+Vector2(24,6),highlight,3.0)
                draw_line(pos+Vector2(6,7),pos+Vector2(6+phase_displacement(k),25),muted,1.5)
            "relicwright":
                # Anchor and local suspended relic: pulse light; never cross a gap.
                draw_line(pos+Vector2(-18,4),pos+Vector2(18,4),muted,4.0)
                draw_line(pos+Vector2(0,6),pos+Vector2(0,31),muted,2.0)
                var lum: float=0.32+phase_displacement(k)
                draw_circle(pos+Vector2(0,31),8,Color(0.38,0.86,0.82,clampf(lum,0.2,MAX_DECORATIVE_OPACITY)))
                draw_circle(pos+Vector2(0,31),3,highlight)
            "industrial":
                # Fixed axle, anchored to an existing platform underside.
                draw_line(pos+Vector2(-18,5),pos+Vector2(18,5),muted,4.0)
                draw_line(pos+Vector2(0,6),pos+Vector2(0,26),muted,4.0)
                var center: Vector2=pos+Vector2(0,28)
                draw_arc(center,9,0,TAU,20,muted,2.0)
                var phi: float=phase_displacement(k)
                for spoke in range(4):
                    var direction: Vector2=Vector2.RIGHT.rotated(phi+float(spoke)*PI*0.5)
                    draw_line(center,center+direction*7,highlight,1.5)
                draw_circle(center,2,highlight)
