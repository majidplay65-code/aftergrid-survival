## Door
## در قابل‌باز/بست با E. وقتی باز است روی لولا می‌لغزد تا دهانه آزاد شود.
## نویز ۴ متر — بدون polling.
class_name Door
extends Interactable

@export var is_open: bool = false
@export var slide_open_z: float = 1.15

const OPEN_NOISE: float = 4.0

var _closed_z: float = 0.0


func _ready() -> void:
	_closed_z = position.z
	_apply_visual()


func _on_interact(_actor: Node3D) -> void:
	is_open = not is_open
	_apply_visual()
	EventBus.noise_emitted.emit(global_position, OPEN_NOISE)


func _apply_visual() -> void:
	prompt_message = "بستن در" if is_open else "بازکردن در"
	position.z = _closed_z + slide_open_z if is_open else _closed_z
