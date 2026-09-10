## Player
## کنترلر اصلی بازیکن (Aftergrid).
## حرکت، پرش، آمار بقا، چرخش زاویه دید و سیستم تعامل با اشیاء دنیای سه‌بعدی.
class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 3.5
const RUN_SPEED: float = 6.5
const ACCELERATION: float = 10.0
const FRICTION: float = 12.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.0025

# نرخ مصرف حیاتی در هر ثانیه
const THIRST_DECAY_RATE: float = 0.25
const HUNGER_DECAY_RATE: float = 0.12

@export var stats: PlayerStats = PlayerStats.new()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var state_machine: StateMachine = $StateMachine
@onready var interaction_raycast: RayCast3D = $CameraPivot/Camera3D/InteractionRayCast
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var focused_interactable: Interactable = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)
	stats.stat_changed.connect(_on_stat_changed)
	stats.died.connect(_on_died)

	if interaction_raycast != null:
		interaction_raycast.add_exception(self)

	# ارسال وضعیت اولیه برای مقداردهی UI
	call_deferred(&"_emit_initial_stats")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	# کلید تعامل با اشیاء محیطی (E)
	if event.is_action_pressed(&"interact"):
		_try_interact()

	# کلید چراغ‌قوه (F) — روشن/خاموش کردن نور دوربین
	if event.is_action_pressed(&"flashlight") and flashlight != null:
		flashlight.visible = not flashlight.visible


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# افت تدریجی آب و غذا در طول زمان (گیم‌پلی بقا)
	stats.decrease_thirst(THIRST_DECAY_RATE * delta)
	stats.decrease_hunger(HUNGER_DECAY_RATE * delta)

	_update_interaction_raycast()
	move_and_slide()


## جهت ورودی خام را در فضای محلی بازیکن برمی‌گرداند.
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


## بررسی پرتو نگاه بازیکن برای تشخیص شیء تعاملی روبه‌رو
func _update_interaction_raycast() -> void:
	if interaction_raycast == null:
		return

	if interaction_raycast.is_colliding():
		var collider: Object = interaction_raycast.get_collider()
		if collider is Interactable and collider.is_interactable:
			if focused_interactable != collider:
				focused_interactable = collider
				EventBus.interactable_focused.emit(collider.get_prompt_text())
			return

	if focused_interactable != null:
		focused_interactable = null
		EventBus.interactable_unfocused.emit()


## اجرای تعامل با شیء هدف
func _try_interact() -> void:
	if focused_interactable != null and is_instance_valid(focused_interactable) and focused_interactable.is_interactable:
		var target: Interactable = focused_interactable
		target.interact(self)
		EventBus.interaction_performed.emit(target)
		_update_interaction_raycast()


func _emit_initial_stats() -> void:
	EventBus.player_stat_changed.emit(&"health", stats.health, stats.max_health)
	EventBus.player_stat_changed.emit(&"stamina", stats.stamina, stats.max_stamina)
	EventBus.player_stat_changed.emit(&"hunger", stats.hunger, stats.max_hunger)
	EventBus.player_stat_changed.emit(&"thirst", stats.thirst, stats.max_thirst)


func _on_stat_changed(stat_name: StringName, current_value: float, max_value: float) -> void:
	EventBus.player_stat_changed.emit(stat_name, current_value, max_value)


func _on_died() -> void:
	EventBus.player_died.emit()
