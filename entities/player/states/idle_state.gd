## IdleState
## بازیکن ساکن است؛ فقط اصطکاک اعمال می‌شود و منتظر ورودی حرکت می‌ماند.
class_name IdleState
extends State

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, 0.0)

	if player.is_moving():
		if player.is_run_pressed():
			state_machine.transition_to(&"RunState")
		else:
			state_machine.transition_to(&"WalkState")
