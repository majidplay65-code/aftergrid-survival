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
@onready var battery_bar: ProgressBar = $Root/MarginContainer/VitalsContainer/BatteryBar

@onready var notification_container: VBoxContainer = $Root/NotificationContainer
@onready var game_over_panel: Panel = $Root/GameOverPanel

var pause_panel: Panel
var _pause_built: bool = false
var night_label: Label
var survive_panel: Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt_container.visible = false
	game_over_panel.visible = false
	_build_pause_menu()

	# اتصال به سیگنال‌های اتوبوس رویداد سراسری
	EventBus.player_stat_changed.connect(_on_player_stat_changed)
	EventBus.interactable_focused.connect(_on_interactable_focused)
	EventBus.interactable_unfocused.connect(_on_interactable_unfocused)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_died.connect(_on_player_died)
	EventBus.toast_requested.connect(_on_toast_requested)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if game_over_panel.visible:
			return
		toggle_pause_menu()
		get_viewport().set_input_as_handled()


## باز/بسته‌کردن منوی توقف (ESC). برای تست headless هم قابل‌صدا زدن است.
func toggle_pause_menu() -> void:
	if not _pause_built:
		_build_pause_menu()
	GameState.toggle_pause()
	pause_panel.visible = GameState.is_paused
	if GameState.is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_pause_menu() -> void:
	if _pause_built:
		return
	var root_control: Control = $Root
	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	pause_panel.visible = false
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(pause_panel)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title: Label = Label.new()
	title.text = "توقف"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var resume_btn: Button = Button.new()
	resume_btn.name = "ResumeButton"
	resume_btn.text = "ادامه"
	resume_btn.pressed.connect(_on_resume_pressed)
	box.add_child(resume_btn)

	var menu_btn: Button = Button.new()
	menu_btn.name = "MenuButton"
	menu_btn.text = "منوی اصلی"
	menu_btn.pressed.connect(_on_menu_pressed)
	box.add_child(menu_btn)

	_pause_built = true


func _on_resume_pressed() -> void:
	if GameState.is_paused:
		toggle_pause_menu()


func _on_menu_pressed() -> void:
	if GameState.is_paused:
		GameState.is_paused = false
	SceneManager.go_to_main_menu()


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
		&"battery":
			_update_bar(battery_bar, current_value, max_value)


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
	_show_toast("+%d %s" % [amount, str(item_id).replace("_", " ")], Color(0.3, 1.0, 0.4))


func _on_toast_requested(message: String) -> void:
	_show_toast(message, Color(0.6, 0.8, 1.0))


## سیستم toast مشترک: نمایش یک برچسب کوتاه که بعد از ۲ ثانیه محو می‌شود.
func _show_toast(text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
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
	if GameState.is_paused:
		GameState.is_paused = false
	SceneManager.reload_current_scene()


func _build_night_hud() -> void:
	var root_control: Control = $Root
	night_label = Label.new()
	night_label.name = "NightLabel"
	night_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	night_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	night_label.offset_top = 12.0
	night_label.offset_bottom = 36.0
	night_label.text = "شب ۱"
	root_control.add_child(night_label)

	survive_panel = Panel.new()
	survive_panel.name = "SurvivePanel"
	survive_panel.visible = false
	survive_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(survive_panel)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	survive_panel.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	center.add_child(box)
	var title: Label = Label.new()
	title.name = "SurviveTitle"
	title.text = "زنده ماندی"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var cont: Button = Button.new()
	cont.name = "SurviveContinue"
	cont.text = "ادامه"
	cont.pressed.connect(_on_survive_continue)
	box.add_child(cont)


func _on_time_of_day_changed(normalized: float) -> void:
	if night_label == null:
		return
	var until_dawn: float = 0.25 - normalized
	if until_dawn < 0.0:
		until_dawn += 1.0
	var pct: int = int(round((1.0 - until_dawn) * 100.0))
	night_label.text = "شب %d — تا سپیده %d%%" % [GameState.night_index, pct]


func _on_night_survived(_night_index: int) -> void:
	if survive_panel != null:
		survive_panel.visible = true
	EventBus.toast_requested.emit("شب را زنده ماندی")


func _on_survive_continue() -> void:
	if survive_panel != null:
		survive_panel.visible = false
