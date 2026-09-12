## تست کارکردی headless فاز ۲۱ (چرخه شب):
## WorldClock Resource، DayCycle، تاریکی نیمه‌شب، سیگنال EventBus.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0
var heard_time: float = -1.0


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.time_of_day_changed.connect(_on_time)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	var packed: PackedScene = load(LEVEL_PATH)
	var level: Node = packed.instantiate()
	root.add_child(level)
	_run(level)
	_finish()


func _on_time(normalized: float) -> void:
	heard_time = normalized


func _run(level: Node) -> void:
	var clock: WorldClock = WorldClock.new()
	_check(clock != null, "WorldClock ساخته می‌شود")
	clock.time_of_day = 0.80
	_check(clock.is_night(), "t=۰.۸۰ شب است")
	_check(clock.night_factor() > 0.9, "نیمه‌شب night_factor نزدیک ۱ است")
	clock.time_of_day = 0.40
	_check(not clock.is_night(), "t=۰.۴۰ روز/گرگ‌ومیش است")
	_check(clock.night_factor() < 0.01, "روز night_factor صفر است")
	var cycle: Node = level.get_node_or_null("DayCycle")
	_check(cycle != null, "DayCycle در سطح هست")
	if cycle == null:
		return
	cycle.call("set_time_of_day", 0.80)
	_check(absf(heard_time - 0.80) < 0.001, "time_of_day_changed در ۰.۸۰ emit شد")
	var world_env: WorldEnvironment = level.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_check(world_env != null and world_env.environment != null, "WorldEnvironment موجود است")
	if world_env != null and world_env.environment != null:
		_check(world_env.environment.ambient_light_energy < 0.2,
				"نیمه‌شب ambient زیر ۰.۲ است")
	cycle.call("set_time_of_day", 0.40)
	if world_env != null and world_env.environment != null:
		_check(world_env.environment.ambient_light_energy > 0.4,
				"روز ambient نزدیک ۰.۵ است")
	var sun: DirectionalLight3D = level.get_node_or_null("Sun") as DirectionalLight3D
	_check(sun != null, "خورشید در صحنه هست")


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
		print("ALL TESTS PASSED (day cycle)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
