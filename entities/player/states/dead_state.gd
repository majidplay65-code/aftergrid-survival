## DeadState
## بازیکن مرده است: بدون ورودی گیم‌پلی، فقط ترمز افقی.
## مسیر: res://entities/player/states/dead_state.gd
class_name DeadState
extends State

@export var player: Player


func physics_update(delta: float) -> void:
	player.apply_horizontal_movement(delta, 0.0, false)
