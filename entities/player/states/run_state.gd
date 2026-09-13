## RunState
## بازیکن با سرعت دویدن حرکت می‌کند و استامینا مصرف می‌کند.
class_name RunState
extends State

const STAMINA_COST_PER_SECOND: float = 15.0

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
			print("Warning: RunState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func physics_update(delta: float) -> void:
	if not _require_player():
		return
	player.apply_horizontal_movement(delta, Player.RUN_SPEED)

	var has_stamina: bool = player.stats.consume_stamina(STAMINA_COST_PER_SECOND * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif player.wants_jump():
		state_machine.transition_to(&"JumpState")
	elif player.is_crouch_pressed():
		state_machine.transition_to(&"CrouchState")
	elif not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif not player.is_run_pressed() or not has_stamina:
		state_machine.transition_to(&"WalkState")
