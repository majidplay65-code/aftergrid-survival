## تست کارکردی headless: آیتم جدید «الکل ضدعفونی» (antiseptic.tres)
## - بارگذاری .tres و راستی‌آزمایی مقادیر ItemData (مصرفی، دسته‌ی MEDKIT)
## - حضور آیتم در کاتالوگ اصلی
## - مصرف کامل از اینونتوری: use_item آیتم را کم می‌کند و health بازیکن را +۱۰ می‌کند
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/item_antiseptic_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
## نکته: autoloadها در حالت -s پیش از _initialize() ثبت می‌شوند ولی _ready() آن‌ها
## فقط در نخستین فریم اجرا می‌شود؛ برای همین چک‌ها بعد از چند فریم در _process انجام می‌شوند.
extends SceneTree

const ANTISEPTIC_PATH: String = "res://resources/items/antiseptic.tres"
const CATALOG_PATH: String = "res://resources/item_catalog.tres"
const PLAYER_PATH: String = "res://entities/player/player.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 18

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var inv: Variant = null
var player: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	inv = root.get_node_or_null("InventoryManager")
	var packed: PackedScene = load(PLAYER_PATH)
	player = packed.instantiate()
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
	var raw: Resource = ResourceLoader.load(ANTISEPTIC_PATH)
	_check(raw != null, "antiseptic.tres لود می‌شود")
	if raw == null:
		return
	_check(raw is ItemData, "antiseptic.tres از نوع ItemData است")
	var item: ItemData = raw as ItemData
	_check(item.item_id == &"antiseptic", "antiseptic شناسه‌ی antiseptic دارد")
	_check(item.item_name == "الکل ضدعفونی", "antiseptic نام فارسی درست دارد")
	_check(item.description != "", "antiseptic توضیح خالی ندارد")
	_check(item.category == ItemData.ItemCategory.MEDKIT, "antiseptic دسته‌ی MEDKIT دارد")
	_check(item.max_stack == 5, "antiseptic max_stack=5 دارد")
	_check(item.is_consumable == true, "antiseptic قابل‌مصرف است")
	_check(item.stat_restore_amount == 10.0, "antiseptic مقدار بازیابی ۱۰ دارد")

	var catalog: Resource = ResourceLoader.load(CATALOG_PATH)
	_check(catalog != null and catalog is ItemCatalog, "کاتالوگ اصلی لود و از نوع ItemCatalog است")
	var cat: ItemCatalog = catalog as ItemCatalog
	if cat == null:
		return
	_check(cat.has_item(&"antiseptic"), "antiseptic در کاتالوگ اصلی ثبت شده است")
	_check(cat.get_item(&"antiseptic") == item, "نمونه‌ی کاتالوگ همان antiseptic.tres است")

	# مصرف کامل از اینونتوریِ autoload: کم شدن آیتم + بازیابی health از طریق EventBus.
	_check(inv != null and inv.has_method("use_item"), "InventoryManager autoload با use_item در دسترس است")
	if inv == null or player == null:
		return
	_check(inv.add_item(&"antiseptic", 1) == 1, "۱ الکل ضدعفونی به اینونتوری اضافه شد")
	player.stats.health = 50.0
	_check(inv.use_item(&"antiseptic") == true, "مصرف الکل ضدعفونی موفق است")
	_check(inv.count_item(&"antiseptic") == 0, "بعد از مصرف، الکل از اینونتوری می‌رود")
	_check(absf(player.stats.health - 60.0) < 0.01, "جان ۵۰+۱۰ = ۶۰")
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
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (item antiseptic)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
