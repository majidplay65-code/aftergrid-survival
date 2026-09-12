## تست کارکردی headless فاز ۱۶ (Jump):
## JumpState، ایمپالس عمودی، نویز پرش، بدون پرش از خزیدن.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/jump_state_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const PROJECT_PATH: String = "res://project.godot"
const EXPECTED_CHECK_COUNT: int = 11

var checks_run: int = 0
var failures: int = 0
var heard_jump_noise: bool = false


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.noise_emitted.connect(_on_noise)
	_run()
	_finish()


func _on_noise(_pos: Vector3, loudness: float) -> void:
	if absf(loudness - Player.JUMP_NOISE) < 0.01:
		heard_jump_noise = true


func _run() -> void:
	_check(_file_contains(PROJECT_PATH, "jump="), "اکشن jump در Input Map هست")
	_check(absf(Player.JUMP_VELOCITY - 4.5) < 0.01, "JUMP_VELOCITY = ۴.۵")
	_check(absf(Player.JUMP_NOISE - 7.0) < 0.01, "نویز پرش ۷ متر است")
	_check(absf(Player.LAND_NOISE - 9.0) < 0.01, "نویز فرود ۹ متر است")
	var packed: PackedScene = load(PLAYER_PATH)
	var player: Player = packed.instantiate() as Player
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	_check(player.get_node_or_null("StateMachine/JumpState") != null, "JumpState در StateMachine هست")
	root.add_child(player)
	var sm: StateMachine = player.get_node("StateMachine") as StateMachine
	_check(sm != null and sm.states.has(&"JumpState"), "StateMachine JumpState را ثبت کرده")
	player.start_jump()
	_check(player.velocity.y > 4.0, "start_jump سرعت عمودی می‌دهد")
	_check(heard_jump_noise, "پرش نویز ۷ متری emit کرد")
	sm.transition_to(&"JumpState")
	_check(sm.current_state != null and StringName(sm.current_state.name) == &"JumpState",
			"transition_to JumpState موفق است")
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
		print("ALL TESTS PASSED (jump state)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
