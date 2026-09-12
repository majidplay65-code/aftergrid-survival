## تست کارکردی headless فاز ۱۴ (Melee + Enemy HP):
## ضربه‌ی نزدیک استامینا/نویز مصرف می‌کند و جان دشمن را کم می‌کند.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/melee_combat_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const SHAMBLER_PATH: String = "res://entities/enemy/enemy.tscn"
const STALKER_PATH: String = "res://entities/enemy/enemy_stalker.tscn"
const BRUTE_PATH: String = "res://entities/enemy/enemy_brute.tscn"
const EXPECTED_CHECK_COUNT: int = 13

var checks_run: int = 0
var failures: int = 0
var heard_noise: bool = false
var death_count: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	EventBus.noise_emitted.connect(_on_noise)
	EventBus.enemy_died.connect(_on_died)
	_run()
	_finish()


func _on_noise(_pos: Vector3, loudness: float) -> void:
	if absf(loudness - Player.MELEE_NOISE) < 0.01:
		heard_noise = true


func _on_died(_pos: Vector3) -> void:
	death_count += 1


func _run() -> void:
	_check(absf(Player.MELEE_STAMINA_COST - 12.0) < 0.01, "هزینه استامینا ۱۲ است")
	_check(absf(Player.MELEE_NOISE - 8.0) < 0.01, "نویز ضربه ۸ متر است")
	var player: Player = (load(PLAYER_PATH) as PackedScene).instantiate() as Player
	root.add_child(player)
	_check(player.get_node_or_null("StateMachine/MeleeState") != null, "MeleeState در ماشین حالت هست")
	var shambler: Enemy = (load(SHAMBLER_PATH) as PackedScene).instantiate() as Enemy
	var stalker: Enemy = (load(STALKER_PATH) as PackedScene).instantiate() as Enemy
	var brute: Enemy = (load(BRUTE_PATH) as PackedScene).instantiate() as Enemy
	root.add_child(shambler)
	root.add_child(stalker)
	root.add_child(brute)
	_check(absf(shambler.max_health - 40.0) < 0.01, "Shambler جان ۴۰ دارد")
	_check(absf(stalker.max_health - 25.0) < 0.01, "Stalker جان ۲۵ دارد")
	_check(absf(brute.max_health - 70.0) < 0.01, "Brute جان ۷۰ دارد")
	player.global_position = Vector3(0.0, 1.0, 0.0)
	shambler.global_position = Vector3(0.0, 1.0, -1.2)
	_check(player.try_melee() == true, "ضربه با استامینا موفق است")
	_check(absf(player.stats.stamina - 88.0) < 0.05, "استامینا ۱۲ واحد کم شد")
	_check(heard_noise, "ضربه نویز ۸ متری emit کرد")
	_check(absf(shambler.health - 25.0) < 0.05, "Shambler ۱۵ آسیب گرفت")
	player.stats.stamina = 0.0
	_check(player.try_melee() == false, "بدون استامینا ضربه نمی‌زند")
	stalker.take_damage(25.0)
	_check(death_count == 1, "دشمن با جان صفر می‌میرد")
	player.free()
	if is_instance_valid(shambler):
		shambler.free()
	if is_instance_valid(brute):
		brute.free()


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
		print("ALL TESTS PASSED (melee combat)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
