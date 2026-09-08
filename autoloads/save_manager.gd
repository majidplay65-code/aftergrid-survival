extends Node

## ذخیره/بارگذاری ساده بر پایه‌ی JSON در user://
##
## فعلاً فقط یک اسلات ذخیره داریم و ساختار داده‌اش عمداً خام است؛
## وقتی مکانیک‌های بقا جدی شدند، همین‌جا schema و مهاجرت نسخه اضافه می‌شود.
## `schema_version` از روز اول هست تا بعداً مجبور نباشیم سیوهای قدیمی را دور بریزیم.

const SAVE_PATH := "user://aftergrid_save.json"
const SCHEMA_VERSION := 1


## داده را روی دیسک می‌نویسد. در صورت موفقیت `true` برمی‌گرداند.
func save_game(data: Dictionary) -> bool:
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"data": data,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error(
			"SaveManager: cannot open \"%s\" for writing (error %d)"
			% [SAVE_PATH, FileAccess.get_open_error()]
		)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


## سیو را می‌خواند. اگر سیوی وجود نداشته باشد یا خراب باشد، دیکشنری خالی برمی‌گرداند.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error(
			"SaveManager: cannot open \"%s\" for reading (error %d)"
			% [SAVE_PATH, FileAccess.get_open_error()]
		)
		return {}
	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file is not a valid JSON object, ignoring it.")
		return {}
	return parsed


## سیو فعلی را پاک می‌کند (برای «شروع دوباره»).
func delete_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: cannot open user:// to delete the save.")
		return
	dir.remove(SAVE_PATH.get_file())
