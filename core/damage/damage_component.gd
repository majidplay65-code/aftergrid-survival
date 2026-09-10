## DamageComponent
## کامپوننت آسیب ساده و قابل‌استفاده‌ی مجدد (فقط برای دشمن نیست).
## روی هر نودی که «آسیب می‌زند» قابل نصب است (دشمن، تله، خطر محیطی) و آسیب را
## به هر هدفی اعمال می‌کند که خاصیت `stats` از نوع PlayerStats داشته باشد
## (اتصال به PlayerStats.take_damage همین‌جا انجام می‌شود).
##
## مسیر: res://core/damage/damage_component.gd
class_name DamageComponent
extends Node

signal damage_dealt(amount: float, target: Node)

## مقدار آسیب در هر ضربه.
@export var damage_amount: float = 10.0

## کول‌داون بین ضربه‌ها به ثانیه (0 = بدون کول‌داون).
@export var cooldown: float = 1.2

var _time_since_last_hit: float = 1000.0


func _process(delta: float) -> void:
	_time_since_last_hit += delta


## تلاش برای اعمال آسیب روی `target` (با رعایت کول‌داون). در صورت موفقیت true برمی‌گردد.
func try_deal_damage(target: Node) -> bool:
	if cooldown > 0.0 and _time_since_last_hit < cooldown:
		return false

	var stats: PlayerStats = _get_player_stats(target)
	if stats == null:
		return false

	stats.take_damage(damage_amount)
	_time_since_last_hit = 0.0
	damage_dealt.emit(damage_amount, target)
	return true


## PlayerStats هدف را پیدا می‌کند (هر نودی که خاصیت `stats` از این نوع داشته باشد).
func _get_player_stats(target: Node) -> PlayerStats:
	if target == null:
		return null
	if target.get("stats") is PlayerStats:
		return target.get("stats") as PlayerStats
	return null
