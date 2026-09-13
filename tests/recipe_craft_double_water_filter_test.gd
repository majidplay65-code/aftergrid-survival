## تست کارکردی headless: دستور ساخت جدید «فیلتر آب دوقلو» (craft_double_water_filter.tres)
## - بارگذاری .tres و راستی‌آزمایی مقادیر RecipeData (دو ماده، خروجی ۲ بطری آب)
## - حضور دستور در کاتالوگ اصلی
## - ساخت واقعی از طریق CraftingSystem: موفق با مواد کامل، شکست با مواد ناکافی
## - بررسی سیگنال‌های EventBus (item_crafted / craft_failed)
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/recipe_craft_double_water_filter_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const RECIPE_PATH: String = "res://resources/recipes/craft_double_water_filter.tres"
const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 23

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var crafting: Variant = null
var event_bus: Variant = null
var crafted_ids: Array = []
var failed_reasons: Array = []


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	crafting = root.get_node_or_null("CraftingSystem")
	if event_bus != null:
		event_bus.item_crafted.connect(_on_item_crafted)
		event_bus.craft_failed.connect(_on_craft_failed)


func _process(_delta: float) -> bool:
	# autoloadها در حالت -s پیش از _initialize() ثبت می‌شوند ولی _ready() آن‌ها
	# (که CraftingSystem در آن کاتالوگ را لود می‌کند) فقط در نخستین فریم اجرا می‌شود.
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	var raw: Resource = ResourceLoader.load(RECIPE_PATH)
	_check(raw != null, "craft_double_water_filter.tres لود می‌شود")
	if raw == null:
		return
	_check(raw is RecipeData, "craft_double_water_filter.tres از نوع RecipeData است")
	var recipe: RecipeData = raw as RecipeData
	_check(recipe.recipe_id == &"craft_double_water_filter", "craft_double_water_filter شناسه‌ی درست دارد")
	_check(recipe.recipe_name == "فیلتر آب دوقلو", "craft_double_water_filter نام فارسی درست دارد")
	_check(recipe.result_item_id == &"water_bottle", "craft_double_water_filter خروجی water_bottle دارد")
	_check(recipe.result_amount == 2, "craft_double_water_filter تعداد خروجی ۲ دارد")
	_check(recipe.ingredients.size() == 2, "craft_double_water_filter دو ماده لازم دارد")
	_check(recipe.ingredients.has(&"scrap_metal") and int(recipe.ingredients[&"scrap_metal"]) == 1,
			"craft_double_water_filter به ۱ قراضه نیاز دارد")
	_check(recipe.ingredients.has(&"air_filter") and int(recipe.ingredients[&"air_filter"]) == 1,
			"craft_double_water_filter به ۱ فیلتر هوا نیاز دارد")
	_check(recipe.craft_time == 2.0, "craft_double_water_filter زمان ساخت ۲ ثانیه دارد")

	var catalog: Resource = ResourceLoader.load(CATALOG_PATH)
	_check(catalog != null and catalog is ItemCatalog, "کاتالوگ اصلی لود و از نوع ItemCatalog است")
	var cat: ItemCatalog = catalog as ItemCatalog
	if cat == null:
		return
	_check(cat.has_recipe(&"craft_double_water_filter"), "craft_double_water_filter در کاتالوگ اصلی ثبت شده است")
	_check(cat.get_recipe(&"craft_double_water_filter") == recipe, "نمونه‌ی کاتالوگ همان craft_double_water_filter.tres است")

	# ساخت واقعی از طریق CraftingSystem autoload روی یک Inventory جدا.
	var inv: Inventory = Inventory.new()
	inv.catalog = cat
	inv.add_item(&"scrap_metal", 1)
	inv.add_item(&"air_filter", 1)
	_check(crafting.can_craft(recipe, inv), "با ۱ قراضه + ۱ فیلتر هوا، can_craft true است")
	_check(crafting.craft(recipe, inv), "ساخت فیلتر آب دوقلو موفق است")
	_check(inv.count_item(&"scrap_metal") == 0, "بعد از ساخت، قراضه مصرف شد")
	_check(inv.count_item(&"air_filter") == 0, "بعد از ساخت، فیلتر هوا مصرف شد")
	_check(inv.count_item(&"water_bottle") == 2, "بعد از ساخت، ۲ بطری آب به اینونتوری آمد")
	_check(crafted_ids.size() == 1 and crafted_ids[0] == &"craft_double_water_filter",
			"سیگنال item_crafted با شناسه‌ی درست emit شد")

	# شکست با مواد ناکافی: بدون دست‌زدن به اینونتوری.
	var empty_inv: Inventory = Inventory.new()
	empty_inv.catalog = cat
	_check(not crafting.can_craft(recipe, empty_inv), "بدون مواد، can_craft false است")
	_check(not crafting.craft(recipe, empty_inv), "ساخت بدون مواد شکست می‌خورد")
	_check(failed_reasons.size() == 1 and failed_reasons[0] == "insufficient_materials",
			"سیگنال craft_failed با دلیل insufficient_materials emit شد")


func _on_item_crafted(recipe_id: StringName) -> void:
	crafted_ids.append(recipe_id)


func _on_craft_failed(_recipe_id: StringName, reason: String) -> void:
	failed_reasons.append(reason)


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
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
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (recipe craft double water filter)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
