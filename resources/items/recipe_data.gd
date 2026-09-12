## RecipeData
## داده‌ی خالصِ یک دستور ساخت (recipe). فقط داده؛ منطق ساخت در لایه‌ی بعدی فاز ۶ می‌آید.
class_name RecipeData
extends Resource

## شناسه‌ی پایدار دستور — مثال: &"craft_medkit"
@export var recipe_id: StringName = &""

## نام نمایشی فارسی دستور.
@export var recipe_name: String = ""

## شناسه‌ی آیتم خروجی (باید در ItemCatalog موجود باشد).
@export var result_item_id: StringName = &""

## تعداد آیتم خروجی از یک بار ساخت.
@export var result_amount: int = 1

## مواد لازم: Dictionary[StringName, int] → شناسه‌ی آیتم به تعداد لازم.
## مثال: { &"scrap_metal": 2, &"cloth": 1 }
@export var ingredients: Dictionary[StringName, int] = {}

## مدت‌زمان ساخت به ثانیه (۰ = ساخت فوری).
@export var craft_time: float = 0.0
