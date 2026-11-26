extends Node2D
## Decorative code only; each visible foothold has separate real StaticBody2D geometry.
var plan: Dictionary={}
func configure(candidate: Dictionary) -> void:
    plan=candidate
    queue_redraw()
func _draw() -> void:
    for rec in plan.get("steps",[]):
        var l: float=rec["x"]-rec["width"]*0.5
        var y: float=rec["top_y"]
        draw_colored_polygon(PackedVector2Array([Vector2(l,y+3),Vector2(l+rec["width"],y+3),
            Vector2(l+rec["width"]-12,y+15),Vector2(l+24,y+18),Vector2(l+4,y+12)]),Color("587f78"))
        draw_line(Vector2(l,y),Vector2(l+rec["width"],y),Color("d5e9ce"),4.0)
        # Structural bolt fixtures (not a free-floating rotating joint)
        for x in [l+13.0,l+rec["width"]-13.0]:
            draw_circle(Vector2(x,y+9.0),2.0,Color("b3bfb2"))
