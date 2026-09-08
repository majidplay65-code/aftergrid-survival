## PlayerStats
## Resource حامل آمار بازیکن + منطق ایمن برای تغییر آن‌ها.
## بین صحنه‌ها و حتی برای Save/Load قابل استفاده مجدد است.
class_name PlayerStats
extends Resource

signal stat_changed(stat_name: StringName, current_value: float, max_value: float)
signal died

@export var max_health: float = 100.0
@export var health: float = 100.0:
	set(value):
		health = clampf(value, 0.0, max_health)
		stat_changed.emit(&"health", health, max_health)
		if health <= 0.0:
			died.emit()

@export var max_stamina: float = 100.0
@export var stamina: float = 100.0:
	set(value):
		stamina = clampf(value, 0.0, max_stamina)
		stat_changed.emit(&"stamina", stamina, max_stamina)

@export var max_hunger: float = 100.0
@export var hunger: float = 100.0:
	set(value):
		hunger = clampf(value, 0.0, max_hunger)
		stat_changed.emit(&"hunger", hunger, max_hunger)

@export var max_thirst: float = 100.0
@export var thirst: float = 100.0:
	set(value):
		thirst = clampf(value, 0.0, max_thirst)
		stat_changed.emit(&"thirst", thirst, max_thirst)


func take_damage(amount: float) -> void:
	health -= amount


func heal(amount: float) -> void:
	health += amount


func consume_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	return true


func regen_stamina(amount: float) -> void:
	stamina += amount


func decrease_hunger(amount: float) -> void:
	hunger -= amount
	if hunger <= 0.0:
		take_damage(1.0)


func decrease_thirst(amount: float) -> void:
	thirst -= amount
	if thirst <= 0.0:
		take_damage(1.5)


func eat(amount: float) -> void:
	hunger += amount


func drink(amount: float) -> void:
	thirst += amount
