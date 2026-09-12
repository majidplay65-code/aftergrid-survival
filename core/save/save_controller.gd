## SaveController
## اتصال واقعی SaveManager به گیم‌پلی (تکمیل فاز ۳ — Survival Loop):
## - بارگذاری خودکار هنگام شروع بازی اگر سیو موجود باشد (وگرنه شروع پیش‌فرض — بدون کرش)
## - سیو دستی: کلید F5 (اکشن `save_game`)
## - لود دستی: کلید F8 (اکشن `load_game`)
## - خودکار سیو (auto-save) هر ۶۰ ثانیه با Timer
## فقط یک slot ساده — مطابق طراحی فعلی SaveManager.
class_name SaveController
extends Node

## فاصله‌ی auto-save به ثانیه (برای تست در صحنه قابل تغییر است).
@export var autosave_interval: float = 60.0

var _autosave_timer: Timer = null


func _ready() -> void:
	# مؤخر (deferred): ابتدا باید بازیکن خودش را در GameState ثبت کرده باشد
	call_deferred("_setup")


func _setup() -> void:
	# شروع با آخرین سیو اگر موجود باشد؛ در نبود سیو کاری نمی‌کند (شروع پیش‌فرض)
	load_now()

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = autosave_interval
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"save_game"):
		save_now()
	elif event.is_action_pressed(&"load_game"):
		load_now()


## SaveData جدید از وضعیت فعلی می‌سازد و SaveManager.save_game() را صدا می‌زند.
func save_now() -> bool:
	var player: Node3D = _get_player()
	if player == null:
		return false
	if bool(player.get("is_dead")):
		return false

	var data: SaveData = _capture_data(player)

	if SaveManager.save_game(data):
		EventBus.toast_requested.emit("ذخیره شد")
		return true
	return false


## اگر سیو موجود باشد بازیکن را از روی آن بازیابی می‌کند؛ در نبود سیو بی‌صدا بازمی‌گردد.
func load_now() -> bool:
	if not SaveManager.has_save_file():
		return false

	var data: SaveData = SaveManager.load_game()
	if data == null:
		push_warning("SaveController: save file is corrupted, cannot load.")
		return false

	if _apply_data(data):
		EventBus.toast_requested.emit("بازی از سیو بارگذاری شد")
		return true
	return false


func _get_player() -> Node3D:
	var player: Node3D = GameState.player_reference
	if player == null or not is_instance_valid(player):
		push_warning("SaveController: player not found.")
		return null
	return player


## داده‌ی قابل ذخیره را از وضعیت فعلی بازیکن جمع می‌کند.
func _capture_data(player: Node3D) -> SaveData:
	var stats: PlayerStats = player.stats
	var camera_pivot: Node3D = player.get_node_or_null("CameraPivot")
	var pitch: float = camera_pivot.rotation.x if camera_pivot != null else 0.0

	var data: SaveData = SaveData.new()
	data.player_position = player.global_position
	data.player_rotation_y = player.rotation.y
	data.player_pitch = pitch
	data.health = stats.health
	data.max_health = stats.max_health
	data.stamina = stats.stamina
	data.max_stamina = stats.max_stamina
	data.hunger = stats.hunger
	data.max_hunger = stats.max_hunger
	data.thirst = stats.thirst
	data.max_thirst = stats.max_thirst
	data.flashlight_battery = float(player.get("flashlight_battery"))
	# اینونتوری واقعی (فاز ۶): از InventoryManager سراسری خوانده می‌شود.
	data.inventory_items = InventoryManager.get_items()
	data.night_index = GameState.night_index
	data.radio_is_on = GameState.radio_is_on
	return data


## وضعیت ذخیره‌شده را روی بازیکن فعلی اعمال می‌کند.
func _apply_data(data: SaveData) -> bool:
	var player: Node3D = _get_player()
	if player == null:
		return false

	var stats: PlayerStats = player.stats
	# اول maxها، بعد مقادیر (ست‌رهای PlayerStats نسبت به max کلوز می‌کند)
	stats.max_health = data.max_health
	stats.max_stamina = data.max_stamina
	stats.max_hunger = data.max_hunger
	stats.max_thirst = data.max_thirst
	stats.health = data.health
	stats.stamina = data.stamina
	stats.hunger = data.hunger
	stats.thirst = data.thirst
	if player.has_method("set_flashlight_battery"):
		player.call("set_flashlight_battery", data.flashlight_battery)

	# بازیابی اینونتوری از سیو (فاز ۶)
	InventoryManager.restore_items(data.inventory_items)
	GameState.night_index = data.night_index
	GameState.radio_is_on = data.radio_is_on

	player.rotation.y = data.player_rotation_y
	var camera_pivot: Node3D = player.get_node_or_null("CameraPivot")
	if camera_pivot != null:
		camera_pivot.rotation.x = clampf(data.player_pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
	player.global_position = data.player_position
	return true


func _on_autosave_timeout() -> void:
	save_now()


func _on_rest_requested(_time_skip: float) -> void:
	save_now()
