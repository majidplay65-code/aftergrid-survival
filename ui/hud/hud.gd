## HUD
## رابط کاربری بازی Aftergrid.
## نمایش آمار بقا (جان، استامینا، گرسنگی، تشنگی)، نشانه‌گیر، اعلان تعامل [E]، و پیام‌های آیتم‌ها.
class_name HUD
extends CanvasLayer

@onready var prompt_container: PanelContainer = $Root/CenterContainer/InteractionPrompt
@onready var prompt_label: Label = $Root/CenterContainer/InteractionPrompt/MarginContainer/HBoxContainer/PromptLabel

@onready var health_bar: ProgressBar = $Root/MarginContainer/VitalsContainer/HealthBar
@onready var stamina_bar: ProgressBar = $Root/MarginContainer/VitalsContainer/StaminaBar
@onready var hunger_bar: ProgressBar = $Root/MarginContainer/VitalsContainer/HungerBar
@onready var thirst_bar: ProgressBar = $Root/MarginContainer/VitalsContainer/ThirstBar

@onready var notification_container: VBoxContainer = $Root/NotificationContainer
@onready var game_over_panel: Panel = $Root/GameOverPanel


func _ready() -> void:
	prompt_container.visible = false
	game_over_panel.visible = false

	# اتصال به سیگنال‌های اتوبوس رویداد سراسری
	EventBus.player_stat_changed.connect(_on_player_stat_changed)
	EventBus.interactable_focused.connect(_on_interactable_focused)
	EventBus.interactable_unfocused.connect(_on_interactable_unfocused)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_died.connect(_on_player_died)


func _on_player_stat_changed(stat_name: StringName, current_value: float, max_value: float) -> void:
	match stat_name:
		&"health":
			_update_bar(health_bar, current_value, max_value)
		&"stamina":
			_update_bar(stamina_bar, current_value, max_value)
		&"hunger":
			_update_bar(hunger_bar, current_value, max_value)
		&"thirst":
			_update_bar(thirst_bar, current_value, max_value)


func _update_bar(bar: ProgressBar, current_val: float, max_val: float) -> void:
	if bar != null:
		bar.max_value = max_val
		bar.value = current_val


func _on_interactable_focused(text: String) -> void:
	prompt_label.text = text
	prompt_container.visible = true


func _on_interactable_unfocused() -> void:
	prompt_container.visible = false


func _on_item_picked_up(item_id: StringName, amount: int) -> void:
	var label: Label = Label.new()
	label.text = "+%d %s" % [amount, str(item_id).replace("_", " ")]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	notification_container.add_child(label)

	# محو شدن خودکار بعد از ۲ ثانیه
	var tween: Tween = create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _on_player_died() -> void:
	game_over_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
