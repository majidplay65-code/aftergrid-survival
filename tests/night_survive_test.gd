## تست کارکردی headless فاز ۲۲ (برد شب).
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 9

var checks_run: int = 0
var failures: int = 0
var heard_index: int = -1


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.night_survived.connect(_on_survived)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	GameState.night_index = 1
	var packed: PackedScene = load(LEVEL_PATH)
	var level: Node = packed.instantiate()
	root.add_child(level)
	_run(level)
	_finish()


func _on_survived(night_index: int) -> void:
	heard_index = night_index


func _run(level: Node) -> void:
	var cycle: Node = level.get_node_or_null("DayCycle")
	_check(cycle != null, "DayCycle موجود است")
	if cycle == null:
		return
	cycle.call("set_time_of_day", 0.19)
	_check(heard_index == -1, "قبل از سپیده night_survived نیست")
	cycle.call("set_time_of_day", 0.26)
	_check(heard_index == 1, "عبور از سپیده night_survived(1) می‌دهد")
	_check(GameState.night_index == 2, "night_index بعد از شب ۱ به ۲ می‌رسد")
	var hud: HUD = level.get_node_or_null("HUD") as HUD
	_check(hud != null, "HUD موجود است")
	if hud != null:
		_check(hud.survive_panel != null and hud.survive_panel.visible,
				"پنل زنده ماندی نمایان است")
		_check(hud.night_label != null, "برچسب شب روی HUD هست")
	var data: SaveData = SaveData.new()
	_check(data.night_index == 1, "سیو قدیمی night_index پیش‌فرض ۱ دارد")


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
		print("ALL TESTS PASSED (night survive)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
