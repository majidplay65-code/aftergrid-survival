## Inventory
## ظرف داده‌ی آیتم‌های بازیکن در زمان اجرا: Dictionary[StringName, int] → شناسه‌ی آیتم به تعداد.
## منطق add/remove/stack اینجا است؛ سقف انباشت (max_stack) از ItemCatalog خوانده می‌شود.
## این Resource وضعیتِ درون‌حافظه است (انتقال به SaveData در لایه‌ی «اتصال» انجام می‌شود).
class_name Inventory
extends Resource

## بعد از هر تغییر واقعی محتوا emit می‌شود (افزودن/حذفِ > ۰).
## (نام `contents_changed` عمداً انتخاب شد، نه `changed` — چون `Resource` از قبل
## سیگنالِ داخلیِ `changed` دارد و سایه‌انداختن روی آن، تحلیل عضو را در کلاس‌های
## بیرونی می‌شکند: «Could not resolve external class member».)
signal contents_changed

## کاتالوگ مرجع برای دانستن max_stack هر آیتم؛ اگر null باشد انباشت عملاً نامحدود است.
var catalog: ItemCatalog = null

## محتوای اینونتوری: شناسه‌ی آیتم → تعداد.
var items: Dictionary[StringName, int] = {}

## سقف انباشت وقتی کاتالوگ/آیتم مشخص نیست.
const UNLIMITED_STACK: int = 2147483647


func _init() -> void:
	# ساخت صریح در _init تا هر نمونه Dictionary مستقل خودش را داشته باشد.
	items = {}


## تعداد فعلی یک آیتم (۰ اگر نبود).
func count_item(item_id: StringName) -> int:
	return int(items.get(item_id, 0))


## آیا حداقل amount واحد از آیتم موجود است؟
func has_item(item_id: StringName, amount: int = 1) -> bool:
	return count_item(item_id) >= amount


## تعدادِ واقعی اضافه‌شده را برمی‌گرداند. سقف انباشت رعایت می‌شود؛
## اگر جا نبود ۰ برمی‌گردد و هیچ تغییری/سیگنالی رخ نمی‌دهد.
func add_item(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var current: int = count_item(item_id)
	var space: int = _max_stack_for(item_id) - current
	var added: int = amount if amount < space else space
	if added <= 0:
		return 0
	items[item_id] = current + added
	contents_changed.emit()
	return added


## تعدادِ واقعی حذف‌شده را برمی‌گرداند. اگر کمتر از amount موجود بود، همان موجود حذف می‌شود؛
## اگر چیزی نبود ۰ برمی‌گردد و هیچ سیگنالی emit نمی‌شود.
func remove_item(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var current: int = count_item(item_id)
	if current <= 0:
		return 0
	var removed: int = current if current < amount else amount
	var remaining: int = current - removed
	if remaining <= 0:
		items.erase(item_id)
	else:
		items[item_id] = remaining
	contents_changed.emit()
	return removed


## کپی (نه رفرنس) از محتوای اینونتوری — تا صداکننده نتواند داده‌ی داخلی را دستکاری کند.
## خروجی یک Dictionary ساده (untyped) است تا سریالایزِ امن در SaveData (ذخیره‌ی .tres)
## بدون درگیرشدن با Dictionary تایپ‌شده انجام شود.
func get_items() -> Dictionary:
	var plain: Dictionary = {}
	for item_id in items:
		plain[item_id] = items[item_id]
	return plain


func is_empty() -> bool:
	return items.is_empty()


## مجموع تعداد همه‌ی آیتم‌ها.
func total_count() -> int:
	var total: int = 0
	for item_id in items:
		total += int(items[item_id])
	return total


## ظرفیت باقی‌مانده برای افزودن یک آیتم (max_stack - تعداد فعلی)؛
## اگر سقفی نباشد (کاتالوگ/آیتم نامشخص یا max_stack غیرمثبت) UNLIMITED_STACK برمی‌گردد.
func space_for(item_id: StringName) -> int:
	var max_stack: int = _max_stack_for(item_id)
	if max_stack == UNLIMITED_STACK:
		return UNLIMITED_STACK
	return max_stack - count_item(item_id)


## جایگزینی کامل محتوای اینونتوری با داده‌ی سیو (فاز ۶ — لایه‌ی اتصال).
## مقادیر غیرمثبت حذف و مقدارها به سقف max_stack محدود می‌شوند؛ سپس contents_changed
## emit می‌شود تا سیستم‌های گوش‌دهنده (UI/EventBus) از بازیابی مطلع شوند.
func restore_items(saved_items: Dictionary) -> void:
	var restored: Dictionary[StringName, int] = {}
	for item_id in saved_items:
		var amount: int = int(saved_items[item_id])
		if amount <= 0:
			continue
		var max_stack: int = _max_stack_for(item_id)
		var stored: int = amount if amount < max_stack else max_stack
		if stored > 0:
			restored[item_id] = stored
	items = restored
	contents_changed.emit()


## سقف انباشت یک آیتم از کاتالوگ؛ اگر کاتالوگ/آیتم نبود یا max_stack غیرمثبت بود → نامحدود.
func _max_stack_for(item_id: StringName) -> int:
	if catalog == null:
		return UNLIMITED_STACK
	var item: ItemData = catalog.get_item(item_id)
	if item == null or item.max_stack <= 0:
		return UNLIMITED_STACK
	return item.max_stack
