## Player
## کنترلر اصلی بازیکن (Aftergrid).
## حرکت، پرش، آمار بقا، چرخش زاویه دید و سیستم تعامل با اشیاء دنیای سه‌بعدی.
class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 3.5
const RUN_SPEED: float = 6.5
const CROUCH_SPEED: float = 1.6
const ACCELERATION: float = 10.0
const FRICTION: float = 12.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.0025
const WALK_FOV: float = 75.0
const RUN_FOV: float = 85.0
const STAND_PIVOT_Y: float = 1.6
const CROUCH_PIVOT_Y: float = 1.05
const STAND_CAPSULE_HEIGHT: float = 1.8
const CROUCH_CAPSULE_HEIGHT: float = 1.2
const FLASHLIGHT_DRAIN_RATE: float = 8.0
const MAX_FLASHLIGHT_BATTERY: float = 100.0

# نرخ مصرف حیاتی در هر ثانیه
const THIRST_DECAY_RATE: float = 0.25
const HUNGER_DECAY_RATE: float = 0.12

@export var stats: PlayerStats = PlayerStats.new()

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var state_machine: StateMachine = $StateMachine
@onready var interaction_raycast: RayCast3D = $CameraPivot/Camera3D/InteractionRayCast
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var focused_interactable: Interactable = null
## تایمر فاصله‌ی قدم‌ها برای emit نویز (نه polling تشخیص دشمن).
var _footstep_timer: float = 0.0
var flashlight_battery: float = MAX_FLASHLIGHT_BATTERY


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)
	stats.stat_changed.connect(_on_stat_changed)
	stats.died.connect(_on_died)
	EventBus.generator_charge_requested.connect(_on_generator_charge_requested)
	EventBus.item_consumed.connect(_on_item_consumed)

	if interaction_raycast != null:
		interaction_raycast.add_exception(self)

	# ارسال وضعیت اولیه برای مقداردهی UI
	call_deferred(&"_emit_initial_stats")


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_paused:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

	# ESC را HUD برای منوی توقف می‌گیرد؛ اینجا موس را toggle نمی‌کنیم.
	# بازگیری موس با کلیک فقط وقتی بازی متوقف نیست.
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# کلید تعامل با اشیاء محیطی (E)
	if event.is_action_pressed(&"interact"):
		_try_interact()

	# کلید چراغ‌قوه (F) — روشن/خاموش کردن نور دوربین (بدون باتری روشن نمی‌شود)
	if event.is_action_pressed(&"flashlight") and flashlight != null:
		_toggle_flashlight()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# افت تدریجی آب و غذا در طول زمان (گیم‌پلی بقا)
	stats.decrease_thirst(THIRST_DECAY_RATE * delta)
	stats.decrease_hunger(HUNGER_DECAY_RATE * delta)

	_update_flashlight_battery(delta)
	_update_interaction_raycast()
	_update_run_fov(delta)
	_update_crouch_pose(delta)
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
		if target_speed >= RUN_SPEED:
			_tick_footstep_noise(delta, 14.0, 0.32, true)
		elif target_speed >= WALK_SPEED:
			_tick_footstep_noise(delta, 6.0, 0.48, false)
		elif target_speed >= CROUCH_SPEED:
			_tick_footstep_noise(delta, 2.5, 0.7, false)
	else:
		_footstep_timer = 0.0
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)


## نویز قدم از کنش موجود (راه‌رفتن/دویدن) — بدون فرض شلیک.
func _tick_footstep_noise(delta: float, loudness: float, interval: float, is_running: bool) -> void:
	_footstep_timer += delta
	if _footstep_timer >= interval:
		_footstep_timer = 0.0
		EventBus.noise_emitted.emit(global_position, loudness)
		EventBus.footstep_played.emit(is_running)


## FOV نرم هنگام دویدن (Game Feel).
func _update_run_fov(delta: float) -> void:
	if camera_3d == null:
		return
	var target_fov: float = RUN_FOV if is_run_pressed() and is_moving() and not is_crouch_pressed() else WALK_FOV
	camera_3d.fov = lerpf(camera_3d.fov, target_fov, clampf(8.0 * delta, 0.0, 1.0))


## دوربین و کپسول برخورد را نرم به حالت خزیده/ایستاده می‌برد.
func _update_crouch_pose(delta: float) -> void:
	var crouched: bool = is_crouch_pressed()
	var target_pivot_y: float = CROUCH_PIVOT_Y if crouched else STAND_PIVOT_Y
	var target_height: float = CROUCH_CAPSULE_HEIGHT if crouched else STAND_CAPSULE_HEIGHT
	var t: float = clampf(10.0 * delta, 0.0, 1.0)
	if camera_pivot != null:
		var pivot_pos: Vector3 = camera_pivot.position
		pivot_pos.y = lerpf(pivot_pos.y, target_pivot_y, t)
		camera_pivot.position = pivot_pos
	if collision_shape != null and collision_shape.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
		capsule.height = lerpf(capsule.height, target_height, t)
		var shape_pos: Vector3 = collision_shape.position
		shape_pos.y = lerpf(shape_pos.y, (target_height - STAND_CAPSULE_HEIGHT) * 0.5, t)
		collision_shape.position = shape_pos


func is_moving() -> bool:
	return get_input_direction().length() > 0.01


func is_run_pressed() -> bool:
	return Input.is_action_pressed(&"run")


func is_crouch_pressed() -> bool:
	return Input.is_action_pressed(&"crouch")


func _toggle_flashlight() -> void:
	if flashlight.visible:
		flashlight.visible = false
		return
	if flashlight_battery <= 0.0:
		EventBus.toast_requested.emit("باتری چراغ‌قوه خالی است")
		return
	flashlight.visible = true


func _update_flashlight_battery(delta: float) -> void:
	if flashlight == null or not flashlight.visible:
		return
	flashlight_battery = maxf(flashlight_battery - FLASHLIGHT_DRAIN_RATE * delta, 0.0)
	EventBus.player_stat_changed.emit(&"battery", flashlight_battery, MAX_FLASHLIGHT_BATTERY)
	if flashlight_battery <= 0.0:
		flashlight.visible = false
		EventBus.toast_requested.emit("باتری چراغ‌قوه خالی است")


func recharge_flashlight() -> void:
	set_flashlight_battery(MAX_FLASHLIGHT_BATTERY)
	EventBus.toast_requested.emit("چراغ‌قوه شارژ شد")


func set_flashlight_battery(value: float) -> void:
	flashlight_battery = clampf(value, 0.0, MAX_FLASHLIGHT_BATTERY)
	EventBus.player_stat_changed.emit(&"battery", flashlight_battery, MAX_FLASHLIGHT_BATTERY)
	if flashlight != null and flashlight.visible and flashlight_battery <= 0.0:
		flashlight.visible = false


func _on_generator_charge_requested() -> void:
	recharge_flashlight()


func _on_item_consumed(item_id: StringName) -> void:
	var catalog: ItemCatalog = InventoryManager.catalog
	if catalog == null:
		return
	var item: ItemData = catalog.get_item(item_id)
	if item == null:
		return
	match item.category:
		ItemData.ItemCategory.WATER:
			stats.drink(item.stat_restore_amount)
		ItemData.ItemCategory.FOOD:
			stats.eat(item.stat_restore_amount)
		ItemData.ItemCategory.MEDKIT:
			stats.heal(item.stat_restore_amount)
	EventBus.toast_requested.emit("مصرف شد: %s" % item.item_name)


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
	EventBus.player_stat_changed.emit(&"battery", flashlight_battery, MAX_FLASHLIGHT_BATTERY)


func _on_stat_changed(stat_name: StringName, current_value: float, max_value: float) -> void:
	EventBus.player_stat_changed.emit(stat_name, current_value, max_value)


func _on_died() -> void:
	EventBus.player_died.emit()
