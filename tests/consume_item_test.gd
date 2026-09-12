## تست کارکردی headless فاز ۱۳ (Consume from Inventory):
## use_item آیتم مصرفی را کم می‌کند، آمار را از طریق EventBus بازیابی می‌کند، قراضه مصرف نمی‌شود.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/consume_item_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	_run()
	_finish()


func _run() -> void:
	var inv: Node = root.get_node("InventoryManager")
	_check(inv.has_method("use_item"), "InventoryManager.use_item موجود است")
	var packed: PackedScene = load(PLAYER_PATH)
	var player: Player = packed.instantiate() as Player
	root.add_child(player)
	_check(inv.add_item(&"water_bottle", 1) == 1, "۱ بطری آب اضافه شد")
	player.stats.thirst = 10.0
	_check(inv.use_item(&"water_bottle") == true, "مصرف بطری آب موفق است")
	_check(inv.count_item(&"water_bottle") == 0, "بعد از مصرف، بطری از اینونتوری می‌رود")
	_check(absf(player.stats.thirst - 40.0) < 0.01, "تشنگی ۱۰+۳۰ = ۴۰")
	_check(inv.add_item(&"canned_food", 1) == 1, "۱ کنسرو اضافه شد")
	player.stats.hunger = 5.0
	_check(inv.use_item(&"canned_food") == true, "مصرف کنسرو موفق است")
	_check(absf(player.stats.hunger - 40.0) < 0.01, "گرسنگی ۵+۳۵ = ۴۰")
	_check(inv.add_item(&"scrap_metal", 1) == 1, "۱ قراضه اضافه شد")
	_check(inv.use_item(&"scrap_metal") == false, "قراضه مصرف نمی‌شود")
	_check(inv.count_item(&"scrap_metal") == 1, "قراضه بعد از تلاش مصرف باقی است")
	player.free()


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
		[&"InventoryManager", "res://core/inventory/inventory_manager.gd"],
		[&"CraftingSystem", "res://core/crafting/crafting_system.gd"],
		[&"AudioManager", "res://autoloads/audio_manager.gd"],
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
		print("ALL TESTS PASSED (consume item)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
