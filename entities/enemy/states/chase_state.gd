## ChaseState
## وقتی بازیکن وارد شعاع دید شد فعال می‌شود (با سیگنال body_entered ناحیه‌ی دید).
## دشمن روی مسیر NavigationAgent3D به سمت موقعیت لحظه‌ای بازیکن دنبال‌سازی می‌کند.
## خروج از این حالت با سیگنال‌هاست (خروج از دید → Patrol، ورود به محدوده‌ی حمله → Attack).
## مسیر: res://entities/enemy/states/chase_state.gd
class_name ChaseState
extends State

## ارجاع به دشمن والد (ارجاع صادراتی اختیاری/ضروری).
@export var enemy: Enemy
## سرعت تعقیب — واریانت‌ها (Stalker/Brute) این را در صحنه override می‌کنند.
@export var speed: float = 3.2


func physics_update(delta: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var player: Node3D = GameState.player_reference
	if player != null and is_instance_valid(player):
		if enemy.player_in_sight_area and not enemy.has_line_of_sight_to(player):
			enemy.lose_visual(player)
			return
		enemy.last_seen_position = player.global_position
		if enemy.agent != null:
			enemy.agent.target_position = player.global_position
	enemy.move_along_agent(delta, speed)
