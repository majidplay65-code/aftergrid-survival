## تست کارکردی headless فاز ۲۵ (سقوط).
##
## نکته: land_from_jump از global_position نویز emit می‌کند و global_position فقط بعد از
## ورود به درخت معتبر است؛ در حالت -s این از نخستین فریم به بعد برقرار می‌شود. برای همین
## چک‌ها در _process() و بعد از چند فریم انجام می‌شوند (الگوی tests/inventory_wiring_test.gd).
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const PLAYER_SCRIPT: String = "res://entities/player/player.gd"
const EXPECTED_CHECK_COUNT: int = 8

var checks_run: int = 0
var failures: int = 0
var last_noise: float = 0.0
var frame: int = 0
var started: bool = false
var player: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	var event_bus: Variant = root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.noise_emitted.connect(_on_noise)
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


func _on_noise(_pos: Vector3, loudness: float) -> void:
	last_noise = loudness


func _run() -> void:
	var player_script: Variant = load(PLAYER_SCRIPT)
	_check(absf(player_script.FALL_DAMAGE_SPEED - 12.0) < 0.01, "آستانه سقوط ۱۲ است")
	_check(absf(player_script.HARD_LAND_NOISE - 14.0) < 0.01, "نویز فرود سخت ۱۴ متر است")
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	player.stats.health = 80.0
	player.peak_fall_speed = 5.0
	player.land_from_jump()
	_check(absf(player.stats.health - 80.0) < 0.01, "فرود معمولی آسیب نمی‌دهد")
	_check(absf(last_noise - player_script.LAND_NOISE) < 0.01, "فرود معمولی نویز ۹ دارد")
	player.peak_fall_speed = 14.0
	player.land_from_jump()
	_check(player.stats.health < 80.0, "فرود سخت آسیب می‌دهد")
	_check(absf(last_noise - player_script.HARD_LAND_NOISE) < 0.01, "فرود سخت نویز ۱۴ دارد")
	player.free()


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
		[&"InventoryManager", "res://core/inventory/inventory_manager.gd"],
		[&"CraftingSystem", "res://core/crafting/crafting_system.gd"],
	]
	for pair in ordered:
		var n: StringName = pair[0]
		if not root.has_node(NodePath(n)):
			var node: Node = load(pair[1]).new()
			node.name = n
			root.add_child(node)


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
		print("ALL TESTS PASSED (fall damage)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
