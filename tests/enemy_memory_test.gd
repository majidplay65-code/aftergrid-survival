## تست کارکردی headless فاز ۲۴ (حافظه دشمن).
##
## نکته: StateMachine states را در _ready() می‌سازد و global_position فقط بعد از ورود
## به درخت معتبر است؛ در حالت -s هر دو فقط از نخستین فریم به بعد در دسترس‌اند. برای همین
## چک‌ها در _process() و بعد از چند فریم انجام می‌شوند (الگوی tests/inventory_wiring_test.gd).
extends SceneTree

const ENEMY_PATH: String = "res://entities/enemy/enemy.tscn"
const STALKER_PATH: String = "res://entities/enemy/enemy_stalker.tscn"
const BRUTE_PATH: String = "res://entities/enemy/enemy_brute.tscn"
const EXPECTED_CHECK_COUNT: int = 9

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var enemy: Variant = null
var stalker: Variant = null
var brute: Variant = null
var dummy: Node3D = null


func _initialize() -> void:
	_ensure_autoloads()
	enemy = load(ENEMY_PATH).instantiate()
	if enemy != null:
		root.add_child(enemy)
	dummy = Node3D.new()
	dummy.position = Vector3(3.0, 0.0, 1.0)
	root.add_child(dummy)
	stalker = load(STALKER_PATH).instantiate()
	root.add_child(stalker)
	brute = load(BRUTE_PATH).instantiate()
	root.add_child(brute)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(enemy != null, "Shambler instantiate می‌شود")
	if enemy == null:
		return
	_check(absf(enemy.memory_seconds - 4.0) < 0.01, "Shambler memory_seconds = ۴")
	var sm: StateMachine = enemy.get_node("StateMachine") as StateMachine
	_check(sm != null and sm.states.has(&"InvestigateState"), "InvestigateState ثبت شده")
	sm.transition_to(&"ChaseState")
	_check(sm.current_state != null and StringName(sm.current_state.name) == &"ChaseState",
			"می‌توان به Chase رفت")
	enemy.lose_visual(dummy)
	_check(enemy.last_seen_position.distance_to(dummy.global_position) < 0.01,
			"last_seen_position ذخیره می‌شود")
	_check(sm.current_state != null and StringName(sm.current_state.name) == &"InvestigateState",
			"گم‌کردن دید → Investigate نه Patrol")
	_check(stalker.memory_seconds > 4.0, "Stalker حافظه بلندتر است")
	_check(brute.memory_seconds <= 4.0, "Brute حافظه بلندتر از Shambler نیست")
	enemy.free()
	dummy.free()
	stalker.free()
	brute.free()


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
		print("ALL TESTS PASSED (enemy memory)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
