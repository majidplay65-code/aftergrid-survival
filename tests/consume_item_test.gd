## تست کارکردی headless فاز ۱۳ (Consume from Inventory):
## use_item آیتم مصرفی را کم می‌کند، آمار را از طریق EventBus بازیابی می‌کند، قراضه مصرف نمی‌شود.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/consume_item_test.gd
##
## نکته: autoloadها در حالت -s پیش از _initialize() ثبت می‌شوند ولی _ready() آن‌ها
## (که InventoryManager در آن اینونتوری واقعی را می‌سازد) فقط در نخستین فریم اجرا می‌شود.
## برای همین چک‌ها به‌جای _initialize() در _process() و بعد از چند فریم انجام می‌شوند
## (الگوی مشترک tests/inventory_wiring_test.gd).
extends SceneTree

const PLAYER_PATH: String = "res://entities/player/player.tscn"
const EXPECTED_CHECK_COUNT: int = 12

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var aborted: bool = false
var inv: Variant = null
var player: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	inv = root.get_node_or_null("InventoryManager")
	_check(inv != null and inv.has_method("use_item"), "InventoryManager.use_item موجود است")
	if inv == null or not inv.has_method("use_item"):
		aborted = true
		_finish()
		return
	var packed: PackedScene = load(PLAYER_PATH)
	player = packed.instantiate()
	root.add_child(player)


func _process(_delta: float) -> bool:
	if aborted:
		return true
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(inv.add_item(&"water_bottle", 1) == 1, "۱ بطری آب اضافه شد")
	player.stats.thirst = 10.0
	_check(inv.use_item(&"water_bottle") == true, "مصرف بطری آب موفق است")
	_check(inv.count_item(&"water_bottle") == 0, "بعد از مصرف، بطری از اینونتوری می‌رود")
	_check(absf(player.stats.thirst - 40.0) < 0.01, "تشنگی ۱۰+۳۰ = ۴۰")
	_check(inv.add_item(&"canned_food", 1) == 1, "۱ کنسرو اضافه شد")
	player.stats.hunger = 5.0
	_check(inv.use_item(&"canned_food") == true, "مصرف کنسرو موفق است")
	_check(absf(player.stats.hunger - 40.0) < 0.01, "گرسنگی ۵+۳۵ = ۴۰")
	_check(inv.add_item(&"scrap_metal", 1) == 1, "۱ قراضه اضافه شد")
	_check(inv.use_item(&"scrap_metal") == false, "قراضه مصرف نمی‌شود")
	_check(inv.count_item(&"scrap_metal") == 1, "قراضه بعد از تلاش مصرف باقی است")
	player.free()


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
		print("ALL TESTS PASSED (consume item)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
