## WalkState
## بازیکن با سرعت راه‌رفتن حرکت می‌کند و استامینا به‌آرامی بازیابی می‌شود.
class_name WalkState
extends State

const STAMINA_REGEN_RATE: float = 10.0

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, Player.WALK_SPEED)
	player.stats.regen_stamina(STAMINA_REGEN_RATE * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif player.is_crouch_pressed():
		state_machine.transition_to(&"CrouchState")
	elif not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif player.is_run_pressed() and player.stats.stamina > 5.0:
		state_machine.transition_to(&"RunState")
