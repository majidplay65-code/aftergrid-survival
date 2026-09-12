## تست کارکردی headless فاز ۲۶ (میز ساخت).
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 8

var checks_run: int = 0
var failures: int = 0
var fail_reason: String = ""


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.craft_failed.connect(_on_fail)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	var packed: PackedScene = load(LEVEL_PATH)
	var level: Node = packed.instantiate()
	root.add_child(level)
	_run(level)
	_finish()


func _on_fail(_id: StringName, reason: String) -> void:
	fail_reason = reason


func _run(level: Node) -> void:
	var bench: Node3D = level.get_node_or_null("Workbench") as Node3D
	_check(bench != null, "Workbench در سطح هست")
	var crafting: Variant = root.get_node_or_null("CraftingSystem")
	var inv: Variant = root.get_node_or_null("InventoryManager")
	_check(crafting != null and inv != null, "CraftingSystem و InventoryManager هستند")
	if crafting == null or inv == null or bench == null:
		return
	inv.add_item(&"scrap_metal", 2)
	var recipe: RecipeData = crafting.catalog.get_recipe(&"craft_water_filter")
	_check(recipe != null, "دستور فیلتر آب موجود است")
	_check(not crafting.is_near_workbench(), "اسپاون از میز دور است")
	_check(not crafting.craft(recipe, inv.inventory, true), "ساخت دور از میز شکست می‌خورد")
	_check(fail_reason == "too_far", "دلیل too_far است")
	_check(crafting.craft(recipe, inv.inventory, false), "ساخت بدون الزام میز همچنان کار می‌کند")


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
		print("ALL TESTS PASSED (workbench)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
