## تست کارکردی headless فاز ۲۷ (رادیو شرق).
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 9

var checks_run: int = 0
var failures: int = 0
var heard_radio: bool = false


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.radio_activated.connect(_on_radio)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	GameState.radio_is_on = false
	var packed: PackedScene = load(LEVEL_PATH)
	var level: Node = packed.instantiate()
	root.add_child(level)
	_run(level)
	_finish()


func _on_radio() -> void:
	heard_radio = true


func _run(level: Node) -> void:
	var radio: RadioBeacon = level.get_node_or_null("RadioBeacon") as RadioBeacon
	_check(radio != null, "RadioBeacon در سطح هست")
	var player: Player = level.get_node_or_null("Player") as Player
	_check(player != null, "بازیکن موجود است")
	if radio == null or player == null:
		return
	_check(radio.global_position.x > 20.0, "رادیو در شرق نقشه است")
	var inv: Variant = root.get_node_or_null("InventoryManager")
	radio.interact(player)
	_check(not heard_radio, "بدون قراضه فعال نمی‌شود")
	inv.add_item(&"scrap_metal", 1)
	radio.interact(player)
	_check(heard_radio, "با قراضه radio_activated می‌آید")
	_check(GameState.radio_is_on, "GameState.radio_is_on روشن است")
	_check(inv.count_item(&"scrap_metal") == 0, "یک قراضه مصرف شد")
	heard_radio = false
	radio.interact(player)
	_check(not heard_radio, "فعال‌سازی دوباره سیگنال نمی‌دهد")


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
		print("ALL TESTS PASSED (radio beacon)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
