## PatrolState
## دشمن بین نقاط از پیش‌تعیین‌شده روی صحنه گشت می‌زند.
## مسیر: res://entities/enemy/states/patrol_state.gd
class_name PatrolState
extends State

const SPEED: float = 2.0
const ARRIVE_DISTANCE: float = 0.6

@export var enemy: Enemy


func enter(_msg: Dictionary = {}) -> void:
	if enemy.patrol_points.is_empty():
		return
	# از نزدیک‌ترین نقطه شروع کن
	var best_index: int = 0
	var best_distance: float = INF
	for i in enemy.patrol_points.size():
		var d: float = enemy.horizontal_distance_to(enemy.patrol_points[i])
		if d < best_distance:
			best_distance = d
			best_index = i
	enemy.current_patrol_index = best_index
	enemy.agent.target_position = enemy.patrol_points[best_index]


func physics_update(delta: float) -> void:
	if enemy.patrol_points.is_empty():
		return
	var point: Vector3 = enemy.patrol_points[enemy.current_patrol_index]
	enemy.agent.target_position = point
	# رسیدن به «نقطه‌ی مسیر» (نه بازیکن) چک می‌شود
	if enemy.horizontal_distance_to(point) < ARRIVE_DISTANCE:
		enemy.current_patrol_index = (enemy.current_patrol_index + 1) % enemy.patrol_points.size()
	enemy.move_along_agent(delta, SPEED)
