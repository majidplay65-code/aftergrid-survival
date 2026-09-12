## تست کارکردی headless فاز ۱۸ (Line of Sight):
## تعقیب فقط با پرتو فیزیک آزاد؛ دیوار وسط = دیده نشد.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/line_of_sight_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const ENEMY_PATH: String = "res://entities/enemy/enemy.tscn"
const CHASE_SCRIPT: String = "res://entities/enemy/states/chase_state.gd"
const ENEMY_SCRIPT: String = "res://entities/enemy/enemy.gd"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var phase: int = 0
var host: Node3D
var player: Player
var enemy: Enemy
var wall: StaticBody3D


func _initialize() -> void:
	_ensure_autoloads()
	_check(_file_contains(ENEMY_SCRIPT, "PhysicsRayQueryParameters3D"),
			"دشمن از PhysicsRayQueryParameters3D استفاده می‌کند")
	_check(_file_contains(CHASE_SCRIPT, "move_along_agent(delta, speed)"),
			"ChaseState از speed درست استفاده می‌کند نه SPEED")
	_build_world()


func _process(_delta: float) -> bool:
	frame += 1
	if phase == 0 and frame >= 8:
		_check_runtime()
		_finish()
		return true
	return false


func _build_world() -> void:
	host = Node3D.new()
	host.name = "LosHost"
	root.add_child(host)

	wall = StaticBody3D.new()
	wall.name = "Wall"
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(6.0, 4.0, 0.5)
	shape_node.shape = box
	wall.add_child(shape_node)
	wall.position = Vector3(0.0, 2.0, 2.5)
	host.add_child(wall)

	enemy = (load(ENEMY_PATH) as PackedScene).instantiate() as Enemy
	host.add_child(enemy)
	enemy.global_position = Vector3(0.0, 1.0, 0.0)

	player = (load(PLAYER_PATH) as PackedScene).instantiate() as Player
	host.add_child(player)
	player.global_position = Vector3(0.0, 1.0, 5.0)


func _check_runtime() -> void:
	_check(enemy != null and player != null, "بازیکن و دشمن در صحنه هستند")
	if enemy == null or player == null:
		return
	_check(enemy.has_method("has_line_of_sight_to"), "has_line_of_sight_to موجود است")
	_check(enemy.has_method("try_spot_player"), "try_spot_player موجود است")
	_check(enemy.player_in_sight_area, "بازیکن داخل کرهٔ دید است (فاصله < ۷)")
	_check(enemy.has_line_of_sight_to(player) == false, "دیوار وسط → خط دید بسته است")
	var sm: StateMachine = enemy.get_node("StateMachine") as StateMachine
	var state_name: StringName = &""
	if sm != null and sm.current_state != null:
		state_name = StringName(sm.current_state.name)
	_check(state_name != &"ChaseState", "بدون خط دید وارد Chase نمی‌شود")
	player.global_position = Vector3(4.0, 1.0, 0.0)
	_check(enemy.has_line_of_sight_to(player) == true, "بدون دیوار در مسیر → خط دید باز است")
	_check(enemy.try_spot_player() == true, "با خط دید باز try_spot تعقیب را شروع می‌کند")
	if sm != null and sm.current_state != null:
		state_name = StringName(sm.current_state.name)
	_check(state_name == &"ChaseState", "بعد از دیدن آزاد، ChaseState فعال است")
	host.free()


func _file_contains(path: String, snippet: String) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	return f.get_as_text().contains(snippet)


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
		print("ALL TESTS PASSED (line of sight)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
