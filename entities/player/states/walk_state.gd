## WalkState
## بازیکن با سرعت راه‌رفتن حرکت می‌کند و استامینا به‌آرامی بازیابی می‌شود.
class_name WalkState
extends State

const STAMINA_REGEN_RATE: float = 10.0

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
			print("Warning: WalkState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func physics_update(delta: float) -> void:
	if not _require_player():
		return
	player.apply_horizontal_movement(delta, Player.WALK_SPEED)
	player.stats.regen_stamina(STAMINA_REGEN_RATE * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif player.wants_jump():
		state_machine.transition_to(&"JumpState")
	elif player.is_crouch_pressed():
		state_machine.transition_to(&"CrouchState")
	elif not player.is_moving():
		state_machine.transition_to(&"IdleState")
	elif player.is_run_pressed() and player.stats.stamina > 5.0:
		state_machine.transition_to(&"RunState")
