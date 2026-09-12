## CraftingSystem
## لایه‌ی منطق ساخت (Crafting) فاز ۶: با گرفتن یک RecipeData و یک Inventory بررسی
## می‌کند که آیا مواد اولیه به‌اندازه‌ی کافی هست (can_craft) و اگر هست، مواد را کم و
## خروجی را اضافه می‌کند (craft). نتیجه از طریق سیگنال‌های موجود EventBus اعلام می‌شود:
## موفقیت → item_crafted(recipe_id)، شکست → craft_failed(recipe_id, reason).
##
## عملیات اتمیک است: اول بررسی کامل (مواد + خروجی + ظرفیت)، بعد commit؛
## در صورت خطای غیرمنتظره‌ی حین commit، هر چیزی که کم شده بود بازگردانده می‌شود.
## (اتصال به Player/UI در لایه‌ی بعدی فاز ۶ انجام می‌شود؛ اینجا فقط منطق خالص.)
##
## توجه: این اسکریپت عمداً `class_name` ندارد — چون به‌عنوان Autoload با همین نام
## (CraftingSystem) ثبت می‌شود و class_nameِ همنام با autoload در Godot 4 خطای
## «Class hides an autoload singleton» می‌دهد (الگوی موجود: autoloadهای قبلی هم ندارند).
extends Node

## دلیل‌های شکست ساخت — به‌عنوان ثابت‌های پروژه برای جلوگیری از اشتباه تایپی.
const FAIL_INSUFFICIENT_MATERIALS: String = "insufficient_materials"
const FAIL_UNKNOWN_RECIPE: String = "unknown_recipe"
const FAIL_NO_INVENTORY: String = "no_inventory"
const FAIL_RESULT_ITEM_UNKNOWN: String = "result_item_unknown"
const FAIL_INVENTORY_FULL: String = "inventory_full"

## مسیر کاتالوگ واقعی — برای autoload که نمی‌تواند @export از بیرون بگیرد.
const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## کاتالوگ مرجع برای اعتبارسنجی دستور/خروجی؛ در autoload از CATALOG_PATH لود می‌شود،
## در تست‌ها از بیرون ست می‌شود.
@export var catalog: ItemCatalog = null


func _ready() -> void:
	# در حالت autoload کاتالوگ از بیرون ست نمی‌شود؛ از داده‌ی واقعی لودش می‌کنیم.
	if catalog == null:
		var loaded: Resource = load(CATALOG_PATH)
		if loaded is ItemCatalog:
			catalog = loaded as ItemCatalog


## بررسی فقط‌خواندنی: آیا مواد اولیه‌ی این دستور به‌اندازه‌ی کافی در اینونتوری هست؟
## هیچ تغییری روی Inventory اعمال نمی‌کند.
func can_craft(recipe: RecipeData, inventory: Inventory) -> bool:
	if recipe == null or inventory == null:
		return false
	for item_id in recipe.ingredients:
		var needed: int = int(recipe.ingredients[item_id])
		if inventory.count_item(item_id) < needed:
			return false
	return true


## تلاش برای ساخت. در موفقیت true و emit سیگنال item_crafted؛
## در شکست false و emit سیگنال craft_failed با دلیل مشخص.
func craft(recipe: RecipeData, inventory: Inventory) -> bool:
	if recipe == null:
		_emit_failure(null, FAIL_UNKNOWN_RECIPE)
		return false
	if inventory == null:
		_emit_failure(recipe, FAIL_NO_INVENTORY)
		return false
	# ۱) بررسی کامل مواد — بدون هیچ تغییری (پیش‌شرط اتمیک بودن)
	if not can_craft(recipe, inventory):
		_emit_failure(recipe, FAIL_INSUFFICIENT_MATERIALS)
		return false
	# ۲) اعتبار خروجی
	if not _validate_result(recipe):
		_emit_failure(recipe, FAIL_RESULT_ITEM_UNKNOWN)
		return false
	# ۳) ظرفیت خروجی (اگر جا نبود، شکست بدون دست‌زدن به مواد)
	if not _result_fits(recipe, inventory):
		_emit_failure(recipe, FAIL_INVENTORY_FULL)
		return false
	# ۴) commit: کم کردن مواد و افزودن خروجی؛ در صورت خطای غیرمنتظره بازگردانی کامل
	var removed_log: Dictionary[StringName, int] = {}
	for item_id in recipe.ingredients:
		var needed: int = int(recipe.ingredients[item_id])
		var removed: int = inventory.remove_item(item_id, needed)
		if removed != needed:
			_rollback(removed_log, inventory)
			_emit_failure(recipe, FAIL_INSUFFICIENT_MATERIALS)
			return false
		removed_log[item_id] = removed
	var added: int = inventory.add_item(recipe.result_item_id, recipe.result_amount)
	if added != recipe.result_amount:
		_rollback(removed_log, inventory)
		_emit_failure(recipe, FAIL_INVENTORY_FULL)
		return false
	EventBus.item_crafted.emit(recipe.recipe_id)
	# نویز ساخت آیتم (۱۰ متر) — منبع از کنش موجود، نه شلیک.
	var player: Node3D = GameState.player_reference
	if player != null and is_instance_valid(player):
		EventBus.noise_emitted.emit(player.global_position, 10.0)
	return true


## خروجی معتبر است؟ (شناسه‌ی غیرخالی، تعداد مثبت، و — اگر کاتالوگ داریم — شناخته‌شده)
func _validate_result(recipe: RecipeData) -> bool:
	if recipe.result_item_id == &"":
		return false
	if recipe.result_amount <= 0:
		return false
	if catalog != null and not catalog.has_item(recipe.result_item_id):
		return false
	return true


## آیا خروجی کامل (result_amount) در اینونتوری جا دارد؟
func _result_fits(recipe: RecipeData, inventory: Inventory) -> bool:
	return inventory.space_for(recipe.result_item_id) >= recipe.result_amount


## بازگردانی مواد کم‌شده (فقط در مسیر خطای غیرمنتظره‌ی commit صدا زده می‌شود).
func _rollback(removed_log: Dictionary[StringName, int], inventory: Inventory) -> void:
	for item_id in removed_log:
		inventory.add_item(item_id, int(removed_log[item_id]))


## emit سیگنال شکست با شناسه‌ی امن (برای دستور null، شناسه‌ی خالی).
func _emit_failure(recipe: RecipeData, reason: String) -> void:
	var recipe_id: StringName = recipe.recipe_id if recipe != null else &""
	EventBus.craft_failed.emit(recipe_id, reason)
