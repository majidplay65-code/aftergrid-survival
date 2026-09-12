## تست کارکردی headless فاز ۸ (Noise-Based Awareness):
## سیگنال noise_emitted(noise_position, loudness)، کاملاً event-driven،
## بدون فرض شلیک، InvestigateState، ضریب شنوایی واریانت‌ها.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/noise_awareness_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const ENEMY_PATH: String = "res://entities/enemy/enemy.tscn"
const STALKER_PATH: String = "res://entities/enemy/enemy_stalker.tscn"
const BRUTE_PATH: String = "res://entities/enemy/enemy_brute.tscn"
const INVESTIGATE_PATH: String = "res://entities/enemy/states/investigate_state.gd"
const ENEMY_SCRIPT: String = "res://entities/enemy/enemy.gd"
const PLAYER_SCRIPT: String = "res://entities/player/player.gd"
const CRAFT_SCRIPT: String = "res://core/crafting/crafting_system.gd"
const BUS_SCRIPT: String = "res://autoloads/event_bus.gd"

const EXPECTED_CHECK_COUNT: int = 14

var frame: int = 0
var phase: int = 0
var checks_run: int = 0
var failures: int = 0
var aborted: bool = false
var event_bus: Variant = null
var enemy: Node = null


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	if event_bus == null:
		_check(false, "P0: EventBus در دسترس نیست")
		aborted = true
		_finish()
		return
	_check_static()
	_spawn_listener()


func _process(_delta: float) -> bool:
	if aborted:
		return true
	frame += 1
	match phase:
		0:
			if frame >= 4:
				# نویز نزدیک: باید Investigate شود (loudness 8، ضریب ۱، فاصله ۰).
				event_bus.noise_emitted.emit(enemy.global_position, 8.0)
				phase = 1
		1:
			if frame >= 8:
				var state: Node = enemy.get_node("StateMachine").current_state
				_check(state != null and StringName(state.name) == &"InvestigateState",
						"نویز نزدیک → InvestigateState")
				# نویز خیلی دور: دشمن دوم نباید از گشت خارج شود.
				var far: Node = _instantiate_in_tree(ENEMY_PATH, Vector3(80.0, 0.7, 80.0))
				event_bus.noise_emitted.emit(Vector3.ZERO, 6.0)
				phase = 2
				_far_enemy = far
		2:
			if frame >= 12:
				var far_state: Node = _far_enemy.get_node("StateMachine").current_state
				_check(far_state != null and StringName(far_state.name) != &"InvestigateState",
						"نویز دور → گشت باقی می‌ماند")
				_finish()
				return true
	return false


var _far_enemy: Node = null


func _check_static() -> void:
	_check(event_bus.has_signal("noise_emitted"), "سیگنال noise_emitted روی EventBus هست")
	_check(ResourceLoader.exists(INVESTIGATE_PATH), "اسکریپت InvestigateState موجود است")
	_check(_file_contains(BUS_SCRIPT, "noise_position"), "پارامتر سیگنال noise_position است (نه position)")
	_check(not _file_contains(BUS_SCRIPT, "signal noise_emitted(position"),
			"سیگنال با پارامتر position تعریف نشده")
	_check(_file_contains(PLAYER_SCRIPT, "EventBus.noise_emitted.emit"),
			"بازیکن نویز قدم را emit می‌کند")
	_check(_file_contains(CRAFT_SCRIPT, "EventBus.noise_emitted.emit"),
			"ساخت آیتم نویز emit می‌کند")
	_check(not _file_contains(ENEMY_SCRIPT, "func _process"),
			"دشمن چک فاصله را در _process پال نمی‌کند")
	_check(_file_contains(ENEMY_SCRIPT, "func _on_noise_emitted"),
			"دشمن مشترک سیگنال نویز است")
	var shambler: Node = load(ENEMY_PATH).instantiate()
	var stalker: Node = load(STALKER_PATH).instantiate()
	var brute: Node = load(BRUTE_PATH).instantiate()
	_check(shambler.get_node_or_null("StateMachine/InvestigateState") != null
			and stalker.get_node_or_null("StateMachine/InvestigateState") != null
			and brute.get_node_or_null("StateMachine/InvestigateState") != null,
			"هر سه واریانت InvestigateState دارند")
	_check(absf(float(stalker.get("hearing_multiplier")) - 1.5) < 0.01, "Stalker شنوایی ×۱.۵")
	_check(absf(float(brute.get("hearing_multiplier")) - 0.6) < 0.01, "Brute شنوایی ×۰.۶")
	shambler.free()
	stalker.free()
	brute.free()


func _spawn_listener() -> void:
	enemy = _instantiate_in_tree(ENEMY_PATH, Vector3(0.0, 0.7, 0.0))


func _instantiate_in_tree(path: String, pos: Vector3) -> Node:
	var node: Node = load(path).instantiate()
	root.add_child(node)
	if node is Node3D:
		(node as Node3D).global_position = pos
	return node


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
		print("ALL TESTS PASSED (noise awareness)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
