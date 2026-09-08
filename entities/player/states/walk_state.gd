## WalkState
## بازیکن با سرعت راه‌رفتن حرکت می‌کند.
class_name WalkState
extends State

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, Player.WALK_SPEED)

	if not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif player.is_run_pressed():
		state_machine.transition_to(&"RunState")
