## WorldClock
## زمان نرمال‌شدهٔ روز (۰..۱). داده است نه Timer روی Player.
class_name WorldClock
extends Resource

## ۰ = نیمه‌شب، ۰.۲۵ = سپیده، ۰.۵ = ظهر، ۰.۷۵ = غروب.
@export var time_of_day: float = 0.40
## طول یک شبانه‌روز فشرده (ثانیه). ۶ دقیقه = یک شب پروتوتایپ.
@export var day_length_seconds: float = 360.0


func advance(delta: float) -> void:
	if day_length_seconds <= 0.0:
		return
	time_of_day = fmod(time_of_day + delta / day_length_seconds, 1.0)
	if time_of_day < 0.0:
		time_of_day += 1.0


func is_night() -> bool:
	return time_of_day >= 0.65 or time_of_day < 0.20


func night_factor() -> float:
	if time_of_day >= 0.65:
		return clampf((time_of_day - 0.65) / 0.15, 0.0, 1.0)
	if time_of_day < 0.20:
		return clampf(1.0 - time_of_day / 0.20, 0.0, 1.0)
	return 0.0
