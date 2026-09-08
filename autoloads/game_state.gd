## GameState
## Autoload برای نگه‌داشتن وضعیت سراسری بازی (نه داده‌ی ذخیره‌شونده روی دیسک).
## نحوه ثبت: Project Settings -> Autoload -> نام "GameState"
extends Node

var is_paused: bool = false:
	set(value):
		is_paused = value
		get_tree().paused = value
		EventBus.game_paused.emit(value)

var current_level_path: String = ""
var player_reference: Node3D = null


func register_player(player: Node3D) -> void:
	player_reference = player


func toggle_pause() -> void:
	is_paused = not is_paused
