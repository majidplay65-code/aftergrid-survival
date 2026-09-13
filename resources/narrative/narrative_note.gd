## NarrativeNote
## داده‌ی خالص یک یادداشت روایی قابل‌جمع‌آوری (فقط متن — نه گیم‌پلی).
## طبق معماری پروژه: Resource برای داده. جمع‌آوری با همان ItemPickup موجود
## انجام می‌شود؛ این کلاس هیچ رفتار/منطق گیم‌پلی ندارد.
class_name NarrativeNote
extends Resource

## شناسه‌ی پایدار نوت (کلید یکتا برای ارجاع/ذخیره). مثال: &"note_shelter_diary"
@export var note_id: StringName = &""

## عنوان نمایشی نوت (فارسی).
@export var title: String = ""

## متن کامل یادداشت (فارسی).
@export var body: String = ""

## شماره‌ی ترتیب روایی (۱ تا ۵) — فقط برای نمایش/مرتب‌سازی، نه منطق.
@export var order_index: int = 0

## مکان‌نمای کوتاه متن (فارسی) — کجای جهان این نوت پیدا می‌شود.
@export var location_hint: String = ""
