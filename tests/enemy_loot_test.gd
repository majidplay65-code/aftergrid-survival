## تست کارکردی headless فاز ۱۵ (Enemy Loot):
## مرگ دشمن از EventBus یک قراضه در محل مرگ می‌اندازد.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/enemy_loot_test.gd
##
## نکته: LootSpawner در _ready() به EventBus.enemy_died وصل می‌شود و _ready() در حالت -s
## فقط در نخستین فریم اجرا می‌شود؛ بنابراین چک‌ها بعد از چند فریم در _process() انجام می‌شوند
## (الگوی مشترک tests/inventory_wiring_test.gd).
extends SceneTree

const SPAWNER_PATH: String = "res://core/loot/loot_spawner.gd"
const ENEMY_PATH: String = "res://entities/enemy/enemy.tscn"
const EXPECTED_CHECK_COUNT: int = 8

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var host: Node3D = null
var spawner: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	host = Node3D.new()
	host.name = "LootHost"
	root.add_child(host)
	spawner = load(SPAWNER_PATH).new()
	host.add_child(spawner)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(ResourceLoader.exists(SPAWNER_PATH), "اسکریپت LootSpawner موجود است")
	var enemy: Variant = load(ENEMY_PATH).instantiate()
	host.add_child(enemy)
	enemy.global_position = Vector3(12.0, 1.0, 18.0)
	var before: int = _scrap_count(host)
	enemy.take_damage(enemy.max_health)
	var after: int = _scrap_count(host)
	_check(after == before + 1, "مرگ دشمن یک قراضه می‌سازد")
	var drop: Node3D = _first_scrap(host)
	_check(drop != null, "قراضه‌ی لوت در درخت هست")
	if drop != null:
		_check(drop.global_position.distance_to(Vector3(12.0, 1.15, 18.0)) < 0.2,
				"قراضه نزدیک محل مرگ است")
		_check(drop.global_position.distance_to(Vector3(0.0, 1.0, 7.0)) > 5.0,
				"لوت روی اسپاون بازیکن نمی‌افتد")
		_check(drop.global_position.distance_to(Vector3(26.0, 1.0, 0.0)) > 5.0,
				"لوت روی نقطه‌ی سیو تست نمی‌افتد")
		_check(drop.get("item_id") == &"scrap_metal", "لوت scrap_metal است")
	host.free()


func _scrap_count(host: Node) -> int:
	var count: int = 0
	for child in host.get_children():
		if child.get("item_id") == &"scrap_metal":
			count += 1
	return count


func _first_scrap(host: Node) -> Node3D:
	for child in host.get_children():
		if child.get("item_id") == &"scrap_metal":
			return child as Node3D
	return null


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
		print("ALL TESTS PASSED (enemy loot)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
