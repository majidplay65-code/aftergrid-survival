## تست کارکردی headless لایه‌ی داده‌ی واقعی فاز ۶ (Inventory/Crafting):
## بارگذاری resources/item_catalog.tres و راستی‌آزمایی مقادیر واقعی .tres
## (آیتم‌های scrap_metal/canned_food/water_bottle/medkit و دستورهای
## craft_water_filter/craft_medkit) به‌همراه اتصال آن‌ها به هم.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/item_catalog_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 49

var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	var catalog: Resource = ResourceLoader.load(CATALOG_PATH)
	_check(catalog != null, "P0: کاتالوگ .tres لود می‌شود")
	if catalog == null:
		_finish()
		return
	_check(catalog is ItemCatalog, "P0: کاتالوگ از نوع ItemCatalog است")
	var cat: ItemCatalog = catalog as ItemCatalog
	_check(cat.items.size() == 4, "P0: کاتالوگ دقیقاً ۴ آیتم دارد")
	_check(cat.recipes.size() == 2, "P0: کاتالوگ دقیقاً ۲ دستور دارد")
	_check_item_scrap(cat)
	_check_item_canned(cat)
	_check_item_water(cat)
	_check_item_medkit(cat)
	_check_recipes(cat)
	_finish()


func _check_item_scrap(cat: ItemCatalog) -> void:
	var item: ItemData = cat.get_item(&"scrap_metal")
	_check(item != null, "scrap_metal در کاتالوگ هست")
	if item == null:
		return
	_check(item.item_id == &"scrap_metal", "scrap_metal شناسه‌ی درست دارد")
	_check(item.item_name == "قطعه آهن‌قراضه", "scrap_metal نام درست دارد")
	_check(item.category == ItemData.ItemCategory.SCRAP, "scrap_metal دسته‌ی SCRAP دارد")
	_check(item.max_stack == 10, "scrap_metal max_stack=10 دارد")
	_check(item.is_consumable == false, "scrap_metal غیرقابل‌مصرف است")


func _check_item_canned(cat: ItemCatalog) -> void:
	var item: ItemData = cat.get_item(&"canned_food")
	_check(item != null, "canned_food در کاتالوگ هست")
	if item == null:
		return
	_check(item.item_id == &"canned_food", "canned_food شناسه‌ی درست دارد")
	_check(item.item_name == "کنسرو لوبیا", "canned_food نام درست دارد")
	_check(item.category == ItemData.ItemCategory.FOOD, "canned_food دسته‌ی FOOD دارد")
	_check(item.max_stack == 5, "canned_food max_stack=5 دارد")
	_check(item.is_consumable == true, "canned_food قابل‌مصرف است")


func _check_item_water(cat: ItemCatalog) -> void:
	var item: ItemData = cat.get_item(&"water_bottle")
	_check(item != null, "water_bottle در کاتالوگ هست")
	if item == null:
		return
	_check(item.item_id == &"water_bottle", "water_bottle شناسه‌ی درست دارد")
	_check(item.item_name == "بطری آب معدنی", "water_bottle نام درست دارد")
	_check(item.category == ItemData.ItemCategory.WATER, "water_bottle دسته‌ی WATER دارد")
	_check(item.max_stack == 5, "water_bottle max_stack=5 دارد")
	_check(item.is_consumable == true, "water_bottle قابل‌مصرف است")


func _check_item_medkit(cat: ItemCatalog) -> void:
	var item: ItemData = cat.get_item(&"medkit")
	_check(item != null, "medkit در کاتالوگ هست")
	if item == null:
		return
	_check(item.item_id == &"medkit", "medkit شناسه‌ی درست دارد")
	_check(item.item_name == "جعبه کمک‌های اولیه", "medkit نام درست دارد")
	_check(item.category == ItemData.ItemCategory.MEDKIT, "medkit دسته‌ی MEDKIT دارد")
	_check(item.max_stack == 3, "medkit max_stack=3 دارد")
	_check(item.is_consumable == true, "medkit قابل‌مصرف است")


func _check_recipes(cat: ItemCatalog) -> void:
	var water: RecipeData = cat.get_recipe(&"craft_water_filter")
	_check(water != null, "craft_water_filter در کاتالوگ هست")
	if water == null:
		return
	_check(water.recipe_id == &"craft_water_filter", "craft_water_filter شناسه‌ی درست دارد")
	_check(water.recipe_name == "فیلتر آب", "craft_water_filter نام درست دارد")
	_check(water.result_item_id == &"water_bottle", "craft_water_filter خروجی water_bottle دارد")
	_check(water.result_amount == 1, "craft_water_filter تعداد خروجی ۱ دارد")
	_check(water.ingredients.size() == 1, "craft_water_filter یک ماده لازم دارد")
	_check(water.ingredients.has(&"scrap_metal") and int(water.ingredients[&"scrap_metal"]) == 2,
			"craft_water_filter به ۲ قراضه نیاز دارد")
	_check(water.craft_time == 1.0, "craft_water_filter زمان ساخت کوتاه (۱ ثانیه) دارد")

	var medkit: RecipeData = cat.get_recipe(&"craft_medkit")
	_check(medkit != null, "craft_medkit در کاتالوگ هست")
	if medkit == null:
		return
	_check(medkit.recipe_id == &"craft_medkit", "craft_medkit شناسه‌ی درست دارد")
	_check(medkit.recipe_name == "کیت کمک‌های اولیه ساده", "craft_medkit نام درست دارد")
	_check(medkit.result_item_id == &"medkit", "craft_medkit خروجی medkit دارد")
	_check(medkit.result_amount == 1, "craft_medkit تعداد خروجی ۱ دارد")
	_check(medkit.ingredients.size() == 2, "craft_medkit دو ماده لازم دارد")
	_check(medkit.ingredients.has(&"canned_food") and int(medkit.ingredients[&"canned_food"]) == 1,
			"craft_medkit به ۱ کنسرو نیاز دارد")
	_check(medkit.ingredients.has(&"scrap_metal") and int(medkit.ingredients[&"scrap_metal"]) == 1,
			"craft_medkit به ۱ قراضه نیاز دارد")
	_check(medkit.craft_time == 3.0, "craft_medkit زمان ساخت متوسط (۳ ثانیه) دارد")

	# اتصال دستورها به آیتم‌ها: خروجی‌ها و مواد هر دستور باید در کاتالوگ موجود باشند.
	_check(cat.has_item(water.result_item_id), "خروجی فیلتر آب در کاتالوگ هست")
	_check(cat.has_item(medkit.result_item_id), "خروجی مدکیت در کاتالوگ هست")
	_check(medkit.craft_time > water.craft_time, "زمان ساخت مدکیت بیشتر از فیلتر آب است (متوسط > کوتاه)")


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
		print("ALL TESTS PASSED (item catalog)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
