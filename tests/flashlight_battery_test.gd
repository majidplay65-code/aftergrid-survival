## تست کارکردی headless فاز ۱۲ (Flashlight Battery):
## تخلیه باتری هنگام روشن بودن، خاموشی در صفر، شارژ از ژنراتور از طریق EventBus.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/flashlight_battery_test.gd
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const HUD_PATH: String = "res://ui/hud/hud.tscn"
const SWITCH_PATH: String = "res://entities/interactables/power_switch.tscn"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	_run()
	_finish()


func _run() -> void:
	_check(absf(Player.FLASHLIGHT_DRAIN_RATE - 8.0) < 0.01, "نرخ تخلیه ۸ واحد بر ثانیه است")
	_check(absf(Player.MAX_FLASHLIGHT_BATTERY - 100.0) < 0.01, "سقف باتری ۱۰۰ است")
	var packed: PackedScene = load(PLAYER_PATH)
	var player: Player = packed.instantiate() as Player
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	root.add_child(player)
	_check(absf(player.flashlight_battery - 100.0) < 0.01, "باتری اولیه ۱۰۰ است")
	player.flashlight.visible = true
	player._update_flashlight_battery(1.0)
	_check(absf(player.flashlight_battery - 92.0) < 0.05, "یک ثانیه روشن → ۹۲ باقی می‌ماند")
	player.set_flashlight_battery(0.0)
	_check(player.flashlight.visible == false, "باتری صفر چراغ را خاموش می‌کند")
	player.recharge_flashlight()
	_check(absf(player.flashlight_battery - 100.0) < 0.01, "recharge_flashlight باتری را پر می‌کند")
	player.set_flashlight_battery(10.0)
	EventBus.generator_charge_requested.emit()
	_check(absf(player.flashlight_battery - 100.0) < 0.01, "سیگنال ژنراتور باتری را شارژ می‌کند")
	var switch_packed: PackedScene = load(SWITCH_PATH)
	var switch_node: PowerSwitch = switch_packed.instantiate() as PowerSwitch
	root.add_child(switch_node)
	player.set_flashlight_battery(5.0)
	switch_node._on_interact(player)
	_check(switch_node.is_powered_on and absf(player.flashlight_battery - 100.0) < 0.01,
			"روشن‌کردن کلید ژنراتور باتری را شارژ می‌کند")
	var hud_packed: PackedScene = load(HUD_PATH)
	var hud: HUD = hud_packed.instantiate() as HUD
	root.add_child(hud)
	_check(hud.get_node_or_null("Root/MarginContainer/VitalsContainer/BatteryBar") != null,
			"نوار باتری روی HUD هست")
	player.free()
	switch_node.free()
	hud.free()


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
		print("ALL TESTS PASSED (flashlight battery)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
