## RadioBeacon
## دلیل شرق: فعال‌سازی با یک قراضه. بدون سلاح گرم.
class_name RadioBeacon
extends Interactable

const COST_ITEM: StringName = &"scrap_metal"
const COST_AMOUNT: int = 1


func _ready() -> void:
	if prompt_message == "تعامل" or prompt_message.is_empty():
		prompt_message = "فعال‌کردن رادیو (۱ قراضه)"


func _on_interact(_actor: Node3D) -> void:
	if GameState.radio_is_on:
		EventBus.toast_requested.emit("سیگنال از قبل فعال است")
		return
	if not InventoryManager.has_item(COST_ITEM, COST_AMOUNT):
		EventBus.toast_requested.emit("برای رادیو ۱ قراضه لازم است")
		return
	InventoryManager.remove_item(COST_ITEM, COST_AMOUNT)
	GameState.radio_is_on = true
	EventBus.radio_activated.emit()
	EventBus.toast_requested.emit("سیگنال زدی — شرق پاسخ داد")
	prompt_message = "رادیو فعال است"
