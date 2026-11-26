extends "res://scripts/r3_m03_stage.gd"
## Accessibility QA: keyboard + mouse control; session-scoped and reversible.
const M04_FIXTURE = preload("res://scripts/r3_m04_fixture_hierarchy.gd")
var motion_checkbox: CheckButton
var motion_status: Label
var motion_ui: CanvasLayer
var reduce_motion_enabled: bool = false
var original_parallax: Array[Vector2] = []

func _ready() -> void:
    super._ready()
    # Replace ONLY the independent decorative layer; never replace the knight.
    var obsolete: Node2D = fixtures
    demo.remove_child(obsolete)
    obsolete.queue_free()
    fixtures = Node2D.new()
    fixtures.name = "R3M04MotionBudgetFixtures"
    fixtures.set_script(M04_FIXTURE)
    fixtures.z_index = 2
    demo.add_child(fixtures)
    fixtures.bind_stage(self)
    set_r3_biome("industrial")
    for p in background_layers:
        original_parallax.append(p.scroll_scale)
    motion_ui = CanvasLayer.new()
    motion_ui.name = "R3M04AccessibilityControls"
    add_child(motion_ui)
    motion_checkbox = CheckButton.new()
    motion_checkbox.name = "ReduceMotionToggle"
    motion_checkbox.text = "Reduce motion [M]"
    motion_checkbox.position = Vector2(736,12)
    motion_checkbox.custom_minimum_size = Vector2(218,32)
    motion_checkbox.add_theme_font_size_override("font_size",13)
    motion_checkbox.tooltip_text = "Stop decorative movement, freeze parallax, and disable camera anticipation. Knight controls remain active."
    motion_ui.add_child(motion_checkbox)
    motion_checkbox.toggled.connect(_on_reduce_motion_toggled)
    motion_status = Label.new()
    motion_status.name = "AccessibilityStatus"
    motion_status.position = Vector2(739,47)
    motion_status.add_theme_font_size_override("font_size",11)
    motion_status.add_theme_color_override("font_color",Color("d7ecd4"))
    motion_ui.add_child(motion_status)
    _apply_reduce_motion(false)
    for ui_node in get_children():
        if ui_node is CanvasLayer and ui_node != motion_ui:
            for label_node in ui_node.get_children():
                if label_node is Label and "STARFOUNDING" in label_node.text:
                    label_node.text = "STARFOUNDING KNIGHTWANDER / R3-M04 motion and performance QA"

func _on_reduce_motion_toggled(value: bool) -> void:
    _apply_reduce_motion(value)

func set_reduced_motion(value: bool) -> void:
    # Set button state so both interaction paths use the same signal.
    if motion_checkbox.button_pressed != value:
        motion_checkbox.button_pressed = value
    else:
        _apply_reduce_motion(value)

func _apply_reduce_motion(value: bool) -> void:
    reduce_motion_enabled = value
    fixtures.set_reduced_motion(value)
    for k in range(background_layers.size()):
        background_layers[k].scroll_scale = Vector2.ZERO if value else original_parallax[k]
    if value:
        set_s32_auto_camera_tracking(false)
        camera.offset = Vector2.ZERO
    else:
        set_s32_auto_camera_tracking(true)
    motion_status.text = "Decorative motion: OFF | parallax: STATIC" if value else "Decorative motion: ON | parallax: ACTIVE"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and not event.is_ctrl_pressed() and event.keycode == KEY_M:
        set_reduced_motion(not reduce_motion_enabled)
        get_viewport().set_input_as_handled()

func motion_snapshot() -> Dictionary:
    var scales: Array[Vector2] = []
    for p in background_layers:
        scales.append(p.scroll_scale)
    return {"reduced":reduce_motion_enabled,"checked":motion_checkbox.button_pressed,
        "camera_follow":camera.get_parent() == demo.actor,
        "horizontal_anticipation":s29_lookahead_enabled,
        "vertical_anticipation":s30_vertical_enabled,
        "parallax_scales":scales,"decorative":fixtures.budget_snapshot(),
        "actor_physics_steps":demo.physics_steps,
        "collision_added":false,"spawn_authority":false}
