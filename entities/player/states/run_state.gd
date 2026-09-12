## RunState
## بازیکن با سرعت دویدن حرکت می‌کند و استامینا مصرف می‌کند.
class_name RunState
extends State

const STAMINA_COST_PER_SECOND: float = 15.0

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, Player.RUN_SPEED)

	var has_stamina: bool = player.stats.consume_stamina(STAMINA_COST_PER_SECOND * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif player.is_crouch_pressed():
		state_machine.transition_to(&"CrouchState")
	elif not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif not player.is_run_pressed() or not has_stamina:
		state_machine.transition_to(&"WalkState")
