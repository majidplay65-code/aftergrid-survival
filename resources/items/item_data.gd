## ItemData
## داده‌ی خالصِ تعریف یک آیتم (نه نمونه‌ی آن در دنیا). فقط داده؛ هیچ منطق گیم‌پلی اینجا نیست.
## لایه‌های بعدی فاز ۶ (Inventory/Crafting/UI) از همین Resource برای شناخت آیتم‌ها استفاده می‌کنند.
class_name ItemData
extends Resource

## دسته‌بندی آیتم. ترتیب و مقادیر عمداً با `ItemPickup.ItemCategory` فعلی یکسان نگه داشته شده
## تا در لایه‌ی اتصال، این دو enum بدون تغییر مقدار با هم ادغام شوند.
enum ItemCategory {
	GENERIC,
	WATER,
	FOOD,
	MEDKIT,
	SCRAP,
	BATTERY,
	TOOL,
}

## شناسه‌ی پایدار آیتم — کلید اینونتوری و دستور ساخت. مثال: &"water_bottle"
@export var item_id: StringName = &""

## نام نمایشی فارسی آیتم.
@export var item_name: String = ""

## توضیح کوتاه برای UI (تولتیپ/لیست).
@export var description: String = ""

## دسته‌ی آیتم (برای رفتار مصرف/ساخت در لایه‌های بعدی).
@export var category: ItemCategory = ItemCategory.GENERIC

## حداکثر تعداد قابل انباشت در یک خانه‌ی اینونتوری (۱ = غیرقابل انباشت).
@export var max_stack: int = 1

## آیا این آیتم مصرف‌شدنی است (آب/غذا/دارو)؟ برای آیتم‌های ساخت (مثل قراضه) false می‌ماند.
@export var is_consumable: bool = false

## آیکون برای نمایش در UI (اختیاری؛ در لایه‌ی UI استفاده می‌شود).
@export var icon: Texture2D
