## AttackState
## وقتی بازیکن وارد محدوده‌ی حمله شد فعال می‌شود (با سیگنال body_entered ناحیه‌ی حمله).
## دشمن توقف می‌کند، رو به بازیکن می‌ایستد و از طریق DamageComponent ضربه می‌زند
## (با کول‌داون). ضربه فقط زمانی اعمال می‌شود که بازیکن داخل محدوده‌ی حمله باشد
## (بُلیانی که فقط با سیگنال‌ها تغییر می‌کند — نه فاصله‌ی خام).
## مسیر: res://entities/enemy/states/attack_state.gd
class_name AttackState
extends State

@export var enemy: Enemy


func physics_update(delta: float) -> void:
	var player: Node3D = GameState.player_reference
	if player == null or not is_instance_valid(player):
		return
	enemy.face_toward(player.global_position)
	if enemy.player_in_attack_area:
		enemy.damage.try_deal_damage(player)
	enemy.stop_moving(delta)
