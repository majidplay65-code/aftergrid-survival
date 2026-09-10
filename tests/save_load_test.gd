## تست کارکردی save/load به‌صورت headless (بدون گرافیک، با کل استک منطق واقعی:
## SaveManager، SaveData، SaveController، EventBus، HUD و صحنه‌ی سطح).
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/save_load_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"

var frame: int = 0
var phase: int = 0
var level: Node = null
var ready_frame: int = 0
var failures: int = 0


func _initialize() -> void:
	# اگر -s autoload ها را لود نکرده باشد، دستی و به ترتیب درست اضافه کن
	_ensure_autoloads()
	# شروع تمیز: هر سیوی قبلی را حذف کن تا مسیر «بدون سیو» هم تست شود
	if SaveManager.has_save_file():
		SaveManager.delete_save_file()
	_start_level()


func _process(_delta: float) -> bool:
	frame += 1
	match phase:
		0:
			# شروع بدون سیو: باید از حالت پیش‌فرض شروع شود و کرش نکند
			if frame >= 20:
				var p: Node3D = _player()
				_check(p != null, "P0: شروع بدون سیو بدون کرش (بازیکن موجود)")
				_check(p != null and p.global_position.distance_to(Vector3(0.0, 1.0, 7.0)) < 0.1,
						"P0: بدون سیو، بازیکن در پوزیشن پیش‌فرض")
				phase = 1
		1:
			# وضعیت بازیکن را عوض کن و سیو دستی (مسیر F5)
			var p: Node3D = _player()
			p.global_position = Vector3(12.0, 1.0, -10.0)
			p.rotation.y = 1.2
			p.get_node("CameraPivot").rotation.x = -0.3
			p.stats.health = 42.0
			p.stats.hunger = 55.0
			p.stats.thirst = 77.0
			_check(_controller().save_now(), "P1: سیو دستی (save_now / F5) موفق")
			phase = 2
		2:
			# فایل ایجاد شده باشد؛ از وضعیتِ عوض‌شده، لود دستی (مسیر F8) و بازیابی
			_check(SaveManager.has_save_file(), "P2: فایل سیو روی disk وجود دارد")
			var p: Node3D = _player()
			p.global_position = Vector3(0.0, 1.0, 7.0)
			p.rotation.y = 0.0
			p.get_node("CameraPivot").rotation.x = 0.0
			p.stats.health = 10.0
			p.stats.hunger = 20.0
			_check(_controller().load_now(), "P2: لود دستی (load_now / F8) موفق")
			_check(absf(p.global_position.x - 12.0) < 0.01 and absf(p.global_position.z + 10.0) < 0.01,
					"P2: لود، پوزیشن بازیکن را بازیابی می‌کند")
			_check(absf(p.rotation.y - 1.2) < 0.01, "P2: لود، yaw بازیکن را بازیابی می‌کند")
			_check(absf(p.get_node("CameraPivot").rotation.x + 0.3) < 0.01, "P2: لود، pitch دوربین را بازیابی می‌کند")
			_check(absf(p.stats.health - 42.0) < 0.01 and absf(p.stats.hunger - 55.0) < 0.01
					and absf(p.stats.thirst - 77.0) < 0.01, "P2: لود، آمار بقا را بازیابی می‌کند")
			phase = 3
		3:
			# شبیه‌سازی بستن و بازکردن بازی: صحنه آزاد و صحنه‌ی جدید (restart)
			_restart_level()
			phase = 4
		4:
			# بعد از restart، بارگذاری خودکار باید بازی را از نقطه‌ی رهاشده ادامه دهد
			if frame >= ready_frame + 15:
				var p: Node3D = _player()
				_check(p != null and absf(p.global_position.x - 12.0) < 0.01
						and absf(p.global_position.z + 10.0) < 0.01,
						"P4: restart + auto-load: پوزیشن از سیو ادامه می‌یابد")
				_check(p != null and absf(p.stats.health - 42.0) < 0.01,
						"P4: restart + auto-load: آمار از سیو ادامه می‌یابد")
				phase = 5
		5:
			# auto-save: controller مستقل با بازه‌ی کوتاه
			var c: Node = load("res://core/save/save_controller.gd").new()
			c.autosave_interval = 0.25
			root.add_child(c)
			ready_frame = frame
			phase = 6
		6:
			if frame == ready_frame + 3:
				# بعد از اینکه _setup این controller تمام شد، وضعیت جدید بگذار
				var p: Node3D = _player()
				p.global_position = Vector3(5.0, 1.0, 5.0)
			var d: SaveData = SaveManager.load_game()
			if d != null and absf(d.player_position.x - 5.0) < 0.01:
				_check(true, "P6: auto-save (Timer) وضعیت جدید را ذخیره کرد")
				phase = 7
		7:
			_finish()
			return true
	return false


func _start_level() -> void:
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)
	ready_frame = frame


func _restart_level() -> void:
	if level != null:
		level.queue_free()
	_start_level()


func _player() -> Node3D:
	if level == null:
		return null
	var p: Node = level.get_node_or_null("Player")
	return p as Node3D if p != null else null


func _controller() -> Node:
	if level == null:
		return null
	return level.get_node_or_null("SaveController")


## اگر اسکریپت با -s اجرا شود و autoload ها لود نشده باشند، دستی اضافه کن.
func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
	]
	for pair in ordered:
		var n: StringName = pair[0]
		if not root.has_node(n):
			var node: Node = load(pair[1]).new()
			node.name = n
			root.add_child(node)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	if failures == 0:
		print("ALL TESTS PASSED (save/load)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
