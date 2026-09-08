## RunState
## بازیکن با سرعت دویدن حرکت می‌کند و استامینا مصرف می‌کند.
class_name RunState
extends State

const STAMINA_COST_PER_SECOND: float = 15.0

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, Player.RUN_SPEED)

	var has_stamina: bool = player.stats.consume_stamina(STAMINA_COST_PER_SECOND * delta)

	if not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif not player.is_run_pressed() or not has_stamina:
		state_machine.transition_to(&"WalkState")
