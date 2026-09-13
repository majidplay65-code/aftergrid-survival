## JumpState
## پرش و حرکت هوایی. فرود به Idle/Walk/Run. خزیدن پرش ندارد.
## مسیر: res://entities/player/states/jump_state.gd
class_name JumpState
extends State

@export var player: Player
## guard state: true اگر `player` در لحظه‌ی فعال‌شدن guard مقدار null/unset بود
## و مسیر fallback امن اجرا شد (برای تست tests/null_guard_states_test.gd).
var player_missing: bool = false
var _player_missing_warned: bool = false


func _require_player() -> bool:
	if player == null:
		player_missing = true
		if not _player_missing_warned:
			_player_missing_warned = true
			print("Warning: JumpState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func enter(_msg: Dictionary = {}) -> void:
	if not _require_player():
		return
	player.start_jump()


func physics_update(delta: float) -> void:
	if not _require_player():
		return
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
