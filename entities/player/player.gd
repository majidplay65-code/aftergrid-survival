## Player
## کنترلر اصلی بازیکن. حرکت خام اینجاست؛ منطق حالت (idle/walk/run)
## در فرزندان StateMachine پیاده‌سازی می‌شود.
##
## ساختار مورد انتظار در Scene Tree:
## Player (CharacterBody3D, این اسکریپت)
## ├── CollisionShape3D
## ├── CameraPivot (Node3D)
## │   └── Camera3D
## └── StateMachine
##     ├── IdleState
##     ├── WalkState
##     └── RunState
class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 3.5
const RUN_SPEED: float = 6.5
const ACCELERATION: float = 10.0
const FRICTION: float = 12.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.0025

@export var stats: PlayerStats = PlayerStats.new()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var state_machine: StateMachine = $StateMachine

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)
	stats.stat_changed.connect(_on_stat_changed)
	stats.died.connect(_on_died)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()


## جهت ورودی خام را در فضای محلی بازیکن برمی‌گرداند (بدون نرمال‌سازی سرعت).
func get_input_direction() -> Vector3:
	var input_vector: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	return direction


## حرکت افقی را با شتاب/اصطکاک به سمت سرعت هدف می‌برد. توسط State ها فراخوانی می‌شود.
func apply_horizontal_movement(delta: float, target_speed: float) -> void:
	var direction: Vector3 = get_input_direction()

	if direction.length() > 0.01:
		var target_velocity: Vector3 = direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)


func is_moving() -> bool:
	return get_input_direction().length() > 0.01


func is_run_pressed() -> bool:
	return Input.is_action_pressed(&"run")


func _on_stat_changed(stat_name: StringName, current_value: float, max_value: float) -> void:
	EventBus.player_stat_changed.emit(stat_name, current_value, max_value)


func _on_died() -> void:
	EventBus.player_died.emit()
