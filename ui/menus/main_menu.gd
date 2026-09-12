## MainMenu
## منوی اصلی شروع بازی. SceneManager از قبل مسیر این صحنه را می‌شناسد.
## مسیر: res://ui/menus/main_menu.gd
class_name MainMenu
extends Control

const LEVEL_PATH: String = "res://levels/test_level.tscn"

var start_button: Button
var quit_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.05, 0.06, 0.08, 1)
	add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title: Label = Label.new()
	title.text = "Aftergrid"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "بعد از خاموشی شبکه"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "شروع"
	start_button.custom_minimum_size = Vector2(220, 40)
	start_button.pressed.connect(_on_start_pressed)
	box.add_child(start_button)

	quit_button = Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "خروج"
	quit_button.custom_minimum_size = Vector2(220, 40)
	quit_button.pressed.connect(_on_quit_pressed)
	box.add_child(quit_button)


func _on_start_pressed() -> void:
	SceneManager.change_scene(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
