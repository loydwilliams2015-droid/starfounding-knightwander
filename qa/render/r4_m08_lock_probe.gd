extends SceneTree
const OUTBOX = preload("res://scripts/r4_m08_outbox.gd")
func run() -> void:
    var args: Array = OS.get_cmdline_user_args()
    var mode: String = str(args[0]) if args.size() > 0 else "expect_acquire"
    var name: String = str(args[1]) if args.size() > 1 else "r4m08_process_lock"
    var box = OUTBOX.new()
    box.configure(name)
    var first: Dictionary = box.acquire_writer()
    if mode == "hold":
        if not first.get("passed", false): quit(2); return
        var ready: FileAccess = FileAccess.open("res://reports/R4_M08_LOCK_READY.json", FileAccess.WRITE)
        if ready == null: quit(3); return
        ready.store_string(JSON.stringify({"ready":true,"owner":box.lock_token,"folder":box.folder})+"\n")
        ready.flush()
        ready.close()
        print("R4_M08_LOCK_HOLDER_READY")
        while true: await process_frame
    if mode == "expect_denied":
        var denied: bool = not first.get("passed", false)
        print("R4_M08_LOCK_RESULT denied=",denied)
        quit(0 if denied else 4)
        return
    if mode == "expect_acquire":
        if not first.get("passed", false): quit(5);return
        var released: bool = box.release_writer()
        print("R4_M08_LOCK_RESULT acquired=",first["passed"]," released=",released)
        quit(0 if released else 6)
        return
    quit(7)
func _initialize() -> void: call_deferred("run")
