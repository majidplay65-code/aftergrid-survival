## JumpState
## پرش و حرکت هوایی. فرود به Idle/Walk/Run. خزیدن پرش ندارد.
## مسیر: res://entities/player/states/jump_state.gd
class_name JumpState
extends State

@export var player: Player


func enter(_msg: Dictionary = {}) -> void:
	player.start_jump()


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, Player.AIR_CONTROL_SPEED, false)
	player.note_fall_speed()
	if player.is_on_floor() and player.velocity.y <= 0.0:
		player.land_from_jump()
		if player.is_moving():
			if player.is_run_pressed() and player.stats.stamina > 5.0:
				state_machine.transition_to(&"RunState")
			else:
				state_machine.transition_to(&"WalkState")
		else:
			state_machine.transition_to(&"IdleState")
