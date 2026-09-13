## تست کارکردی headless فاز ۲۲ (برد شب).
##
## نکته: DayCycle ارجاع Environment را در _ready() پیدا می‌کند و HUD پنل شب را در _ready()
## می‌سازد؛ در حالت -s این‌ها از نخستین فریم به بعد در دسترس‌اند. برای همین سطح پیش از
## فریم‌ها به درخت اضافه و چک‌ها در _process() انجام می‌شوند (الگوی tests/inventory_wiring_test.gd).
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const EXPECTED_CHECK_COUNT: int = 14

var checks_run: int = 0
var failures: int = 0
var heard_index: int = -1
var game_state: Variant = null
var level: Node = null
var frame: int = 0
var started: bool = false


func _initialize() -> void:
	_ensure_autoloads()
	var event_bus: Variant = root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.night_survived.connect(_on_survived)
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	game_state = root.get_node_or_null("GameState")
	if game_state != null:
		game_state.night_index = 1
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run(level)
		_finish()
		return true
	return false


func _on_survived(night_index: int) -> void:
	heard_index = night_index


func _run(level: Node) -> void:
	var cycle: Node = level.get_node_or_null("DayCycle")
	_check(cycle != null, "DayCycle موجود است")
	if cycle == null:
		return
	cycle.call("set_time_of_day", 0.19)
	_check(heard_index == -1, "قبل از سپیده night_survived نیست")
	cycle.call("set_time_of_day", 0.26)
	_check(heard_index == 1, "عبور از سپیده night_survived(1) می‌دهد")
	_check(game_state != null and game_state.night_index == 2, "night_index بعد از شب ۱ به ۲ می‌رسد")
	var hud: Variant = level.get_node_or_null("HUD")
	_check(hud != null, "HUD موجود است")
	if hud != null:
		_check(hud.survive_panel != null and hud.survive_panel.visible,
				"پنل زنده ماندی نمایان است")
		_check(hud.night_label != null, "برچسب شب روی HUD هست")
	var data: SaveData = SaveData.new()
	_check(data.night_index == 1, "سیو قدیمی night_index پیش‌فرض ۱ دارد")
	# ── edge-caseها (هرکدام یک باگ بالقوه‌ی مشخص می‌گیرد) ──
	# (۱) پرش زمان به عقب نباید night_survived بدهد
	# (باگ: اگر شرط current >= previous حذف شود (مثلاً در بازآرایی به
	# min/max)، پرش عقب + رسیدن به سپیده progression کاذب می‌دهد — سواستفاده).
	cycle.call("set_time_of_day", 0.19)
	_check(heard_index == 1, "Edge: پرش عقب (۰٫۲۶→۰٫۱۹) → night_survived جدید نمی‌دهد")
	_check(game_state.night_index == 2, "Edge: پرش عقب → night_index تغییر نمی‌کند")
	# (۲) «شب کوتاه» (previous ≥ ۰٫۲۰) نباید بشمارد
	# (باگ: حذف گاردِ previous >= 0.20، عبوری ۰٫۲۲→۰٫۲۶ که شبِ واقعی‌ای
	# پشت سر نگذاشته، را progression می‌شمارد).
	cycle.call("set_time_of_day", 0.22)
	cycle.call("set_time_of_day", 0.26)
	_check(heard_index == 1, "Edge: عبور از ۰٫۲۲ (شب کوتاه) → night_survived نمی‌دهد")
	# (۳) شب کاملِ دوم: ایندکسِ اعلام‌شده باید شبِ پایان‌یافته باشد، نه شبِ بعد
	# (باگ: emit با مقدارِ after-increment، برچسب شبِ اشتباه روی HUD/سیو می‌گذارد).
	cycle.call("set_time_of_day", 0.10)
	cycle.call("set_time_of_day", 0.26)
	_check(heard_index == 2, "Edge: شب دوم با ایندکس ۲ اعلام می‌شود (شبِ پایان‌یافته)")
	_check(game_state.night_index == 3, "Edge: بعد از شب دوم night_index=3")


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
		print("ALL TESTS PASSED (night survive)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
