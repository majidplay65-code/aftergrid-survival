## تست کارکردی headless فاز ۱۹ (در و فضای داخلی):
## SafeShop با در Interactable، دو آیتم داخل، مانع ناوبری، navmesh کاروشده.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/interiors_test.gd
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const NAVMESH_VERTEX_COUNT: int = 394
const NAVMESH_POLYGON_COUNT: int = 582
const EXPECTED_CHECK_COUNT: int = 17

var checks_run: int = 0
var failures: int = 0
var level: Node = null


func _initialize() -> void:
	_ensure_autoloads()
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)
	_run()
	_finish()


func _run() -> void:
	var shop: Node3D = level.get_node_or_null("SafeShop") as Node3D
	_check(shop != null, "SafeShop در سطح هست")
	if shop == null:
		return
	_check(shop.global_position.distance_to(Vector3(-10.0, 0.0, 6.0)) < 0.05,
			"SafeShop در (-10, 0, 6) است")
	var door: Door = shop.get_node_or_null("Door") as Door
	_check(door != null, "در داخل فروشگاه هست")
	if door != null:
		_check(not door.is_open, "در ابتدا بسته است")
		var player: Node3D = level.get_node_or_null("Player") as Node3D
		_check(player != null, "بازیکن برای تعامل در موجود است")
		if player != null:
			door.interact(player)
			_check(door.is_open, "E در را باز می‌کند")
			door.interact(player)
			_check(not door.is_open, "E دوباره در را می‌بندد")
	_check(shop.get_node_or_null("WaterBottle") != null, "بطری آب داخل فروشگاه هست")
	_check(shop.get_node_or_null("CannedFood") != null, "کنسرو داخل فروشگاه هست")
	var obstacle: NavigationObstacle3D = level.get_node_or_null("ObstacleShop") as NavigationObstacle3D
	_check(obstacle != null, "ObstacleShop در صحنه هست")
	if obstacle != null:
		_check(obstacle.get_vertices().size() == 4, "ObstacleShop چهار رأس دارد")
		_check(obstacle.affect_navigation_mesh and obstacle.carve_navigation_mesh,
				"ObstacleShop علامت‌های affect + carve را دارد")
	var region: Node3D = level.get_node_or_null("NavigationRegion") as Node3D
	_check(region != null, "NavigationRegion در صحنه هست")
	if region == null:
		return
	var navmesh: NavigationMesh = region.navigation_mesh
	_check(navmesh != null, "navigation_mesh ست شده")
	if navmesh == null:
		return
	_check(navmesh.get_vertices().size() == NAVMESH_VERTEX_COUNT,
			"navmesh %d رأس دارد" % NAVMESH_VERTEX_COUNT)
	_check(navmesh.get_polygon_count() == NAVMESH_POLYGON_COUNT,
			"navmesh %d مثلث دارد" % NAVMESH_POLYGON_COUNT)


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
		print("ALL TESTS PASSED (interiors)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
