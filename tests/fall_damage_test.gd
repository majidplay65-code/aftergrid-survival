## تست کارکردی headless فاز ۲۵ (سقوط).
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const EXPECTED_CHECK_COUNT: int = 8

var checks_run: int = 0
var failures: int = 0
var last_noise: float = 0.0


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.noise_emitted.connect(_on_noise)
	_run()
	_finish()


func _on_noise(_pos: Vector3, loudness: float) -> void:
	last_noise = loudness


func _run() -> void:
	_check(absf(Player.FALL_DAMAGE_SPEED - 12.0) < 0.01, "آستانه سقوط ۱۲ است")
	_check(absf(Player.HARD_LAND_NOISE - 14.0) < 0.01, "نویز فرود سخت ۱۴ متر است")
	var player: Player = load(PLAYER_PATH).instantiate() as Player
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	root.add_child(player)
	player.stats.health = 80.0
	player.peak_fall_speed = 5.0
	player.land_from_jump()
	_check(absf(player.stats.health - 80.0) < 0.01, "فرود معمولی آسیب نمی‌دهد")
	_check(absf(last_noise - Player.LAND_NOISE) < 0.01, "فرود معمولی نویز ۹ دارد")
	player.peak_fall_speed = 14.0
	player.land_from_jump()
	_check(player.stats.health < 80.0, "فرود سخت آسیب می‌دهد")
	_check(absf(last_noise - Player.HARD_LAND_NOISE) < 0.01, "فرود سخت نویز ۱۴ دارد")
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
