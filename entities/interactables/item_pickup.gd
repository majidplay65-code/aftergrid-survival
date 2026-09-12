## ItemPickup
## شیء فیزیکی/محیطی که بازیکن می‌تواند با فشردن کلید تعامل (E) آن را بردارد یا مصرف کند.
class_name ItemPickup
extends Interactable

enum ItemCategory {
	GENERIC,
	WATER,
	FOOD,
	MEDKIT,
	SCRAP,
	BATTERY,
	TOOL
}

## شناسه یکتای آیتم در کاتالوگ (مثلاً water_bottle)
@export var item_id: StringName = &"water_bottle"
## نام نمایشی آیتم در UI و پیام‌ها
@export var item_name: String = "بطری آب معدنی"
## دسته‌بندی آیتم برای تعیین اثر هنگام مصرف
@export var item_category: ItemCategory = ItemCategory.WATER
## تعداد/میزان آیتم موجود در این برداشت
@export var amount: int = 1
## مقدار بازیابی ویژگی‌های بازیکن در صورت مصرف مستقیم
@export var stat_restore_amount: float = 25.0
## آیا هنگام برداشتن فوراً مصرف شود (اختیاری؛ پیش‌فرض false)
@export var is_consumable_on_pickup: bool = false


func _ready() -> void:
	if prompt_message == "تعامل" or prompt_message.is_empty():
		prompt_message = "برداشتن %s" % item_name


func _on_interact(actor: Node3D) -> void:
	if not is_interactable:
		return

	is_interactable = false

	if is_consumable_on_pickup:
		# مسیر قدیمی (فقط اگر صحنه صریحاً true باشد).
		_consume_on_pickup(actor)
		queue_free()
		return

	# یک حقیقت: E = برداشتن به کیف. اگر جا نبود شیء سر جایش می‌ماند.
	if InventoryManager != null and InventoryManager.inventory != null:
		if InventoryManager.inventory.space_for(item_id) < amount:
			is_interactable = true
			EventBus.toast_requested.emit("کیف پر است")
			return
	EventBus.item_picked_up.emit(item_id, amount)
	queue_free()


## مصرف فوری آیتم (آب/غذا/دارو) روی آمار بازیکن + اعلان toast مشترک.
## آیتم مصرفی به اینونتوری اضافه نمی‌شود؛ فقط اثر و اعلان دارد.
func _consume_on_pickup(actor: Node3D) -> void:
	if actor is Player:
		var player: Player = actor as Player
		if player != null and player.stats != null:
			match item_category:
				ItemCategory.WATER:
					player.stats.drink(stat_restore_amount)
				ItemCategory.FOOD:
					player.stats.eat(stat_restore_amount)
				ItemCategory.MEDKIT:
					player.stats.heal(stat_restore_amount)
	EventBus.toast_requested.emit("مصرف شد: %s" % item_name)
