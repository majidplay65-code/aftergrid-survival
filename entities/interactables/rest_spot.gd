## RestSpot
## پناه. فقط EventBus: rest_requested. نویز صفر.
class_name RestSpot
extends Interactable

@export var hunger_restore: float = 8.0
@export var thirst_restore: float = 8.0
@export var time_skip: float = 0.08


func _ready() -> void:
	if prompt_message == "تعامل" or prompt_message.is_empty():
		prompt_message = "استراحت"


func _on_interact(actor: Node3D) -> void:
	if actor is Player:
		var player: Player = actor as Player
		if player.is_dead:
			return
		player.stats.eat(hunger_restore)
		player.stats.drink(thirst_restore)
	EventBus.rest_requested.emit(time_skip)
	EventBus.toast_requested.emit("استراحت کردی")
