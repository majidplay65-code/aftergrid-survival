## Workbench
## میز ساخت نزدیک ژنراتور. ساخت از Tab؛ این نود فقط مکان و گروه است.
class_name Workbench
extends Interactable


func _ready() -> void:
	add_to_group(&"workbenches")
	if prompt_message == "تعامل" or prompt_message.is_empty():
		prompt_message = "میز ساخت (Tab)"


func _on_interact(_actor: Node3D) -> void:
	EventBus.toast_requested.emit("نزدیک میز ساخت. Tab را باز کن")
