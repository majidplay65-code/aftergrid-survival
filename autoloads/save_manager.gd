## SaveManager
## Autoload برای ذخیره/بارگذاری بازی روی دیسک با فرمت Resource باینری Godot (.tres/.res).
## نحوه ثبت: Project Settings -> Autoload -> نام "SaveManager"
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_NAME: String = "save_slot_1.tres"


func _ready() -> void:
	_ensure_save_directory_exists()


func save_game(data: SaveData) -> bool:
	_ensure_save_directory_exists()
	var full_path: String = SAVE_DIR + SAVE_FILE_NAME
	var error: Error = ResourceSaver.save(data, full_path)

	if error != OK:
		push_error("SaveManager: failed to save game. Error code: %d" % error)
		return false

	EventBus.game_saved.emit()
	return true


func load_game() -> SaveData:
	var full_path: String = SAVE_DIR + SAVE_FILE_NAME

	if not FileAccess.file_exists(full_path):
		push_warning("SaveManager: no save file found at %s" % full_path)
		return null

	var loaded_resource: Resource = ResourceLoader.load(full_path)

	if loaded_resource == null or not (loaded_resource is SaveData):
		push_error("SaveManager: save file is corrupted or invalid.")
		return null

	EventBus.game_loaded.emit()
	return loaded_resource as SaveData


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE_NAME)


func delete_save_file() -> void:
	var full_path: String = SAVE_DIR + SAVE_FILE_NAME
	if FileAccess.file_exists(full_path):
		DirAccess.remove_absolute(full_path)


func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
