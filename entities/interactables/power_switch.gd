## PowerSwitch
## کلید یا سوئیچ ژنراتور اضطراری که با تعامل (E) وضعیت روشنایی محیط را تغییر می‌دهد.
class_name PowerSwitch
extends Interactable

## وضعیت اولیه روشن/خاموش بودن ژنراتور.
@export var is_powered_on: bool = false

## چراغ هدف اختیاری که وضعیت روشنایی آن با کلید کنترل می‌شود (در صورت عدم تخصیص نادیده گرفته می‌شود).
@export var target_light: Light3D

## مش نشان‌گر اختیاری برای تغییر رنگ بر اساس وضعیت روشن/خاموش (در صورت عدم تخصیص نادیده گرفته می‌شود).
@export var indicator_mesh: MeshInstance3D

## رنگ وضعیت روشن.
@export var on_color: Color = Color(0.1, 0.9, 0.3)   # سبز روشن
## رنگ وضعیت خاموش.
@export var off_color: Color = Color(0.9, 0.2, 0.1)  # قرمز خاموش


func _ready() -> void:
	_update_switch_state()


func _on_interact(_actor: Node3D) -> void:
	is_powered_on = not is_powered_on
	_update_switch_state()
	if is_powered_on:
		EventBus.generator_charge_requested.emit()


func _update_switch_state() -> void:
	prompt_message = "خاموش‌کردن ژنراتور اضطراری" if is_powered_on else "روشن‌کردن ژنراتور اضطراری"

	if target_light != null and is_instance_valid(target_light):
		target_light.visible = is_powered_on

	if indicator_mesh != null and is_instance_valid(indicator_mesh):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = on_color if is_powered_on else off_color
		mat.emission_enabled = true
		mat.emission = on_color if is_powered_on else off_color
		mat.emission_energy_multiplier = 2.0 if is_powered_on else 0.5
		indicator_mesh.material_override = mat
