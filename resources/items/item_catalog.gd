## ItemCatalog
## دیتابیس مرجعِ تعریف آیتم‌ها و دستورهای ساخت — «تنها منبع حقیقت» برای داده‌ی فاز ۶.
## لایه‌های بعدی (Inventory/Crafting/UI) آیتم یا دستور را فقط از همین کاتالوگ می‌گیرند.
## اینجا فقط دسترسیِ فقط‌خواندنی به داده است؛ هیچ تغییری در آیتم‌ها/دستورها نمی‌دهد.
class_name ItemCatalog
extends Resource

## همه‌ی آیتم‌های شناخته‌شده (تعریف، نه نمونه‌ی درون اینونتوری).
@export var items: Array[ItemData] = []

## همه‌ی دستورهای ساخت شناخته‌شده.
@export var recipes: Array[RecipeData] = []


## آیتم با شناسه‌ی داده‌شده را برمی‌گرداند؛ اگر نبود null.
func get_item(item_id: StringName) -> ItemData:
	for item in items:
		if item != null and item.item_id == item_id:
			return item
	return null


## دستور با شناسه‌ی داده‌شده را برمی‌گرداند؛ اگر نبود null.
func get_recipe(recipe_id: StringName) -> RecipeData:
	for recipe in recipes:
		if recipe != null and recipe.recipe_id == recipe_id:
			return recipe
	return null


## آیا آیتمی با این شناسه در کاتالوگ تعریف شده است؟
func has_item(item_id: StringName) -> bool:
	return get_item(item_id) != null


## آیا دستوری با این شناسه در کاتالوگ تعریف شده است؟
func has_recipe(recipe_id: StringName) -> bool:
	return get_recipe(recipe_id) != null
