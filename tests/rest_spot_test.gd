## تست کارکردی headless فاز ۲۳ (پناه / استراحت).
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 8

var checks_run: int = 0
var failures: int = 0
var heard_rest: bool = false


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.rest_requested.connect(_on_rest)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	var packed: PackedScene = load(LEVEL_PATH)
	var level: Node = packed.instantiate()
	root.add_child(level)
	_run(level)
	_finish()


func _on_rest(_skip: float) -> void:
	heard_rest = true


func _run(level: Node) -> void:
	var shop: Node = level.get_node_or_null("SafeShop")
	_check(shop != null, "SafeShop موجود است")
	if shop == null:
		return
	var rest: RestSpot = shop.get_node_or_null("RestSpot") as RestSpot
	_check(rest != null, "RestSpot داخل فروشگاه هست")
	var player: Player = level.get_node_or_null("Player") as Player
	_check(player != null, "بازیکن موجود است")
	if rest == null or player == null:
		return
	player.stats.hunger = 40.0
	player.stats.thirst = 40.0
	rest.interact(player)
	_check(heard_rest, "rest_requested از EventBus آمد")
	_check(player.stats.hunger > 40.0, "استراحت گرسنگی را برمی‌گرداند")
	_check(player.stats.thirst > 40.0, "استراحت تشنگی را برمی‌گرداند")
	_check(absf(rest.time_skip - 0.08) < 0.001, "پرش زمان ۰.۰۸ است")


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
		print("ALL TESTS PASSED (rest spot)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
