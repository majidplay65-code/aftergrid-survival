## ChaseState
## وقتی بازیکن وارد شعاع دید شد فعال می‌شود (با سیگنال body_entered ناحیه‌ی دید).
## دشمن روی مسیر NavigationAgent3D به سمت موقعیت لحظه‌ای بازیکن دنبال‌سازی می‌کند.
## خروج از این حالت با سیگنال‌هاست (خروج از دید → Patrol، ورود به محدوده‌ی حمله → Attack).
## مسیر: res://entities/enemy/states/chase_state.gd
class_name ChaseState
extends State

const SPEED: float = 3.2

@export var enemy: Enemy


func physics_update(delta: float) -> void:
	var player: Node3D = GameState.player_reference
	if player != null and is_instance_valid(player):
		enemy.agent.target_position = player.global_position
	enemy.move_along_agent(delta, SPEED)
