## DayCycle
## رفتار چرخهٔ شب: WorldClock را جلو می‌برد و نور محیط را از روی Resource عوض می‌کند.
extends Node

var clock: WorldClock = WorldClock.new()
var _environment: Environment = null
var _sun: DirectionalLight3D = null
var _previous_time: float = 0.40


func _ready() -> void:
	_previous_time = clock.time_of_day
	var level: Node = get_parent()
	if level != null:
		var world_env: WorldEnvironment = level.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if world_env != null:
			_environment = world_env.environment
		_sun = level.get_node_or_null("Sun") as DirectionalLight3D
	if not EventBus.rest_requested.is_connected(_on_rest_requested):
		EventBus.rest_requested.connect(_on_rest_requested)
	apply_lighting()


func _process(delta: float) -> void:
	_previous_time = clock.time_of_day
	clock.advance(delta)
	_after_time_changed()


func set_time_of_day(value: float) -> void:
	_previous_time = clock.time_of_day
	clock.time_of_day = fmod(value, 1.0)
	if clock.time_of_day < 0.0:
		clock.time_of_day += 1.0
	_after_time_changed()


func _on_rest_requested(time_skip: float) -> void:
	set_time_of_day(fmod(clock.time_of_day + time_skip, 1.0))


func apply_lighting() -> void:
	var darkness: float = clock.night_factor()
	if _environment != null:
		_environment.ambient_light_energy = lerpf(0.5, 0.08, darkness)
	if _sun != null:
		_sun.light_energy = lerpf(1.4, 0.05, darkness)


func _after_time_changed() -> void:
	EventBus.time_of_day_changed.emit(clock.time_of_day)
	apply_lighting()
	_maybe_survive_night()


func _maybe_survive_night() -> void:
	const DAWN: float = 0.25
	var previous: float = _previous_time
	var current: float = clock.time_of_day
	# فقط عبور روبه‌جلو از سپیده (نه پرش دلخواه زمان).
	if not (previous < DAWN and current >= DAWN and current >= previous):
		return
	if previous >= 0.20:
		return
	var survived: int = GameState.night_index
	GameState.night_index += 1
	EventBus.night_survived.emit(survived)
