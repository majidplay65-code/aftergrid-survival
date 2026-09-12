## MeleeState
## ضربه‌ی نزدیک: استامینا مصرف می‌شود، نویز ۸ متری، قفل کوتاه سپس Idle.
## مسیر: res://entities/player/states/melee_state.gd
class_name MeleeState
extends State

const RECOVERY_TIME: float = 0.35

@export var player: Player

var _elapsed: float = 0.0


func enter(_msg: Dictionary = {}) -> void:
	_elapsed = 0.0
	player.try_melee()


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, 0.0)
	_elapsed += delta
	if _elapsed >= RECOVERY_TIME:
		if player.is_crouch_pressed():
			state_machine.transition_to(&"CrouchState")
		elif player.is_moving():
			state_machine.transition_to(&"WalkState")
		else:
			state_machine.transition_to(&"IdleState")
