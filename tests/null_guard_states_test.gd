## تست کارکردی headless (null guard):
## @export var player: Player در ۷ حالتِ Player می‌تواند null/unset بماند
## (مثلاً state ای که بدون صحنه، مستقیم با .new() ساخته می‌شود). در آن حالت
## enter() و physics_update() نباید crash کنند: warning چاپ می‌شود و مسیر
## fallback امن اجرا می‌شود (هیچ دسترسی به player، هیچ transition).
## کنترل مثبت (بخش ۲) ثابت می‌کند guard در صحنه‌ی واقعی
## (player.tscn، player = NodePath("../..")) اشتبالی نمی‌زند.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/null_guard_states_test.gd
##
## نکته: crash در Godot 4 به شکل SCRIPT ERROR با قطعِ همان تابع ظاهر می‌شود؛
## بنابراین اگر guard نباشد، چک‌های همان بخش اجرا نمی‌شوند و چکِ متا
## (تعداد چک‌ها) در _finish شکست می‌خورد + خط SCRIPT ERROR گارد CI را
## می‌شکند.
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const EXPECTED_CHECK_COUNT: int = 26

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var player: Variant = null


func _initialize() -> void:
	player = load(PLAYER_PATH).instantiate()
	if player != null:
		root.add_child(player)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	# ── ۱) سناریوی منفی: state ای که مستقیم ساخته شده و player آن null است ──
	var state_paths: Array = [
		["res://entities/player/states/idle_state.gd", "IdleState"],
		["res://entities/player/states/walk_state.gd", "WalkState"],
		["res://entities/player/states/run_state.gd", "RunState"],
		["res://entities/player/states/crouch_state.gd", "CrouchState"],
		["res://entities/player/states/jump_state.gd", "JumpState"],
		["res://entities/player/states/melee_state.gd", "MeleeState"],
		["res://entities/player/states/dead_state.gd", "DeadState"],
	]
	var all_loaded: bool = true
	for pair in state_paths:
		var script: Variant = load(str(pair[0]))
		if script == null:
			all_loaded = false
	_check(all_loaded, "همه‌ی ۷ اسکریپت state بارگذاری می‌شوند")

	for pair in state_paths:
		var label: String = str(pair[1])
		var script: Variant = load(str(pair[0]))
		var st: Variant = script.new() if script != null else null
		_check(st != null and st.player == null,
				label + ": در state جدید، خروجی player واقعاً null است (پیش‌شرط)")
		if st == null:
			continue
		# با player null نباید crash کند؛ guard باید fallback امن را اجرا کند.
		st.enter({})
		st.physics_update(0.016)
		_check(st.player_missing == true,
				label + ": بعد از فراخوانی با player=null، player_missing = true (fallback اجرا شد)")
		_check(st._player_missing_warned == true,
				label + ": warning یک‌بار چاپ شده")
		st.free()

	# ── ۲) کنترل مثبت: در صحنه‌ی واقعی guard نباید اشتبالی بزند ──
	_check(player != null, "بازیکن از player.tscn instantiate شد")
	if player == null:
		return
	var walk: Variant = player.get_node_or_null("StateMachine/WalkState")
	_check(walk != null and walk.player != null,
			"WalkState در صحنه‌ی واقعی player غیر-null دارد (سیم‌بندی درست است)")
	if walk != null:
		walk.physics_update(0.016)
		_check(walk.player_missing == false,
				"در صحنه‌ی واقعی guard اشتبالی نمی‌زند (player_missing همچنان false)")
	player.free()


func _check(ok: bool, label: String) -> void:
	checks_run += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (null guard states)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
