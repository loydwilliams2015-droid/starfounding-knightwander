extends SceneTree
const GEN = preload("res://qa/map/r2_m01_route_generator.gd")
var checks := 0
var failures := 0
func check(ok: bool, explanation: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(explanation)
func run() -> void:
    for screens in [4,5,6]:
        for seed in range(100):
            var a: Dictionary = GEN.generate(seed,screens)
            var b: Dictionary = GEN.generate(seed,screens)
            var v: Dictionary = GEN.validate(a)
            check(a["valid"],"generation")
            check(v["passed"],"reachability")
            check(a==b,"replay")
            check(v["reachable_nodes"]==screens*5,"graph connectivity")
            check(a["ground"].size()==screens,"ground continuity")
    check(not GEN.generate(77,3)["valid"],"reject 3 screens")
    check(not GEN.generate(77,7)["valid"],"reject 7 screens")
    var bad: Dictionary = GEN.generate(22,5)
    bad["pads"][3]["x"]+=500
    check(not GEN.validate(bad)["passed"],"reject tampered route")
    print("R2_M01_RESULT checks=",checks," failures=",failures," seeds=300")
    quit(0 if failures==0 else 1)
func _initialize() -> void:
    call_deferred("run")
