## تست کارکردی headless فاز ۱۱ (Stealth Crouch):
## CrouchState در ماشین حالت بازیکن، سرعت/نویز کمتر، اکشن crouch.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/stealth_crouch_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const PLAYER_SCRIPT: String = "res://entities/player/player.gd"
const PROJECT_PATH: String = "res://project.godot"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	_run()
	_finish()


func _run() -> void:
	_check(ResourceLoader.exists(PLAYER_PATH), "صحنه‌ی بازیکن موجود است")
	_check(_file_contains(PROJECT_PATH, "crouch="), "اکشن crouch در Input Map هست")
	_check(absf(Player.CROUCH_SPEED - 1.6) < 0.01, "CROUCH_SPEED = ۱.۶")
	_check(Player.CROUCH_SPEED < Player.WALK_SPEED, "خزیدن از راه‌رفتن کندتر است")
	_check(_file_contains(PLAYER_SCRIPT, "2.5"), "نویز خزیدن ۲.۵ متر است")
	var packed: PackedScene = load(PLAYER_PATH)
	var player: Node = packed.instantiate()
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	_check(player.get_node_or_null("StateMachine/CrouchState") != null, "CrouchState در StateMachine هست")
	_check(player.get_node_or_null("StateMachine/IdleState") != null, "IdleState باقی است")
	_check(player.has_method("is_crouch_pressed"), "is_crouch_pressed موجود است")
	root.add_child(player)
	var sm: StateMachine = player.get_node("StateMachine") as StateMachine
	_check(sm != null and sm.states.has(&"CrouchState"), "StateMachine CrouchState را ثبت کرده")
	sm.transition_to(&"CrouchState")
	_check(sm.current_state != null and StringName(sm.current_state.name) == &"CrouchState",
			"transition_to CrouchState موفق است")
	player.free()


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
		print("ALL TESTS PASSED (stealth crouch)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
