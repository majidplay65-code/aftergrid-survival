## Enemy
## دشمن نمونه‌ی فاز ۵ (Threat System).
## CharacterBody3D با NavigationAgent3D که دقیقاً از الگوی موجود core/state_machine/
## (State/StateMachine) استفاده می‌کند.
## تشخیص بازیکن فقط با سیگنال‌های body_entered/body_exited دو Area3D
## (شعاع دید + محدوده‌ی حمله) انجام می‌شود — محاسبه‌ی فاصله‌ی خام از بازیکن در _process نیست.
##
## مسیر: res://entities/enemy/enemy.gd
class_name Enemy
extends CharacterBody3D

const ACCELERATION: float = 8.0
const FRICTION: float = 10.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var state_machine: StateMachine = $StateMachine
@onready var damage: DamageComponent = $Damage
@onready var sight_area: Area3D = $SightArea
@onready var attack_area: Area3D = $AttackArea

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## نقاط گشت‌زنی از پیش‌تعیین‌شده روی صحنه (در enemy.tscn مقداردهی شده).
@export var patrol_points: Array[Vector3] = []

## ضریب شنوایی نسبت به loudness سیگنال نویز (Stalker تیزگوش، Brute کم‌حوصله).
@export var hearing_multiplier: float = 1.0

## ایندکس نقطه‌ی فعلی گشت (توسط PatrolState مدیریت می‌شود).
var current_patrol_index: int = 0

## بازیکن همین الان داخل شعاع حمله است؟ (فقط با سیگنال‌های AttackArea تغییر می‌کند)
var player_in_attack_area: bool = false

## آخرین هدف بررسی نویز (توسط InvestigateState و هندلر سیگنال نویز).
var investigate_target: Vector3 = Vector3.ZERO


func _ready() -> void:
	sight_area.body_entered.connect(_on_sight_body_entered)
	sight_area.body_exited.connect(_on_sight_body_exited)
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_area.body_exited.connect(_on_attack_body_exited)
	EventBus.noise_emitted.connect(_on_noise_emitted)


func _exit_tree() -> void:
	if EventBus.noise_emitted.is_connected(_on_noise_emitted):
		EventBus.noise_emitted.disconnect(_on_noise_emitted)


## شنیدن نویز کاملاً event-driven است: چک فاصله فقط اینجا، صفر polling در _process.
func _on_noise_emitted(noise_position: Vector3, loudness: float) -> void:
	var hearing_range: float = loudness * hearing_multiplier
	if horizontal_distance_to(noise_position) > hearing_range:
		return
	var current_name: StringName = &""
	if state_machine.current_state != null:
		current_name = StringName(state_machine.current_state.name)
	if current_name == &"ChaseState" or current_name == &"AttackState":
		return
	investigate_target = noise_position
	if current_name == &"InvestigateState":
		agent.target_position = noise_position
		return
	state_machine.transition_to(&"InvestigateState", {"target": noise_position})


## سیگنال تشخیص: بازیکن وارد شعاع دید شد → تعقیب
func _on_sight_body_entered(body: Node3D) -> void:
	if body is Player:
		state_machine.transition_to(&"ChaseState")


## سیگنال تشخیص: بازیکن از شعاع دید خارج شد → بازگشت به گشت
func _on_sight_body_exited(body: Node3D) -> void:
	if body is Player:
		state_machine.transition_to(&"PatrolState")


## سیگنال تشخیص: بازیکن وارد محدوده‌ی حمله شد → حمله
func _on_attack_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in_attack_area = true
		state_machine.transition_to(&"AttackState")


## سیگنال تشخیص: بازیکن از محدوده‌ی حمله خارج شد → ادامه‌ی تعقیب
func _on_attack_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_attack_area = false
		# اگر هنوز در شعاع دید است، تعقیب ادامه دارد؛ خروج از دید با سیگنال SightArea مدیریت می‌شود
		state_machine.transition_to(&"ChaseState")


## حرکت روی مسیر NavigationAgent3D با سرعت داده‌شده (توسط State ها فراخوانی می‌شود).
func move_along_agent(delta: float, speed: float) -> void:
	# نکته‌ی مهم (قانون ضد Hallucination در AGENTS.md):
	# NavigationAgent3D در Godot 4.7 متدی به نام is_on_navigation_map ندارد؛ صدا زدنش
	# خطای runtime می‌دهد. معادلِ درست و موجود: get_navigation_map() که RID می‌دهد و
	# RID.is_valid(). این باگ قبلاً پنهان بود چون PatrolState به‌خاطر آرایه‌ی خالی
	# patrol_points همیشه early-return می‌کرد و این خط اصلاً اجرا نمی‌شد.
	if agent == null or not agent.get_navigation_map().is_valid():
		_slow_down_and_slide(delta)
		return

	var next_pos: Vector3 = agent.get_next_path_position()
	var to_next: Vector3 = next_pos - global_position
	to_next.y = 0.0

	if to_next.length() > 0.3:
		var direction: Vector3 = to_next.normalized()
		face_toward(next_pos)
		velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


## توقف کامل (حالت Attack) — فقط ترمز + گرانش + move_and_slide
func stop_moving(delta: float) -> void:
	_slow_down_and_slide(delta)


func _slow_down_and_slide(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


## چرخش به سمت یک نقطه‌ی جهانی (فقط جهت‌گیری بصری؛ تشخیص نیست)
func face_toward(world_point: Vector3) -> void:
	var d: Vector3 = world_point - global_position
	d.y = 0.0
	if d.length() > 0.05:
		rotation.y = atan2(-d.x, -d.z)


## فاصله‌ی افقی (روی صفحه‌ی XZ) تا یک نقطه‌ی جهانی — بدون اثر اختلاف ارتفاع.
## (Vector3 در Godot متد horizontal_length ندارد؛ این helper همان معنا را امن پیاده می‌کند.)
func horizontal_distance_to(world_point: Vector3) -> float:
	var d: Vector3 = world_point - global_position
	d.y = 0.0
	return d.length()
