## تست کارکردی headless لایه‌ی منطق فاز ۶ (Inventory):
## Inventory (Resource: add/remove/stack) + InventoryManager (پل به EventBus:
## item_picked_up / item_dropped → اینونتوری، تغییر واقعی → inventory_changed).
##
## داده‌ی استفاده‌شده در این تست «فرضی» است (کاتالوگ ساخته‌شده در کد)؛
## داده‌ی واقعی (.tres) طبق برنامه در لایه‌ی بعد تعریف می‌شود.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/inventory_logic_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 35

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var event_bus: Variant = null
var manager: Variant = null
var inventory_changed_emissions: int = 0
var inv_changed_count: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	if event_bus == null:
		_check(false, "P0: نود EventBus در دسترس نیست")
		_finish()
		return
	_test_inventory_resource()


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		# ساخت manager بعد از ثبت autoloadها (اسکریپتِ ارجاع‌دهنده به EventBus باید
		# بعد از ثبت شناسه‌های سراسری لود شود — همان الگوی save_load_test).
		manager = load("res://core/inventory/inventory_manager.gd").new()
		manager.catalog = _build_catalog()
		root.add_child(manager)
		event_bus.inventory_changed.connect(_on_inventory_changed_counter)
	elif frame >= 3:
		_test_inventory_manager()
		_finish()
		return true
	return false


## شمارنده‌ی انتشارهای EventBus.inventory_changed (باید فقط روی تغییر واقعی بالا برود).
func _on_inventory_changed_counter() -> void:
	inventory_changed_emissions += 1


## شمارنده‌ی سیگنال changed خودِ Inventory (Resource).
func _on_inventory_changed() -> void:
	inv_changed_count += 1


## کاتالوگ فرضی برای تست (داده‌ی واقعی .tres در لایه‌ی بعد می‌آید):
## قراضه max_stack=3، آب max_stack=1 (مصرفی)، مدکیت max_stack=5.
func _build_catalog() -> ItemCatalog:
	var cat: ItemCatalog = ItemCatalog.new()
	var scrap: ItemData = ItemData.new()
	scrap.item_id = &"scrap_metal"
	scrap.item_name = "قطعه آهن‌قراضه"
	scrap.max_stack = 3
	cat.items.append(scrap)
	var water: ItemData = ItemData.new()
	water.item_id = &"water_bottle"
	water.item_name = "بطری آب معدنی"
	water.max_stack = 1
	water.is_consumable = true
	cat.items.append(water)
	var medkit: ItemData = ItemData.new()
	medkit.item_id = &"medkit"
	medkit.item_name = "جعبه کمک‌های اولیه"
	medkit.max_stack = 5
	cat.items.append(medkit)
	return cat


## بخش الف — منطق خالص Resource بدون نیاز به درخت/اتوبوس.
func _test_inventory_resource() -> void:
	var inv: Inventory = Inventory.new()
	inv.catalog = _build_catalog()
	_check(inv != null, "Inventory ساخته می‌شود")
	_check(inv.is_empty(), "Inventory در ابتدا خالی است")
	_check(inv.count_item(&"scrap_metal") == 0, "count_item برای آیتم غایب ۰ است")
	_check(inv.has_item(&"scrap_metal") == false, "has_item برای آیتم غایب false است")
	_check(inv.add_item(&"scrap_metal", 2) == 2, "add_item هر ۲ واحد را اضافه می‌کند")
	_check(inv.count_item(&"scrap_metal") == 2, "count_item ۲ را برمی‌گرداند")
	_check(inv.add_item(&"scrap_metal", 5) == 1, "add_item فقط ۱ واحد اضافه می‌کند (سقف max_stack=۳)")
	_check(inv.count_item(&"scrap_metal") == 3, "انباشت از max_stack بیشتر نمی‌شود")
	_check(inv.add_item(&"scrap_metal", 0) == 0, "add_item با مقدار صفر ۰ برمی‌گرداند")
	_check(inv.add_item(&"water_bottle", 2) == 1, "add_item آیتم max_stack=۱ را فقط ۱ می‌گیرد")
	_check(inv.count_item(&"water_bottle") == 1, "آیتم غیرقابل انباشت در ۱ می‌ماند")
	_check(inv.remove_item(&"scrap_metal", 1) == 1, "remove_item ۱ واحد حذف می‌کند")
	_check(inv.count_item(&"scrap_metal") == 2, "بعد از حذف ۲ می‌ماند")
	_check(inv.remove_item(&"scrap_metal", 99) == 2, "remove_item بیش از موجود فقط موجود را حذف می‌کند")
	_check(inv.count_item(&"scrap_metal") == 0, "آیتم بعد از خالی‌شدن ۰ است")
	_check(inv.has_item(&"scrap_metal") == false, "has_item بعد از خالی‌شدن false است")
	_check(inv.remove_item(&"scrap_metal", 1) == 0, "remove_item از آیتم غایب ۰ برمی‌گرداند")
	_check(inv.total_count() == 1, "total_count مجموع همه‌ی آیتم‌ها است")
	_check(inv.is_empty() == false, "is_empty بعد از افزودن false است")
	var snapshot: Dictionary = inv.get_items()
	snapshot[&"water_bottle"] = 99
	_check(inv.count_item(&"water_bottle") == 1, "get_items کپی می‌دهد نه رفرنس")
	# سیگنال changed فقط روی تغییر واقعی
	inv_changed_count = 0
	inv.changed.connect(_on_inventory_changed)
	_check(inv.add_item(&"water_bottle", 5) == 0, "add_item وقتی جا نیست ۰ برمی‌گرداند")
	_check(inv_changed_count == 0, "changed بدون تغییر واقعی emit نمی‌شود")
	inv.add_item(&"medkit", 1)
	inv.remove_item(&"medkit", 1)
	_check(inv_changed_count == 2, "changed روی add/remove واقعی emit می‌شود")


## بخش ب — InventoryManager به‌عنوان پل به EventBus.
func _test_inventory_manager() -> void:
	_check(manager != null, "InventoryManager ساخته و به درخت اضافه شد")
	event_bus.item_picked_up.emit(&"scrap_metal", 2)
	_check(manager.count_item(&"scrap_metal") == 2, "item_picked_up → افزودن به اینونتوری")
	_check(inventory_changed_emissions == 1, "inventory_changed بعد از اولین تغییر emit شد")
	event_bus.item_picked_up.emit(&"scrap_metal", 5)
	_check(manager.count_item(&"scrap_metal") == 3, "item_picked_up → انباشت در max_stack محدود می‌شود")
	_check(inventory_changed_emissions == 2, "inventory_changed بعد از تغییر دوم emit شد")
	event_bus.item_dropped.emit(&"scrap_metal", 1)
	_check(manager.count_item(&"scrap_metal") == 2, "item_dropped → کم کردن از اینونتوری")
	_check(inventory_changed_emissions == 3, "inventory_changed بعد از تغییر سوم emit شد")
	event_bus.item_picked_up.emit(&"scrap_metal", 0)
	_check(inventory_changed_emissions == 3, "تغییر صفر → inventory_changed دوباره emit نمی‌شود")
	_check(manager.has_item(&"scrap_metal", 2) == true, "manager.has_item مقدار کافی را تشخیص می‌دهد")
	_check(manager.has_item(&"scrap_metal", 3) == false, "manager.has_item کمبود را تشخیص می‌دهد")
	var snapshot: Dictionary = manager.get_items()
	_check(snapshot.get(&"scrap_metal", 0) == 2, "manager.get_items محتوا را برمی‌گرداند")


## اگر اسکریپت با -s اجرا شود و autoload ها لود نشده باشند، دستی اضافه کن.
func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
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
		print("ALL TESTS PASSED (inventory logic)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
