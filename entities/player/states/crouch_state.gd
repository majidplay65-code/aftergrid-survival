## CrouchState
## بازیکن خزیده حرکت می‌کند: کندتر، کم‌صداتر. استامینا مثل Walk بازیابی می‌شود.
## مسیر: res://entities/player/states/crouch_state.gd
class_name CrouchState
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
			print("Warning: CrouchState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func physics_update(delta: float) -> void:
	if not _require_player():
		return
	var speed: float = Player.CROUCH_SPEED if player.is_moving() else 0.0
	player.apply_horizontal_movement(delta, speed)
	player.stats.regen_stamina(STAMINA_REGEN_RATE * delta)

	if player.is_melee_just_pressed() and player.stats.stamina >= Player.MELEE_STAMINA_COST:
		state_machine.transition_to(&"MeleeState")
	elif not player.is_crouch_pressed():
		if player.is_moving():
			if player.is_run_pressed() and player.stats.stamina > 5.0:
				state_machine.transition_to(&"RunState")
			else:
				state_machine.transition_to(&"WalkState")
		else:
			state_machine.transition_to(&"IdleState")
