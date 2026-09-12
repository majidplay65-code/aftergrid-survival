## تست کارکردی headless فاز ۱۷ (Death):
## DeadState، قفل ورودی، Game Over، عدم سیو بعد از مرگ.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/player_death_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const HUD_PATH: String = "res://ui/hud/hud.tscn"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0
var died_signals: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.player_died.connect(_on_player_died)
	_run()
	_finish()


func _on_player_died() -> void:
	died_signals += 1


func _run() -> void:
	var player: Player = (load(PLAYER_PATH) as PackedScene).instantiate() as Player
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	_check(player.get_node_or_null("StateMachine/DeadState") != null, "DeadState در StateMachine هست")
	root.add_child(player)
	_check(player.is_dead == false, "بازیکن در ابتدا زنده است")
	player.stats.take_damage(200.0)
	_check(player.is_dead == true, "جان صفر → is_dead")
	_check(died_signals == 1, "یک‌بار player_died emit شد")
	var sm: StateMachine = player.get_node("StateMachine") as StateMachine
	_check(sm.current_state != null and StringName(sm.current_state.name) == &"DeadState",
			"ماشین حالت به DeadState می‌رود")
	_check(player.try_melee() == false, "مرده ضربه نمی‌زند")
	var before_y: float = player.velocity.y
	player.start_jump()
	_check(absf(player.velocity.y - before_y) < 0.01, "مرده پرش نمی‌کند")
	player.stats.take_damage(10.0)
	_check(died_signals == 1, "مرگ تکراری سیگنال دوباره نمی‌فرستد")
	var hud: HUD = (load(HUD_PATH) as PackedScene).instantiate() as HUD
	root.add_child(hud)
	EventBus.player_died.emit()
	_check(hud.game_over_panel.visible == true, "پنل Game Over بعد از مرگ دیده می‌شود")
	var saver: SaveController = SaveController.new()
	root.add_child(saver)
	_check(saver.save_now() == false, "سیو بعد از مرگ انجام نمی‌شود")
	player.free()
	hud.free()
	saver.free()


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
		print("ALL TESTS PASSED (player death)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
