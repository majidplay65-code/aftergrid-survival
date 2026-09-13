## MeleeState
## ضربه‌ی نزدیک: استامینا مصرف می‌شود، نویز ۸ متری، قفل کوتاه سپس Idle.
## مسیر: res://entities/player/states/melee_state.gd
class_name MeleeState
extends State

const RECOVERY_TIME: float = 0.35

@export var player: Player
## guard state: true اگر `player` در لحظه‌ی فعال‌شدن guard مقدار null/unset بود
## و مسیر fallback امن اجرا شد (برای تست tests/null_guard_states_test.gd).
var player_missing: bool = false
var _player_missing_warned: bool = false

var _elapsed: float = 0.0


func _require_player() -> bool:
	if player == null:
		player_missing = true
		if not _player_missing_warned:
			_player_missing_warned = true
			print("Warning: MeleeState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func enter(_msg: Dictionary = {}) -> void:
	if not _require_player():
		return
	_elapsed = 0.0
	player.try_melee()


func physics_update(delta: float) -> void:
	if not _require_player():
		return
	player.apply_horizontal_movement(delta, 0.0)
	_elapsed += delta
	if _elapsed >= RECOVERY_TIME:
		if player.is_crouch_pressed():
			state_machine.transition_to(&"CrouchState")
		elif player.is_moving():
			state_machine.transition_to(&"WalkState")
		else:
			state_machine.transition_to(&"IdleState")
