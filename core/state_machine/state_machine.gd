## StateMachine
## نودی که فرزندانش را به‌عنوان State ثبت می‌کند و بین آن‌ها جابه‌جا می‌شود.
## استفاده: این نود را زیر Player (یا هر Entity) قرار بده و State های واقعی
## را به‌عنوان فرزند این نود اضافه کن.
class_name StateMachine
extends Node

signal state_changed(from_state_name: StringName, to_state_name: StringName)

@export var initial_state: State

var current_state: State = null
var states: Dictionary = {}  # StringName -> State


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[StringName(child.name)] = child
			child.state_machine = self

	if initial_state != null:
		current_state = initial_state
		current_state.enter()
	elif states.size() > 0:
		push_warning("StateMachine: no initial_state set, defaulting to first child.")
		current_state = states.values()[0]
		current_state.enter()


func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.handle_input(event)


## انتقال به حالت جدید با نام (نام باید دقیقاً برابر با نام نود فرزند باشد).
func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("StateMachine: state '%s' does not exist." % state_name)
		return

	if current_state != null and StringName(current_state.name) == state_name:
		return

	var previous_name: StringName = StringName(current_state.name) if current_state else &""

	if current_state != null:
		current_state.exit()

	current_state = states[state_name]
	current_state.enter(msg)

	state_changed.emit(previous_name, state_name)
