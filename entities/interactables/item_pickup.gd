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

@export var item_id: StringName = &"water_bottle"
@export var item_name: String = "بطری آب معدنی"
@export var item_category: ItemCategory = ItemCategory.WATER
@export var amount: int = 1
@export var stat_restore_amount: float = 25.0
@export var is_consumable_on_pickup: bool = true


func _ready() -> void:
	if prompt_message == "تعامل" or prompt_message.is_empty():
		prompt_message = "برداشتن %s" % item_name


func _on_interact(actor: Node3D) -> void:
	if not is_interactable:
		return

	is_interactable = false

	# در صورتی که آیتم مصرفی فوری باشد، اثر روی آمار بازیکن اعمال می‌شود
	if is_consumable_on_pickup and actor is Player:
		var player: Player = actor as Player
		match item_category:
			ItemCategory.WATER:
				player.stats.drink(stat_restore_amount)
			ItemCategory.FOOD:
				player.stats.eat(stat_restore_amount)
			ItemCategory.MEDKIT:
				player.stats.heal(stat_restore_amount)

	# ارسال سیگنال دریافت آیتم به اتوبوس رویداد (برای UI و اینونتوری)
	EventBus.item_picked_up.emit(item_id, amount)

	# حذف شیء از دنیای بازی
	queue_free()
