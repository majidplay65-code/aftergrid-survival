## تست کارکردی headless فاز ۱۲ (Flashlight Battery):
## تخلیه باتری هنگام روشن بودن، خاموشی در صفر، شارژ از ژنراتور از طریق EventBus.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/flashlight_battery_test.gd
##
## نکته: flashlight عضو @onready بازیکن است و فقط بعد از _ready() مقدار می‌گیرد؛ در حالت -s
## این از نخستین فریم به بعد برقرار می‌شود. برای همین بازیکن پیش از فریم‌ها به درخت اضافه و
## چک‌ها در _process() انجام می‌شوند (الگوی tests/inventory_wiring_test.gd).
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const PLAYER_SCRIPT: String = "res://entities/player/player.gd"
const HUD_PATH: String = "res://ui/hud/hud.tscn"
const SWITCH_PATH: String = "res://entities/interactables/power_switch.tscn"
const EXPECTED_CHECK_COUNT: int = 11

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var player: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	player = load(PLAYER_PATH).instantiate()
	if player != null:
		# باتری اولیه را پیش از ورود به درخت (و پیش از هر فریم drain) می‌سنجیم؛
		# flashlight_battery یک عضو ساده است و نیازی به _ready ندارد.
		_check(absf(player.flashlight_battery - 100.0) < 0.01, "باتری اولیه ۱۰۰ است")
		root.add_child(player)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	var player_script: Variant = load(PLAYER_SCRIPT)
	_check(absf(player_script.FLASHLIGHT_DRAIN_RATE - 8.0) < 0.01, "نرخ تخلیه ۸ واحد بر ثانیه است")
	_check(absf(player_script.MAX_FLASHLIGHT_BATTERY - 100.0) < 0.01, "سقف باتری ۱۰۰ است")
	_check(player != null, "بازیکن instantiate می‌شود")
	if player == null:
		return
	# در فریم‌های انتظار، چراغ‌قوه (که در صحنه به‌صورت پیش‌فرض روشن است) باتری را کم کرده؛
	# برای یک نقطه‌ی شروع تمیز، باتری را به سقف برمی‌گردانیم.
	player.set_flashlight_battery(100.0)
	player.flashlight.visible = true
	player._update_flashlight_battery(1.0)
	_check(absf(player.flashlight_battery - 92.0) < 0.05, "یک ثانیه روشن → ۹۲ باقی می‌ماند")
	player.set_flashlight_battery(0.0)
	_check(player.flashlight.visible == false, "باتری صفر چراغ را خاموش می‌کند")
	player.recharge_flashlight()
	_check(absf(player.flashlight_battery - 100.0) < 0.01, "recharge_flashlight باتری را پر می‌کند")
	player.set_flashlight_battery(10.0)
	var event_bus: Variant = root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.generator_charge_requested.emit()
	_check(absf(player.flashlight_battery - 100.0) < 0.01, "سیگنال ژنراتور باتری را شارژ می‌کند")
	var switch_packed: PackedScene = load(SWITCH_PATH)
	var switch_node: Variant = switch_packed.instantiate()
	root.add_child(switch_node)
	player.set_flashlight_battery(5.0)
	switch_node._on_interact(player)
	_check(switch_node.is_powered_on and absf(player.flashlight_battery - 100.0) < 0.01,
			"روشن‌کردن کلید ژنراتور باتری را شارژ می‌کند")
	var hud_packed: PackedScene = load(HUD_PATH)
	var hud: Variant = hud_packed.instantiate()
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
