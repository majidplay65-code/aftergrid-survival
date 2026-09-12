## تست کارکردی headless فاز ۱۰ (Game Feel & Shareable Build):
## منوی اصلی، AudioManager، افکت‌های WAV، منوی توقف HUD، FOV دویدن، export.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/game_feel_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const MENU_PATH: String = "res://ui/menus/main_menu.tscn"
const AUDIO_SCRIPT: String = "res://autoloads/audio_manager.gd"
const PROJECT_PATH: String = "res://project.godot"
const EXPORT_PATH: String = "res://export_presets.cfg"
const LEVEL_PATH: String = "res://levels/test_level.tscn"

const SFX_PATHS: Array[String] = [
	"res://assets/audio/footstep_walk.wav",
	"res://assets/audio/footstep_run.wav",
	"res://assets/audio/craft.wav",
	"res://assets/audio/pickup.wav",
	"res://assets/audio/ui_click.wav",
	"res://assets/audio/hit.wav",
	"res://assets/audio/pause_whoosh.wav",
]

const EXPECTED_CHECK_COUNT: int = 19

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var phase: int = 0
var aborted: bool = false
var level: Node = null
var hud: Variant = null
var menu: Node = null


func _initialize() -> void:
	_ensure_autoloads()
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	_check_static()
	if aborted:
		_finish()
		return
	menu = load(MENU_PATH).instantiate()
	root.add_child(menu)


func _process(_delta: float) -> bool:
	if aborted:
		return true
	frame += 1
	match phase:
		0:
			if frame >= 3:
				_check(menu.get("start_button") != null, "منوی اصلی دکمه‌ی شروع دارد")
				_check(menu.get("quit_button") != null, "منوی اصلی دکمه‌ی خروج دارد")
				menu.queue_free()
				var packed: PackedScene = load(LEVEL_PATH)
				level = packed.instantiate()
				root.add_child(level)
				phase = 1
		1:
			if frame >= 6:
				hud = level.get_node_or_null("HUD")
				_check(hud != null, "HUD در سطح هست")
				if hud == null:
					aborted = true
					_finish()
					return true
				_check(hud.pause_panel != null, "پنل توقف ساخته شده")
				_check(hud.pause_panel.visible == false, "پنل توقف در ابتدا بسته است")
				hud.toggle_pause_menu()
				_check(hud.pause_panel.visible == true, "toggle_pause_menu پنل را باز می‌کند")
				var game_state: Variant = root.get_node_or_null("GameState")
				_check(game_state != null and game_state.is_paused == true, "بازی بعد از ESC متوقف است")
				hud.toggle_pause_menu()
				_check(hud.pause_panel.visible == false, "toggle دوباره پنل را می‌بندد")
				var player: Node = level.get_node_or_null("Player")
				_check(player != null and absf(float(player.get("WALK_FOV")) - 75.0) < 0.01, "WALK_FOV = ۷۵")
				_check(player != null and absf(float(player.get("RUN_FOV")) - 85.0) < 0.01, "RUN_FOV = ۸۵")
				_finish()
				return true
	return false


func _check_static() -> void:
	_check(ResourceLoader.exists(MENU_PATH), "صحنه‌ی منوی اصلی موجود است")
	_check(ResourceLoader.exists(AUDIO_SCRIPT), "اسکریپت AudioManager موجود است")
	_check(ResourceLoader.exists(EXPORT_PATH), "export_presets.cfg موجود است")
	var event_bus: Variant = root.get_node_or_null("EventBus")
	_check(event_bus != null and event_bus.has_signal("footstep_played"),
			"سیگنال footstep_played روی EventBus هست")
	var all_sfx: bool = true
	for sfx_path in SFX_PATHS:
		if not ResourceLoader.exists(sfx_path):
			all_sfx = false
	_check(all_sfx, "هر ۷ افکت WAV موجود است")
	_check(_file_contains(PROJECT_PATH, "main_menu.tscn"), "main_scene به منوی اصلی اشاره می‌کند")
	_check(_file_contains(PROJECT_PATH, "AudioManager"), "AudioManager به‌عنوان autoload ثبت شده")
	_check(_file_contains(EXPORT_PATH, "Linux") and _file_contains(EXPORT_PATH, "Windows Desktop"),
			"presetهای Linux و Windows موجودند")


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
		print("ALL TESTS PASSED (game feel)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
