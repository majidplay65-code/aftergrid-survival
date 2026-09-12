## تست کارکردی headless فاز ۹ (World Expansion):
## حیاط صنعتی شرقی (دو انبار + سه کانتینر + سوله)، موانع ناوبری، آیتم‌ها، Enemy4،
## و شمار رأس/مثلث navmesh کاروشده.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/world_expansion_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const NAVMESH_VERTEX_COUNT: int = 394
const NAVMESH_POLYGON_COUNT: int = 582
const EXPECTED_CHECK_COUNT: int = 22

const BUILDING_NAMES: Array[String] = [
	"WarehouseA", "WarehouseB", "Container1", "Container2", "Container3", "Shed",
]
const NEW_OBSTACLE_NAMES: Array[String] = [
	"ObstacleW1", "ObstacleW2", "ObstacleC1", "ObstacleC2", "ObstacleC3", "ObstacleShed",
]
const NEW_ITEM_NAMES: Array[String] = [
	"ScrapMetal2", "WaterBottle3", "CannedFood3", "Medkit2",
]

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
	for building_name in BUILDING_NAMES:
		_check(level.get_node_or_null(NodePath(building_name)) != null,
				"سازه‌ی %s در سطح هست" % building_name)
	for obstacle_name in NEW_OBSTACLE_NAMES:
		var obstacle: NavigationObstacle3D = level.get_node_or_null(NodePath(obstacle_name)) as NavigationObstacle3D
		_check(obstacle != null and obstacle.get_vertices().size() == 4
				and obstacle.affect_navigation_mesh and obstacle.carve_navigation_mesh,
				"مانع %s با vertices + carve" % obstacle_name)
	for item_name in NEW_ITEM_NAMES:
		_check(level.get_node_or_null(NodePath(item_name)) != null,
				"آیتم %s در حیاط صنعتی هست" % item_name)
	_check(level.get_node_or_null("Enemy4") != null, "Enemy4 در حیاط صنعتی هست")
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
		print("ALL TESTS PASSED (world expansion)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
