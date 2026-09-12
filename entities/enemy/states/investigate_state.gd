## InvestigateState
## وقتی نویز در محدوده‌ی شنوایی شنیده شد فعال می‌شود (سیگنال EventBus.noise_emitted).
## دشمن روی navmesh به سمت محل نویز می‌رود؛ پس از رسیدن یا اتمام زمان به گشت برمی‌گردد.
## تعقیب/حمله اگر بازیکن دیده شود با سیگنال‌های Area3D اولویت دارند.
## مسیر: res://entities/enemy/states/investigate_state.gd
class_name InvestigateState
extends State

const ARRIVE_DISTANCE: float = 0.8
const GIVE_UP_SECONDS: float = 6.0

@export var enemy: Enemy
@export var speed: float = 2.4

var _elapsed: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	_elapsed = 0.0
	if msg.has("target"):
		enemy.investigate_target = msg["target"]
	enemy.agent.target_position = enemy.investigate_target


func physics_update(delta: float) -> void:
	if enemy.try_spot_player():
		return
	_elapsed += delta
	enemy.agent.target_position = enemy.investigate_target
	if enemy.horizontal_distance_to(enemy.investigate_target) < ARRIVE_DISTANCE or _elapsed >= GIVE_UP_SECONDS:
		state_machine.transition_to(&"PatrolState")
		return
	enemy.move_along_agent(delta, speed)
