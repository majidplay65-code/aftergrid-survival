## DeadState
## بازیکن مرده است: بدون ورودی گیم‌پلی، فقط ترمز افقی.
## مسیر: res://entities/player/states/dead_state.gd
class_name DeadState
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
			print("Warning: DeadState: 'player' export is null/unset — safe fallback (skipping updates).")
		return false
	return true


func physics_update(delta: float) -> void:
	if not _require_player():
		return
	player.apply_horizontal_movement(delta, 0.0, false)
