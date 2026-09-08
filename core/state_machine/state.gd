## State
## کلاس پایه‌ی انتزاعی برای هر حالت. هر حالت واقعی از این ارث می‌برد
## و متدهای زیر را در صورت نیاز override می‌کند.
class_name State
extends Node

## توسط StateMachine در زمان اجرا مقداردهی می‌شود؛ به هیچ‌وجه دستی ست نکنید.
var state_machine: StateMachine = null


## زمانی که وارد این حالت می‌شویم فراخوانی می‌شود.
## msg می‌تواند داده‌ی اختیاری از حالت قبلی حمل کند.
func enter(_msg: Dictionary = {}) -> void:
	pass


## زمانی که از این حالت خارج می‌شویم فراخوانی می‌شود.
func exit() -> void:
	pass


## معادل _process ولی فقط وقتی این حالت فعال است.
func update(_delta: float) -> void:
	pass


## معادل _physics_process ولی فقط وقتی این حالت فعال است.
func physics_update(_delta: float) -> void:
	pass


## معادل _unhandled_input ولی فقط وقتی این حالت فعال است.
func handle_input(_event: InputEvent) -> void:
	pass
