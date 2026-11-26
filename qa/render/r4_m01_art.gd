extends Node2D
## R4-M01 raster-only layers. The R2 generated collider tree is separate.
## Variant: 0 ground/pad silhouettes; 1 contextual suspended fixtures; 2 backdrop.
var variant: int = 0
var route: Dictionary = {}
var surfaces: Array[Dictionary] = []
var joints: Array[Dictionary] = []
var backdrop_band: int = 0
var reduced_motion: bool = false
var time_s: float = 0.0
var draws: int = 0
func configure(p_route: Dictionary, p_surfaces: Array[Dictionary], p_joints: Array[Dictionary], p_variant: int, p_band: int = 0) -> void:
    route = p_route
    surfaces = p_surfaces
    joints = p_joints
    variant = p_variant
    backdrop_band = p_band
    queue_redraw()
func set_reduced_motion(value: bool) -> void:
    reduced_motion=value
    queue_redraw()
func _process(delta: float) -> void:
    if variant == 1 and not reduced_motion:
        time_s = fposmod(time_s + minf(delta,0.05),TAU*10.0)
        queue_redraw()
func _draw() -> void:
    draws += 1
    if route.is_empty(): return
    match variant:
        0: _draw_surfaces()
        1: _draw_attachments()
        2: _draw_backdrop()
func _draw_surfaces() -> void:
    for g in route["ground"]:
        var left: float = float(g["x"])-float(g["width"])*0.5
        var top: float = float(g["y"])-float(g["height"])*0.5
        draw_rect(Rect2(left,top,float(g["width"]),float(g["height"])),Color("34474b"))
        draw_line(Vector2(left,top),Vector2(left+float(g["width"]),top),Color("b8d2b3"),3.0)
    for surf in surfaces:
        var l: float=surf["left_x"]
        var r: float=surf["right_x"]
        var y: float=surf["top_y"]
        var material: String=surf["biome"]
        if material=="stone":
            draw_colored_polygon(PackedVector2Array([Vector2(l,y+3),Vector2(r,y+3),Vector2(r-14,y+27),Vector2(l+42,y+31),Vector2(l+6,y+18)]),Color("5c8077"))
            for k in range(3):
                draw_line(Vector2(l+30+k*50,y+8),Vector2(l+42+k*50,y+21),Color("3e5e62"),2.0)
            draw_line(Vector2(l,y+1),Vector2(r,y+1),Color("ccdbb8"),4.0)
        elif material=="timber":
            draw_rect(Rect2(l,y+2,r-l,24),Color("735343"))
            for k in range(8):
                var x: float=l+float(k)*((r-l)/8.0)
                draw_line(Vector2(x,y+4),Vector2(x,y+24),Color("403a37"),2)
                draw_circle(Vector2(x+6,y+9),2,Color("d9b57d"))
            draw_line(Vector2(l,y+1),Vector2(r,y+1),Color("e0c78e"),4.0)
        elif material=="relicwright":
            draw_rect(Rect2(l,y+2,r-l,22),Color("55687c"))
            for k in range(4):
                var x: float=l+10+k*45.0
                draw_rect(Rect2(x,y+8,29,9),Color("7393a1"))
                draw_line(Vector2(x+3,y+12),Vector2(x+25,y+12),Color("9fdfd0"),1.5)
            draw_line(Vector2(l,y+1),Vector2(r,y+1),Color("b5e9d4"),4.0)
        else:
            draw_rect(Rect2(l,y+2,r-l,22),Color("4e6372"))
            for k in range(12):
                var x: float=l+5+k*16.0
                draw_line(Vector2(x,y+6),Vector2(x+9,y+19),Color("889da7"),2)
            draw_line(Vector2(l,y+1),Vector2(r,y+1),Color("cbd9d1"),4.0)
        if surf["weathered"]:
            draw_line(Vector2(l+50,y+7),Vector2(l+61,y+18),Color("293c42"),1.7)
        if not surf["link_ok"]:
            draw_line(Vector2(r-9,y+6),Vector2(r-4,y+19),Color("de8670"),2.4)
func _draw_attachments() -> void:
    for j in joints:
        var a: Vector2=j["a"]
        var b: Vector2=j["b"]
        var kind: String=j["kind"]
        var tone: Color=Color("9daeb0",0.48)
        if kind=="end_caps":
            for p in [a,b]:
                draw_rect(Rect2(p-Vector2(13,4),Vector2(26,8)),Color("4a5a60",0.6))
                draw_circle(p,2.4,Color("dca27c",0.9))
        elif kind=="stone_strata":
            for p in [a,b]:
                draw_colored_polygon(PackedVector2Array([p+Vector2(-18,1),p+Vector2(18,1),p+Vector2(13,15),p+Vector2(-12,18)]),Color("647b73"))
        elif kind.begins_with("timber"):
            for p in [a,b]:
                draw_line(p+Vector2(-18,0),p+Vector2(0,21),Color("a7805c"),7)
                draw_line(p+Vector2(18,0),p+Vector2(0,21),Color("805d49"),7)
                draw_circle(p,3.0,Color("d5b389"))
            if kind=="timber_lintel":
                draw_line(a+Vector2(0,13),b+Vector2(0,13),Color("916b50"),5)
        else:
            for p in [a,b]:
                draw_rect(Rect2(p-Vector2(12,5),Vector2(24,10)),Color("536c78"))
                draw_circle(p,3,Color("bdd7cb"))
            if kind=="steel_hinge":
                draw_line(a,b,tone,6)
                var pivot: Vector2=a.lerp(b,0.5)
                draw_arc(pivot,9,0,TAU,20,Color("a3b4b0",0.72),2)
                for k in range(4):
                    var phase: float=0.0 if reduced_motion else time_s*0.31
                    draw_line(pivot,pivot+Vector2.RIGHT.rotated(phase+k*PI*0.5)*7,Color("bfd0c1",0.7),1.7)
            else:
                var pts := PackedVector2Array()
                for idx in range(21):
                    var u: float=float(idx)/20.0
                    var sag: float=14.0+(0.0 if reduced_motion else 0.7*sin(time_s+float(j["from"])))
                    pts.append(a.lerp(b,u)+Vector2(0,sag*sin(PI*u)))
                draw_polyline(pts,tone,3.0,true)
func _draw_backdrop() -> void:
    var width: float=float(route["width"])
    if backdrop_band==0:
        draw_rect(Rect2(-120,-700,width+240,1120),Color("142336",0.82))
        for i in range(85):
            var x: float=40.0+float(posmod(i*257, int(width)))
            var y: float=-350.0+float(posmod(i*67,190))
            draw_circle(Vector2(x,y),1.2,Color("b8cbca",0.5))
    elif backdrop_band==1:
        var polygon := PackedVector2Array([Vector2(-60,445)])
        for i in range(int(width/120)+3):
            var x: float=-60.0+i*120.0
            polygon.append(Vector2(x,165.0+sin(i*0.89)*80))
        polygon.append(Vector2(width+180,445))
        draw_colored_polygon(polygon,Color("253e50",0.83))
    elif backdrop_band==2:
        for i in range(int(width/90)+1):
            var x: float=i*90.0
            var h: float=150.0+float(posmod(i*37,125))
            draw_rect(Rect2(x,365-h,72,h),Color("355265",0.55))
            draw_rect(Rect2(x+12,365-h+40,10,13),Color("c2b48b",0.35))
    else:
        for i in range(int(width/105)+1):
            var x: float=i*105.0
            draw_line(Vector2(x,418),Vector2(x+15,340),Color("3d615d",0.48),5)
            draw_circle(Vector2(x+15,325),26.0,Color("446963",0.33))
