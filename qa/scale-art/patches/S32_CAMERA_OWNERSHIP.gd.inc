## Append to scripts/sk_s25_stage.gd in the S31 standalone QA project.
## S32: explicit transition from manual diagnostics to normal player-follow
## camera ownership. Idempotent; leaves world geometry and actor unchanged.
func set_s32_auto_camera_tracking(enabled: bool) -> void:
    if enabled:
        s29_lookahead_enabled = true
        s30_vertical_enabled = true
        s27_camera_phase = 0.0
        # Clear stale manual offsets; the next physics frame owns both axes.
        s29_lookahead_x = 0.0
        s30_vertical_offset = 0.0
        camera.offset = Vector2.ZERO
    else:
        s29_lookahead_enabled = false
        s30_vertical_enabled = false

func s32_camera_ownership_snapshot() -> Dictionary:
    return {
        "auto_horizontal": s29_lookahead_enabled,
        "auto_vertical": s30_vertical_enabled,
        "manual_phase": s27_camera_phase,
        "offset": camera.offset,
        "actor_position": demo.actor.global_position,
        "parallax_count": background_layers.size()
    }
