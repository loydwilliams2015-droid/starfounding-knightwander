extends "res://scripts/r3_m03_fixture_hierarchy.gd"
## R3-M04: leave character physics and authoritative world alone.
## Rendering budget: reduce-motion mode draws a static ornament once.
var draw_calls: int = 0
var paused_updates: int = 0
var active_updates: int = 0
var decoration_cpu_us: int = 0
var last_draw_cpu_us: int = 0
var peak_draw_cpu_us: int = 0

func set_reduced_motion(enabled: bool) -> void:
    if enabled == reduced_motion:
        return
    super.set_reduced_motion(enabled)
    if enabled:
        for k in range(levels.size()):
            levels[k] = 0.0
    # Last active rotation is preserved; static presentation uses a neutral orientation.
    queue_redraw()

func _process(delta: float) -> void:
    if reduced_motion:
        # No phase advance, no redraw per frame: static decorative art.
        paused_updates += 1
        return
    active_updates += 1
    super._process(delta)

func _draw() -> void:
    var t0: int = Time.get_ticks_usec()
    super._draw()
    last_draw_cpu_us = Time.get_ticks_usec() - t0
    decoration_cpu_us += last_draw_cpu_us
    peak_draw_cpu_us = maxi(peak_draw_cpu_us,last_draw_cpu_us)
    draw_calls += 1

func budget_snapshot() -> Dictionary:
    return {"draw_calls":draw_calls,"paused_updates":paused_updates,
        "active_updates":active_updates,"draw_cpu_us_total":decoration_cpu_us,
        "last_draw_cpu_us":last_draw_cpu_us,"peak_draw_cpu_us":peak_draw_cpu_us,
        "reduced_motion":reduced_motion,"phases":phase,
        "collision_added":false,"spawn_authority":false}
