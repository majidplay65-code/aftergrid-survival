## Interactable
## کلاس پایه‌ی اشیاء قابل تعامل در دنیای سه‌بعدی (Aftergrid).
## هر شیء که بازیکن بتواند با نگاه‌کردن و زدن کلید E با آن تعامل کند از این کلاس استفاده می‌کند.
class_name Interactable
extends StaticBody3D

signal interacted(actor: Node3D)

@export var prompt_message: String = "تعامل"
@export var prompt_action_key: String = "E"
@export var is_interactable: bool = true


func get_prompt_text() -> String:
	return prompt_message


func interact(actor: Node3D) -> void:
	if not is_interactable:
		return
	interacted.emit(actor)
	_on_interact(actor)


## توسط کلاس‌های فرزند override می‌شود.
func _on_interact(_actor: Node3D) -> void:
	pass
