## تست کارکردی headless لایه‌ی UI فاز ۶ (Inventory/Crafting):
## InventoryUI در صحنه حاضر است، فهرست اینونتوری و دکمه‌های ساخت را از داده‌ی واقعی
## می‌سازد، حالت قابلیت ساخت را درست نشان می‌دهد (enabled/disabled)، و ساخت از طریق
## UI روی اینونتوریِ واقعی autoload اثر می‌گذارد.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/inventory_ui_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 27

var frame: int = 0
var phase: int = 0
var aborted: bool = false
var finished: bool = false
var level: Node = null
var event_bus: Variant = null
var inv_manager: Variant = null
var crafting: Variant = null
var save_manager: Variant = null
var ui: Variant = null
var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	inv_manager = root.get_node_or_null("InventoryManager")
	crafting = root.get_node_or_null("CraftingSystem")
	save_manager = root.get_node_or_null("SaveManager")
	if event_bus == null or inv_manager == null or crafting == null or save_manager == null:
		_check(false, "P0: autoloadهای لازم در دسترس نیستند")
		aborted = true
		return
	# شروع تمیز: حذف سیو قبلی تا اینونتوری از سیو لود نشود
	if save_manager.has_save_file():
		save_manager.delete_save_file()
	_start_level()


func _process(_delta: float) -> bool:
	if finished:
		return true
	if aborted:
		_finish()
		return true
	frame += 1
	match phase:
		0:
			if frame >= 3:
				_check_ui_presence()
				phase = 1
		1:
			if frame >= 6:
				_check_inventory_display()
				phase = 2
		2:
			if frame >= 9:
				_check_crafting_display()
				phase = 3
		3:
			if frame >= 12:
				_check_craft_flow()
				phase = 4
		4:
			_finish()
			return true
	return false


func _check_ui_presence() -> void:
	ui = level.get_node_or_null("InventoryUI")
	_check(ui != null, "InventoryUI در صحنه حاضر است")
	if ui == null:
		aborted = true
		return
	_check(ui.panel != null, "پنل InventoryUI ساخته شده است")
	_check(ui.is_open == false, "پنل در ابتدا بسته است")
	_check(ui.panel.visible == false, "پنل در ابتدا نامرئی است")
	_check(ui.inventory_list.get_child_count() == 1, "اینونتوری خالی → یک برچسب «خالی»")
	_check(_list_text(ui.inventory_list) == "خالی", "برچسب اینونتوری خالی «خالی» است")
	ui.set_open(true)
	_check(ui.is_open == true, "set_open(true) پنل را باز می‌کند")
	_check(ui.panel.visible == true, "بازشدن → پنل مرئی می‌شود")
	ui.set_open(false)
	_check(ui.is_open == false, "set_open(false) پنل را می‌بندد")
	_check(ui.panel.visible == false, "بستن → پنل نامرئی می‌شود")


func _check_inventory_display() -> void:
	_check(int(inv_manager.add_item(&"scrap_metal", 2)) == 2, "۲ قراضه به اینونتوری اضافه شد")
	ui.refresh()
	_check(ui.inventory_list.get_child_count() == 1, "فهرست اینونتوری یک ردیف دارد")
	var text: String = _list_text(ui.inventory_list)
	_check(text.contains("قراضه"), "نام قراضه در فهرست هست")
	_check(text.contains("×2"), "تعداد ×2 در فهرست هست")


func _check_crafting_display() -> void:
	_check(ui.crafting_list.get_child_count() == 2, "دو دکمه‌ی ساخت ساخته شد")
	var water_btn: Button = ui.get_craft_button(&"craft_water_filter")
	_check(water_btn != null, "دکمه‌ی فیلتر آب موجود است")
	if water_btn != null:
		_check(water_btn.disabled == false, "فیلتر آب با ۲ قراضه فعال است")
	var medkit_btn: Button = ui.get_craft_button(&"craft_medkit")
	_check(medkit_btn != null, "دکمه‌ی مدکیت موجود است")
	if medkit_btn != null:
		_check(medkit_btn.disabled == true, "مدکیت بدون کنسرو غیرفعال است")


func _check_craft_flow() -> void:
	var catalog: ItemCatalog = crafting.catalog
	if catalog == null:
		aborted = true
		return
	var water_recipe: RecipeData = catalog.get_recipe(&"craft_water_filter")
	var medkit_recipe: RecipeData = catalog.get_recipe(&"craft_medkit")
	_check(ui.craft_recipe(water_recipe) == true, "ساخت فیلتر آب از طریق UI موفق است")
	_check(int(inv_manager.count_item(&"scrap_metal")) == 0, "بعد از ساخت، قراضه‌ها مصرف شدند")
	_check(int(inv_manager.count_item(&"water_bottle")) == 1, "بعد از ساخت، ۱ بطری آب داریم")
	_check(ui.inventory_list.get_child_count() == 1, "فهرست بعد از ساخت به‌روز شد")
	_check(_list_text(ui.inventory_list).contains("بطری"), "بطری آب در فهرست هست")
	_check(ui.craft_recipe(medkit_recipe) == false, "ساخت مدکیت بدون کنسرو شکست می‌خورد")
	_check(int(inv_manager.count_item(&"medkit")) == 0, "مدکیت در شکست ساخته نشد")


## متن اولین برچسب در یک لیست (برای بازرسی headless).
## ردیف مصرفی ممکن است HBox(Label, Button) باشد؛ قراضه همچنان Label تنها است.
func _list_text(list: Node) -> String:
	if list.get_child_count() == 0:
		return ""
	var child: Node = list.get_child(0)
	if child is Label:
		return (child as Label).text
	if child.get_child_count() > 0:
		var nested: Node = child.get_child(0)
		if nested is Label:
			return (nested as Label).text
	return ""


func _start_level() -> void:
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)


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
	finished = true
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (inventory ui)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
