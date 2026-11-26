extends Node2D
## Marker art is observational. No input, collider or authoritative pickups.
var route:Dictionary={}
var native_edge_marks:Dictionary={}
var certificate_valid:=false
var star_preview:Array=[]
var event_preview:Array=[]
func configure(p_route:Dictionary)->void:
    route=p_route
    native_edge_marks.clear()
    certificate_valid=false
    star_preview.clear()
    event_preview.clear()
    queue_redraw()
func show_native_trace(trace:Dictionary,accepted:bool,preview:Dictionary)->void:
    native_edge_marks.clear()
    for edge in trace.get("edges",[]):
        native_edge_marks[int(edge["to"])]=bool(edge.get("passable",false))
    certificate_valid=accepted
    star_preview=preview.get("stars",[])
    event_preview=preview.get("events",[])
    queue_redraw()
func _draw()->void:
    if route.is_empty():return
    for idx in range(route["pads"].size()):
        var pad:Dictionary=route["pads"][idx]
        var p:=Vector2(float(pad["x"]),float(pad["y"])-33.0)
        var c:Color=Color("6f8491",0.45)
        if idx==0:c=Color("b6d5a5",0.78)
        elif native_edge_marks.has(idx):
            c=Color("8bd9bf",0.83) if native_edge_marks[idx] else Color("e18f78",0.88)
        draw_arc(p,6.0,0.0,TAU,16,c,2.0)
    if not certificate_valid:return
    for s in star_preview:
        var p:Vector2=s["world"]-Vector2(4000,0)
        draw_circle(p,5.0,Color("f0d486",0.85))
        draw_circle(p,2.0,Color("fbf3c7"))
    for e in event_preview:
        var p:Vector2=e["world"]-Vector2(4000,0)
        draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),Color("93d3e4",0.8),false,2.0)
