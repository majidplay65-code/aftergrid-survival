## تست کارکردی headless لایه‌ی داده‌ی فاز ۶ (Inventory/Crafting):
## ItemData، RecipeData و ItemCatalog — بدون نیاز به صحنه یا autoload.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/inventory_data_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»:
## اگر یک تابع به‌خاطر «Invalid call» وسط راه قطع شود، تعداد چک‌ها کم می‌شود و
## این محافظ همان را به FAIL تبدیل می‌کند — چون Godot حتی با SCRIPT ERROR هم
## exit code صفر برمی‌گرداند).
const EXPECTED_CHECK_COUNT: int = 35

var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_test_item_data_defaults()
	_test_item_data_assignment()
	_test_recipe_data_defaults()
	_test_recipe_data_assignment()
	_test_catalog_lookup()
	_finish()


func _test_item_data_defaults() -> void:
	var item: ItemData = ItemData.new()
	_check(item != null, "ItemData ساخته می‌شود")
	_check(item.item_id == &"", "ItemData: شناسه‌ی پیش‌فرض خالی است")
	_check(item.item_name == "", "ItemData: نام پیش‌فرض خالی است")
	_check(item.category == ItemData.ItemCategory.GENERIC, "ItemData: دسته‌ی پیش‌فرض GENERIC است")
	_check(item.max_stack == 1, "ItemData: max_stack پیش‌فرض ۱ است")
	_check(item.is_consumable == false, "ItemData: is_consumable پیش‌فرض false است")


func _test_item_data_assignment() -> void:
	var item: ItemData = ItemData.new()
	item.item_id = &"water_bottle"
	item.item_name = "بطری آب معدنی"
	item.category = ItemData.ItemCategory.WATER
	item.max_stack = 5
	item.is_consumable = true
	_check(item.item_id == &"water_bottle", "ItemData: item_id مقدار می‌گیرد")
	_check(item.item_name == "بطری آب معدنی", "ItemData: item_name مقدار می‌گیرد")
	_check(item.category == ItemData.ItemCategory.WATER, "ItemData: category مقدار می‌گیرد")
	_check(item.max_stack == 5, "ItemData: max_stack مقدار می‌گیرد")
	_check(item.is_consumable == true, "ItemData: is_consumable مقدار می‌گیرد")


func _test_recipe_data_defaults() -> void:
	var recipe: RecipeData = RecipeData.new()
	_check(recipe != null, "RecipeData ساخته می‌شود")
	_check(recipe.recipe_id == &"", "RecipeData: شناسه‌ی پیش‌فرض خالی است")
	_check(recipe.result_amount == 1, "RecipeData: result_amount پیش‌فرض ۱ است")
	_check(recipe.ingredients.is_empty(), "RecipeData: ingredients پیش‌فرض خالی است")
	_check(recipe.craft_time == 0.0, "RecipeData: craft_time پیش‌فرض ۰ است")


func _test_recipe_data_assignment() -> void:
	var recipe: RecipeData = RecipeData.new()
	recipe.recipe_id = &"craft_medkit"
	recipe.recipe_name = "ساخت جعبه کمک‌های اولیه"
	recipe.result_item_id = &"medkit"
	recipe.result_amount = 1
	recipe.ingredients[&"scrap_metal"] = 3
	recipe.ingredients[&"cloth"] = 2
	recipe.craft_time = 2.5
	_check(recipe.recipe_id == &"craft_medkit", "RecipeData: recipe_id مقدار می‌گیرد")
	_check(recipe.result_item_id == &"medkit", "RecipeData: result_item_id مقدار می‌گیرد")
	_check(recipe.result_amount == 1, "RecipeData: result_amount مقدار می‌گیرد")
	_check(recipe.ingredients.has(&"scrap_metal") and recipe.ingredients[&"scrap_metal"] == 3,
			"RecipeData: ingredients کلید/مقدار int نگه می‌دارد")
	_check(recipe.ingredients.has(&"cloth") and recipe.ingredients[&"cloth"] == 2,
			"RecipeData: ingredients چند ماده‌ی لازم را نگه می‌دارد")
	_check(recipe.ingredients.size() == 2, "RecipeData: ingredients دو ماده دارد")
	_check(recipe.craft_time == 2.5, "RecipeData: craft_time مقدار می‌گیرد")


func _test_catalog_lookup() -> void:
	var catalog: ItemCatalog = ItemCatalog.new()
	_check(catalog.items.is_empty(), "ItemCatalog: items پیش‌فرض خالی است")
	_check(catalog.recipes.is_empty(), "ItemCatalog: recipes پیش‌فرض خالی است")
	_check(catalog.get_item(&"water_bottle") == null, "ItemCatalog: آیتم ناشناخته null برمی‌گرداند")
	_check(catalog.has_item(&"water_bottle") == false, "ItemCatalog: has_item برای آیتم ناشناخته false است")

	var water: ItemData = ItemData.new()
	water.item_id = &"water_bottle"
	water.item_name = "بطری آب معدنی"
	var scrap: ItemData = ItemData.new()
	scrap.item_id = &"scrap_metal"
	scrap.item_name = "قطعه آهن‌قراضه"
	catalog.items.append(water)
	catalog.items.append(scrap)

	var recipe: RecipeData = RecipeData.new()
	recipe.recipe_id = &"craft_medkit"
	recipe.result_item_id = &"medkit"
	recipe.ingredients[&"scrap_metal"] = 3
	catalog.recipes.append(recipe)

	var found_water: ItemData = catalog.get_item(&"water_bottle")
	_check(found_water != null and found_water == water, "ItemCatalog: get_item آیتم موجود را برمی‌گرداند")
	_check(catalog.get_item(&"medkit") == null, "ItemCatalog: get_item آیتم غایب null برمی‌گرداند")
	_check(catalog.has_item(&"scrap_metal") == true, "ItemCatalog: has_item برای آیتم موجود true است")
	var found_recipe: RecipeData = catalog.get_recipe(&"craft_medkit")
	_check(found_recipe != null and found_recipe == recipe, "ItemCatalog: get_recipe دستور موجود را برمی‌گرداند")
	_check(catalog.has_recipe(&"craft_medkit") == true, "ItemCatalog: has_recipe برای دستور موجود true است")
	_check(catalog.has_recipe(&"craft_bandage") == false, "ItemCatalog: has_recipe برای دستور غایب false است")
	_check(found_recipe.ingredients.has(&"scrap_metal") and found_recipe.ingredients[&"scrap_metal"] == 3,
			"ItemCatalog: دستورِ یافت‌شده موادش را حفظ می‌کند")


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
		print("ALL TESTS PASSED (inventory data)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
