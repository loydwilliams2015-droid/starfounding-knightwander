extends RefCounted
## R3-M02 reversible environmental contrast, no authoritative gameplay writes.
const BIOMES := ["stone","timber","relicwright","industrial"]
const TINTS := [Color("a6beb0"),Color("c9aa88"),Color("72bbbb"),Color("bdc9cd")]
static func set_biome(stage: Node2D, biome: String, enabled: bool = true) -> bool:
    var ix: int = BIOMES.find(biome)
    if ix < 0: return false
    stage.set_readability_mode(enabled)
    stage.set_surface_separation(enabled)
    var base: Color = TINTS[ix]
    stage.background_layers[1].modulate = Color(base.r,base.g,base.b,1.0) if enabled else Color.WHITE
    return true
static func snapshot(stage: Node2D) -> Dictionary:
    return {"actor":stage.demo.actor.global_position,
        "crouched":stage.demo.adapter.crouched,
        "art_valid":stage.demo.art_driver.is_visual_valid(),
        "geometry_valid":stage.demo.adapter.pose_geometry_verified(),
        "camera_offset":stage.camera.offset,
        "layers":stage.background_layers.size(),
        "sprite_alpha":stage.demo.adapter.visual.modulate.a,
        "foreground_alpha":stage.foreground.modulate.a}
