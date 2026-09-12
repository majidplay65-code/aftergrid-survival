## AudioManager
## Autoload پخش صدای event-driven. به EventBus گوش می‌دهد؛ سیستم‌های دیگر
## مستقیماً این نود را صدا نمی‌زنند.
## مسیر: res://autoloads/audio_manager.gd
extends Node

const FOOTSTEP_WALK: String = "res://assets/audio/footstep_walk.wav"
const FOOTSTEP_RUN: String = "res://assets/audio/footstep_run.wav"
const CRAFT: String = "res://assets/audio/craft.wav"
const PICKUP: String = "res://assets/audio/pickup.wav"
const UI_CLICK: String = "res://assets/audio/ui_click.wav"
const HIT: String = "res://assets/audio/hit.wav"
const PAUSE_WHOOSH: String = "res://assets/audio/pause_whoosh.wav"

var _last_health: float = 100.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# در headless درایور صدا نیست؛ پخش می‌تواند WARNING بدهد و CI را قرمز کند.
	if DisplayServer.get_name() == "headless":
		return
	EventBus.footstep_played.connect(_on_footstep_played)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_crafted.connect(_on_item_crafted)
	EventBus.player_stat_changed.connect(_on_player_stat_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_paused.connect(_on_game_paused)


func _on_footstep_played(is_running: bool) -> void:
	var path: String = FOOTSTEP_RUN if is_running else FOOTSTEP_WALK
	var pitch: float = 1.08 if is_running else 0.96
	_play(path, pitch)


func _on_item_picked_up(_item_id: StringName, _amount: int) -> void:
	_play(PICKUP, 1.0)


func _on_item_crafted(_recipe_id: StringName) -> void:
	_play(CRAFT, 1.0)


func _on_player_stat_changed(stat_name: StringName, current_value: float, _max_value: float) -> void:
	if stat_name != &"health":
		return
	if current_value < _last_health - 0.5:
		_play(HIT, 1.0)
	_last_health = current_value


func _on_player_died() -> void:
	_play(HIT, 0.8)


func _on_game_paused(is_paused: bool) -> void:
	_play(PAUSE_WHOOSH if is_paused else UI_CLICK, 1.0)


## پخش یک‌باره؛ نود پخش‌کننده بعد از اتمام آزاد می‌شود.
func _play(path: String, pitch: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: Resource = load(path)
	if stream == null or not (stream is AudioStream):
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream as AudioStream
	player.pitch_scale = pitch
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
