extends RefCounted
## R3-M01: visual-only reference pose and foot-anchor contract.
## Source reference PNGs are carried in standalone ZIP, NOT committed here.
const POSES := ["knight_standing.png", "knight_transition_settle_s22_trial.png",
 "knight_transition_compress_s22_trial.png", "knight_crouching.png"]
const BIOMES := ["stone","timber","relicwright","industrial"]
const FOOT_ANCHOR_Y := 430.0
const SPRITE_WIDTH := 64
static func apply(sprite: Sprite2D, pose_texture: Texture2D, x: float) -> void:
    assert(pose_texture != null and pose_texture.get_width() == SPRITE_WIDTH)
    sprite.texture=pose_texture
    sprite.centered=true
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.region_enabled=false
    sprite.offset=Vector2(0,-float(pose_texture.get_height())*0.5)
    sprite.scale=Vector2.ONE
    sprite.position=Vector2(x,FOOT_ANCHOR_Y)
static func validate(sprite: Sprite2D, pose_texture: Texture2D) -> bool:
    return sprite.texture==pose_texture and sprite.centered and not sprite.region_enabled \
        and sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST \
        and sprite.offset.is_equal_approx(Vector2(0,-float(pose_texture.get_height())*0.5)) \
        and sprite.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(sprite.position.y,FOOT_ANCHOR_Y)
