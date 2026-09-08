## SceneManager
## Autoload برای تعویض صحنه به‌صورت متمرکز و امن (deferred).
## نحوه ثبت: Project Settings -> Autoload -> نام "SceneManager"
extends Node

const MAIN_MENU_PATH: String = "res://ui/menus/main_menu.tscn"


func change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("SceneManager: scene path does not exist -> %s" % scene_path)
		return

	GameState.current_level_path = scene_path
	get_tree().paused = false
	call_deferred("_do_change_scene", scene_path)


func reload_current_scene() -> void:
	if GameState.current_level_path != "":
		change_scene(GameState.current_level_path)
	else:
		get_tree().reload_current_scene()


func go_to_main_menu() -> void:
	change_scene(MAIN_MENU_PATH)


func _do_change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
