## IdleState
## بازیکن ساکن است؛ اصطکاک اعمال می‌شود و استامینا با سرعت بازیابی می‌شود.
class_name IdleState
extends State

const STAMINA_REGEN_RATE: float = 16.0

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, 0.0)
	player.stats.regen_stamina(STAMINA_REGEN_RATE * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif player.is_crouch_pressed():
		state_machine.transition_to(&"CrouchState")
	elif player.is_moving():
		if player.is_run_pressed():
			state_machine.transition_to(&"RunState")
		else:
			state_machine.transition_to(&"WalkState")
