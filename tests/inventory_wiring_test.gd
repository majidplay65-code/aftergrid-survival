## تست کارکردی headless لایه‌ی اتصال فاز ۶ (Inventory/Crafting):
## - autoloadهای InventoryManager و CraftingSystem با کاتالوگ واقعی ثبت و سیم‌کشی شده‌اند؛
## - آیتم غیرمصرفی (قراضه) از طریق ItemPickup به اینونتوری می‌رود، مصرفی (آب) نمی‌رود؛
## - ساخت از طریق CraftingSystem روی اینونتوریِ واقعی autoload؛
## - SaveController اینونتوری واقعی را ذخیره و بازیابی می‌کند (فیلد رزروشده‌ی inventory_items).
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/inventory_wiring_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const SCRAP_SCENE_PATH: String = "res://entities/interactables/scrap_metal.tscn"
const WATER_SCENE_PATH: String = "res://entities/interactables/water_bottle.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 21

var frame: int = 0
var phase: int = 0
var aborted: bool = false
var level: Node = null
var event_bus: Variant = null
var inv_manager: Variant = null
var crafting: Variant = null
var save_manager: Variant = null
var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	inv_manager = root.get_node_or_null("InventoryManager")
	crafting = root.get_node_or_null("CraftingSystem")
	save_manager = root.get_node_or_null("SaveManager")
	if event_bus == null or inv_manager == null or crafting == null:
		_check(false, "P0: autoloadهای لازم در دسترس نیستند")
		aborted = true
		_finish()
		return
	# شروع تمیز: حذف سیو قبلی تا مسیر save/load قابل تکرار باشد
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	_start_level()


func _process(_delta: float) -> bool:
	if aborted:
		return true
	frame += 1
	match phase:
		0:
			if frame >= 3:
				_check_autoload_wiring()
				_check_pickup_wiring()
				phase = 1
		1:
			if frame >= 6:
				_check_crafting_wiring()
				phase = 2
		2:
			if frame >= 9:
				_check_save_load_wiring()
				phase = 3
		3:
			_finish()
			return true
	return false


## بخش الف — autoloadها با کاتالوگ واقعی بالا آمده‌اند.
func _check_autoload_wiring() -> void:
	_check(inv_manager.inventory != null, "InventoryManager autoload اینونتوری را ساخته")
	_check(inv_manager.catalog != null, "InventoryManager کاتالوگ واقعی را لود کرده")
	_check(inv_manager.catalog.items.size() == 4, "کاتالوگ autoload چهار آیتم دارد")
	_check(inv_manager.catalog.has_item(&"scrap_metal"), "کاتالوگ autoload قراضه را می‌شناسد")
	_check(crafting.catalog != null, "CraftingSystem کاتالوگ واقعی را لود کرده")
	_check(crafting.catalog.recipes.size() == 2, "کاتالوگ autoload دو دستور دارد")


## بخش ب — سیم‌کشی ItemPickup: غیرمصرفی به اینونتوری، مصرفی نه.
func _check_pickup_wiring() -> void:
	var player: Node3D = _player()
	_check(player != null, "بازیکن در صحنه حاضر است")
	if player == null:
		return
	var scrap: Interactable = _instantiate_pickup(SCRAP_SCENE_PATH)
	scrap.interact(player)
	_check(inv_manager.count_item(&"scrap_metal") == 1, "برداشتن قراضه → ۱ قراضه به اینونتوری")
	player.stats.thirst = 50.0
	var water: Interactable = _instantiate_pickup(WATER_SCENE_PATH)
	water.interact(player)
	_check(inv_manager.count_item(&"water_bottle") == 0, "نوشیدن آب → به اینونتوری نمی‌رود")
	_check(absf(player.stats.thirst - 80.0) < 0.01, "نوشیدن آب → تشنگی ۵۰ به ۸۰ رسید")


## بخش ج — ساخت از طریق CraftingSystem روی اینونتوریِ واقعی autoload.
func _check_crafting_wiring() -> void:
	_check(inv_manager.add_item(&"scrap_metal", 1) == 1, "یک قراضه‌ی دیگر اضافه شد (مجموع ۲)")
	var water_recipe: RecipeData = crafting.catalog.get_recipe(&"craft_water_filter")
	_check(water_recipe != null, "دستور فیلتر آب از کاتالوگ autoload گرفته شد")
	if water_recipe == null:
		return
	_check(crafting.craft(water_recipe, inv_manager.inventory), "ساخت فیلتر آب از طریق autoload موفق است")
	_check(inv_manager.count_item(&"scrap_metal") == 0, "بعد از ساخت، هر ۲ قراضه مصرف شد")
	_check(inv_manager.count_item(&"water_bottle") == 1, "بعد از ساخت، ۱ بطری آب تولید شد")


## بخش د — SaveController اینونتوری واقعی را ذخیره و بازیابی می‌کند.
func _check_save_load_wiring() -> void:
	var controller: Node = _controller()
	_check(controller != null, "SaveController در صحنه حاضر است")
	if controller == null:
		return
	_check(controller.save_now(), "سیو دستی با اینونتوری فعلی موفق است")
	inv_manager.remove_item(&"water_bottle", 1)
	_check(inv_manager.count_item(&"water_bottle") == 0, "اینونتوری بعد از سیو خالی شد")
	_check(controller.load_now(), "لود دستی موفق است")
	_check(inv_manager.count_item(&"water_bottle") == 1, "لود، بطری آب ذخیره‌شده را بازیابی کرد")


func _instantiate_pickup(scene_path: String) -> Interactable:
	var packed: PackedScene = load(scene_path)
	var node: Interactable = packed.instantiate() as Interactable
	level.add_child(node)
	return node


func _start_level() -> void:
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)


func _player() -> Node3D:
	if level == null:
		return null
	var p: Node = level.get_node_or_null("Player")
	return p as Node3D if p != null else null


func _controller() -> Node:
	if level == null:
		return null
	return level.get_node_or_null("SaveController")


## اگر اسکریپت با -s اجرا شود و autoload ها لود نشده باشند، دستی اضافه کن.
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
		# در Godot 4.7 پارامتر has_node از نوع NodePath است و StringName به‌صورت ضمنی
		# به NodePath تبدیل نمی‌شود؛ پس صریح تبدیل می‌کنیم: StringName → NodePath.
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
		print("ALL TESTS PASSED (inventory wiring)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
