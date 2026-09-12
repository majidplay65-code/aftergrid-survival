## تست کارکردی headless: prop غیرتعاملی «نیمکت» (bench.tscn)
## - صحنه‌ی prop بارگذاری می‌شود؛ بدون اسکریپت/منطق (صرفاً بصری)
## - در بلوک شهری (test_level.tscn) در محل انتظار instance شده است
## - حداقل یک مش دارد و روی زمین (y≈0) قرار گرفته
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/prop_broken_sign_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const PROP_PATH: String = "res://entities/decor/bench.tscn"
const LEVEL_PATH: String = "res://levels/test_level.tscn"
const PROP_NODE_NAME: String = "Bench"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 13

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var level: Node = null


func _initialize() -> void:
	# سطح test_level شامل بازیکن/دشمن‌هاست که _ready() آن‌ها autoloadها را می‌خواهد؛
	# autoloadها در حالت -s پیش از _initialize() ثبت می‌شوند ولی _ready()شان
	# فقط در نخستین فریم اجرا می‌شود (الگوی مشترک tests/inventory_wiring_test.gd).
	_ensure_autoloads()
	# شروع تمیز: حذف سیوی که ممکن است تست‌های قبلی روی همین runner باقی گذاشته باشند
	# (SaveController در _ready سطح، سیو را خودکار لود می‌کند).
	var save_manager: Node = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()


func _process(_delta: float) -> bool:
	# صبر تا فریم‌های اول (اجرای _ready autoloadها) — الگوی مشترک تست‌ها.
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


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


func _run() -> void:
	var packed: PackedScene = load(PROP_PATH)
	_check(packed != null, "bench.tscn لود می‌شود")
	if packed == null:
		return
	var prop: Node = packed.instantiate()
	_check(prop is Node3D, "ریشه‌ی prop یک Node3D است")
	var root3d: Node3D = prop as Node3D
	_check(root3d != null and root3d.get_script() == null, "ریشه‌ی prop اسکریپت ندارد (غیرتعاملی)")
	_check(_no_script_anywhere(root3d), "هیچ فرزندِ prop اسکریپت ندارد (صرفاً بصری)")
	_check(_count_meshes(root3d) >= 3, "prop حداقل ۳ مش دارد (نشان + پاها)")
	prop.free()

	var level_packed: PackedScene = load(LEVEL_PATH)
	_check(level_packed != null, "سطح test_level لود می‌شود")
	if level_packed == null:
		return
	level = level_packed.instantiate()
	root.add_child(level)
	var placed: Node = level.get_node_or_null(PROP_NODE_NAME)
	_check(placed != null, "Bench در بلوک شهری instance شده است")
	if placed == null:
		return
	_check(placed is Node3D, "instance داخل سطح یک Node3D است")
	var placed3d: Node3D = placed as Node3D
	_check(absf(placed3d.global_position.x - 6.0) < 0.01, "Bench در x=6 قرار دارد")
	_check(absf(placed3d.global_position.z - 14.0) < 0.01, "Bench در z=14 قرار دارد")
	_check(absf(placed3d.global_position.y - 0.0) < 0.01, "Bench روی زمین (y=0) است")
	_check(_count_meshes(placed3d) >= 3, "instance داخل سطح مش دارد")
	level.queue_free()


func _no_script_anywhere(n: Node) -> bool:
	if n.get_script() != null:
		return false
	for child in n.get_children():
		if not _no_script_anywhere(child):
			return false
	return true


func _count_meshes(n: Node) -> int:
	var count: int = 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		count += 1
	for child in n.get_children():
		count += _count_meshes(child)
	return count


func _check(ok: bool, label: String) -> void:
	checks_run += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (prop bench)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
