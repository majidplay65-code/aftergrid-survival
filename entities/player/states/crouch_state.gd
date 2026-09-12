## CrouchState
## بازیکن خزیده حرکت می‌کند: کندتر، کم‌صداتر. استامینا مثل Walk بازیابی می‌شود.
## مسیر: res://entities/player/states/crouch_state.gd
class_name CrouchState
extends State

const STAMINA_REGEN_RATE: float = 10.0

@export var player: Player


func physics_update(delta: float) -> void:
	var speed: float = Player.CROUCH_SPEED if player.is_moving() else 0.0
	player.apply_horizontal_movement(delta, speed)
	player.stats.regen_stamina(STAMINA_REGEN_RATE * delta)

	if not player.is_crouch_pressed():
		if player.is_moving():
			if player.is_run_pressed() and player.stats.stamina > 5.0:
				state_machine.transition_to(&"RunState")
			else:
				state_machine.transition_to(&"WalkState")
		else:
			state_machine.transition_to(&"IdleState")
