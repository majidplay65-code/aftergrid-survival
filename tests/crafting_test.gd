## تست کارکردی headless لایه‌ی منطق ساخت (Crafting) فاز ۶:
## CraftingSystem با داده‌ی واقعی .tres — هم حالت موفق و هم حالت شکست (کمبود مواد،
## پر بودن اینونتوری) به‌همراه اتمیک بودن (اول check کامل، بعد commit) و
## اتصال به سیگنال‌های EventBus (item_crafted / craft_failed).
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/crafting_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 39

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var aborted: bool = false
var event_bus: Variant = null
var crafting: Variant = null
var catalog: ItemCatalog = null
var inventory: Inventory = null
var crafted_ids: Array[StringName] = []
var failed_ids: Array[StringName] = []
var failed_reasons: Array[String] = []


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	if event_bus == null:
		_check(false, "P0: نود EventBus در دسترس نیست")
		aborted = true
		_finish()


func _process(_delta: float) -> bool:
	if aborted:
		return true
	frame += 1
	if frame == 1:
		_setup()
		_run_tests()
		_finish()
		return true
	return false


func _setup() -> void:
	# crafting system بعد از ثبت autoloadها لود می‌شود (اسکریپتِ ارجاع‌دهنده به
	# EventBus باید بعد از ثبت شناسه‌های سراسری کامپایل شود — الگوی سایر تست‌ها).
	crafting = load("res://core/crafting/crafting_system.gd").new()
	catalog = ResourceLoader.load(CATALOG_PATH) as ItemCatalog
	crafting.catalog = catalog
	# نود به درخت اضافه می‌شود تا در teardown آزاد شود و در خروجی نشت نکند
	# (الگوی inventory_logic_test — نود بیرون از درخت در ObjectDB می‌ماند).
	root.add_child(crafting)
	inventory = _new_inventory()
	# شمارنده‌ی سیگنال‌ها روی نود واقعی اتوبوس (نه شناسه‌ی سراسری)
	event_bus.item_crafted.connect(_on_item_crafted)
	event_bus.craft_failed.connect(_on_craft_failed)


func _on_item_crafted(recipe_id: StringName) -> void:
	crafted_ids.append(recipe_id)


func _on_craft_failed(recipe_id: StringName, reason: String) -> void:
	failed_ids.append(recipe_id)
	failed_reasons.append(reason)


## اینونتوری تازه با کاتالوگ واقعی (برای هر سناریو مستقل).
func _new_inventory() -> Inventory:
	var inv: Inventory = Inventory.new()
	inv.catalog = catalog
	return inv


func _clear_signals() -> void:
	crafted_ids.clear()
	failed_ids.clear()
	failed_reasons.clear()


func _run_tests() -> void:
	_check(catalog != null, "P0: کاتالوگ واقعی .tres لود شد")
	if catalog == null:
		return
	_check(catalog.recipes.size() == 2, "P0: کاتالوگ دو دستور دارد")
	var water: RecipeData = catalog.get_recipe(&"craft_water_filter")
	var medkit: RecipeData = catalog.get_recipe(&"craft_medkit")
	_check(water != null and medkit != null, "P0: هر دو دستور واقعی در کاتالوگ هستند")
	_test_water_success(water)
	_test_water_insufficient(water)
	_test_medkit_success(medkit)
	_test_medkit_insufficient(medkit)
	_test_inventory_full(water)
	_test_can_craft_readonly(water)
	_test_null_inputs(water)


func _test_water_success(water: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	_check(inventory.add_item(&"scrap_metal", 2) == 2, "آماده‌سازی: ۲ قراضه اضافه شد")
	_check(crafting.can_craft(water, inventory), "can_craft با مواد کافی true است")
	_check(crafting.craft(water, inventory), "craft فیلتر آب با مواد کافی موفق است")
	_check(inventory.count_item(&"scrap_metal") == 0, "بعد از ساخت، هر ۲ قراضه مصرف شد")
	_check(inventory.count_item(&"water_bottle") == 1, "بعد از ساخت، ۱ بطری آب تولید شد")
	_check(crafted_ids.size() == 1 and crafted_ids[0] == &"craft_water_filter",
			"item_crafted با شناسه‌ی درست emit شد")
	_check(failed_ids.is_empty(), "در موفقیت craft_failed emit نشد")


func _test_water_insufficient(water: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	inventory.add_item(&"scrap_metal", 1)
	_check(not crafting.can_craft(water, inventory), "can_craft با مواد ناکافی false است")
	_check(not crafting.craft(water, inventory), "craft فیلتر آب با کمبود مواد شکست می‌خورد")
	_check(inventory.count_item(&"scrap_metal") == 1, "شکست، مواد را مصرف نمی‌کند")
	_check(inventory.count_item(&"water_bottle") == 0, "شکست، خروجی تولید نمی‌کند")
	_check(failed_ids.size() == 1 and failed_ids[0] == &"craft_water_filter",
			"craft_failed با شناسه‌ی درست emit شد")
	_check(failed_reasons.size() == 1 and failed_reasons[0] == "insufficient_materials",
			"دلیل شکست insufficient_materials است")
	_check(crafted_ids.is_empty(), "در شکست item_crafted emit نشد")


func _test_medkit_success(medkit: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	inventory.add_item(&"canned_food", 1)
	inventory.add_item(&"scrap_metal", 1)
	_check(crafting.craft(medkit, inventory), "craft مدکیت با مواد کافی موفق است")
	_check(inventory.count_item(&"canned_food") == 0, "کنسرو مصرف شد")
	_check(inventory.count_item(&"scrap_metal") == 0, "قراضه مصرف شد")
	_check(inventory.count_item(&"medkit") == 1, "۱ مدکیت تولید شد")
	_check(crafted_ids.size() == 1 and crafted_ids[0] == &"craft_medkit",
			"item_crafted مدکیت با شناسه‌ی درست emit شد")
	_check(failed_ids.is_empty(), "craft_failed در موفقیت مدکیت emit نشد")


func _test_medkit_insufficient(medkit: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	inventory.add_item(&"canned_food", 1)
	_check(not crafting.craft(medkit, inventory), "craft مدکیت بدون قراضه شکست می‌خورد")
	_check(inventory.count_item(&"canned_food") == 1, "کنسرو در شکست دست‌نخورده می‌ماند")
	_check(inventory.count_item(&"medkit") == 0, "مدکیت در شکست تولید نمی‌شود")
	_check(failed_reasons.size() == 1 and failed_reasons[0] == "insufficient_materials",
			"دلیل شکست مدکیت insufficient_materials است")
	_check(failed_ids.size() == 1 and failed_ids[0] == &"craft_medkit",
			"craft_failed مدکیت با شناسه‌ی درست emit شد")


func _test_inventory_full(water: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	inventory.add_item(&"scrap_metal", 2)
	inventory.add_item(&"water_bottle", 5)
	_check(not crafting.craft(water, inventory), "craft وقتی خروجی جا ندارد شکست می‌خورد")
	_check(inventory.count_item(&"scrap_metal") == 2, "در inventory_full مواد مصرف نشد (اتمیک)")
	_check(inventory.count_item(&"water_bottle") == 5, "در inventory_full خروجی اضافه نشد")
	_check(failed_reasons.size() == 1 and failed_reasons[0] == "inventory_full",
			"دلیل inventory_full است")


func _test_can_craft_readonly(water: RecipeData) -> void:
	inventory = _new_inventory()
	inventory.add_item(&"scrap_metal", 2)
	_check(crafting.can_craft(water, inventory), "can_craft با مواد کافی true است")
	_check(inventory.count_item(&"scrap_metal") == 2 and inventory.count_item(&"water_bottle") == 0,
			"can_craft فقط‌خواندنی است (هیچ تغییری نمی‌دهد)")


func _test_null_inputs(water: RecipeData) -> void:
	inventory = _new_inventory()
	_clear_signals()
	_check(not crafting.craft(null, inventory), "craft با دستور null شکست می‌خورد")
	_check(not crafting.craft(water, null), "craft با اینونتوری null شکست می‌خورد")
	_check(inventory.count_item(&"scrap_metal") == 0 and inventory.count_item(&"water_bottle") == 0,
			"ورودی null هیچ تغییری نمی‌دهد")
	_check(not crafting.can_craft(null, inventory) and not crafting.can_craft(water, null),
			"can_craft با ورودی null false است")


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
	# پاکسازی رفرنس‌ها پیش از خروج تا گارد ERROR/WARNING (نشت ریسورس) در CI فعال نشود
	if crafting != null:
		crafting.catalog = null
	catalog = null
	inventory = null
	crafting = null
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (crafting)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
