## تست کارکردی save/load به‌صورت headless (بدون گرافیک، با کل استک منطق واقعی:
## SaveManager، SaveData، SaveController، EventBus، HUD و صحنه‌ی سطح).
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/save_load_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"

## موقعیتی که برای تست رفت‌وبرگشتِ پوزیشن استفاده می‌شود.
## چرا این نقطه؟ (این دقیقاً باگ P4 بود)
##   موقعیت قبلی (12, 1, -10) داخل جعبه‌ی برخوردِ Bldg2 قرار داشت
##   (Bldg2: x∈[9,23]، z∈[-21,-9]). بازیکن هرگز نمی‌تواند آنجا بایستد؛ به‌محض اجرای
##   اولین فریم‌های فیزیک، موتور او را از داخل دیوار بیرون می‌راند و پوزیشن x/z عوض
##   می‌شد — بنابراین P4 (که ۱۵ فریم بعد چک می‌کرد) شکست می‌خورد، در حالی که خودِ
##   save/load پوزیشن درست کار می‌کرد (P1/P2 این را ثابت می‌کنند).
##   نقطه‌ی جدید (26, 1, 0) روی زمین صاف است، از همه‌ی جعبه‌های برخورد بیرون است
##   (۳ متر تا Bldg2) و ≥ ۱۴ متر از نزدیک‌ترین نقطه‌ی گشتِ دشمن فاصله دارد تا دشمن
##   در طول تست بازیکن را نبیند و سلامتِ ۴۲ دست‌نخورده بماند.
const SAVED_POSITION: Vector3 = Vector3(26.0, 1.0, 0.0)

## تعداد فریم‌های فیزیک برای اثبات این‌که دشمن واقعاً روی navmesh گشت می‌زند.
## (process فریم در headless خیلی سریع‌تر از فیزیک جلو می‌رود، پس معیارِ زمان باید
##  فریم فیزیک باشد نه فریم رندر.)
const NAV_PROBE_PHYSICS_FRAMES: int = 60

var frame: int = 0
var phase: int = 0
var level: Node = null
var ready_frame: int = 0
var failures: int = 0
var initial_checks_done: bool = false
var nav_probe_start_frame: int = 0
var enemy_start_position: Vector3 = Vector3.ZERO
var auto_load_applied_checked: bool = false
## در حالت اجرای `-s` (این اسکریپت = main loop)، شناسه‌ی autoload ها در لحظه‌ی کامپایلِ
## همین فایل هنوز ثبت نشده است؛ Godot اول اسکریپت main loop را لود می‌کند
## (main.cpp: ResourceLoader::load(script)) و بعد autoload ها را به‌عنوان global
## constant ثبت می‌کند. پس ارجاع مستقیم به `SaveManager` خطای
## «Identifier not found» می‌دهد و باید نود واقعیِ autoload را از درخت گرفت.
var save_manager: Variant = null


func _initialize() -> void:
	# اگر -s autoload ها را لود نکرده باشد، دستی و به ترتیب درست اضافه کن
	_ensure_autoloads()
	save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null:
		_check(false, "P0: نود SaveManager در دسترس نیست")
		_finish()
		return
	# شروع تمیز: هر سیوی قبلی را حذف کن تا مسیر «بدون سیو» هم تست شود
	if save_manager.has_save_file():
		save_manager.delete_save_file()
	_start_level()


func _process(_delta: float) -> bool:
	frame += 1
	match phase:
		0:
			# شروع بدون سیو: باید از حالت پیش‌فرض شروع شود و کرش نکند
			if not initial_checks_done and frame >= 20:
				var p: Node3D = _player()
				_check(p != null, "P0: شروع بدون سیو بدون کرش (بازیکن موجود)")
				_check(p != null and p.global_position.distance_to(Vector3(0.0, 1.0, 7.0)) < 0.1,
						"P0: بدون سیو، بازیکن در پوزیشن پیش‌فرض")
				_check_navigation_mesh()
				# شروع سنجش حرکت دشمن روی navmesh (اثبات گشت با فریم فیزیک)
				var enemy: Node3D = _enemy()
				if enemy != null:
					enemy_start_position = enemy.global_position
				nav_probe_start_frame = Engine.get_physics_frames()
				initial_checks_done = true
			elif initial_checks_done and Engine.get_physics_frames() - nav_probe_start_frame >= NAV_PROBE_PHYSICS_FRAMES:
				_check_enemy_patrols()
				phase = 1
		1:
			# وضعیت بازیکن را عوض کن و سیو دستی (مسیر F5)
			var p: Node3D = _player()
			p.global_position = SAVED_POSITION
			p.rotation.y = 1.2
			p.get_node("CameraPivot").rotation.x = -0.3
			p.stats.health = 42.0
			p.stats.hunger = 55.0
			p.stats.thirst = 77.0
			_check(_controller().save_now(), "P1: سیو دستی (save_now / F5) موفق")
			phase = 2
		2:
			# فایل ایجاد شده باشد؛ از وضعیتِ عوض‌شده، لود دستی (مسیر F8) و بازیابی
			_check(save_manager.has_save_file(), "P2: فایل سیو روی disk وجود دارد")
			var p: Node3D = _player()
			p.global_position = Vector3(0.0, 1.0, 7.0)
			p.rotation.y = 0.0
			p.get_node("CameraPivot").rotation.x = 0.0
			p.stats.health = 10.0
			p.stats.hunger = 20.0
			_check(_controller().load_now(), "P2: لود دستی (load_now / F8) موفق")
			_check(absf(p.global_position.x - SAVED_POSITION.x) < 0.01
					and absf(p.global_position.z - SAVED_POSITION.z) < 0.01,
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
			# ۴الف) خودِ auto-load پوزیشن را روی Player.global_position اعمال کرده
			if not auto_load_applied_checked and frame >= ready_frame + 2:
				var p_early: Node3D = _player()
				_check(p_early != null and absf(p_early.global_position.x - SAVED_POSITION.x) < 0.01
						and absf(p_early.global_position.z - SAVED_POSITION.z) < 0.01,
						"P4: restart + auto-load: پوزیشن روی بازیکن جدید اعمال شد")
				auto_load_applied_checked = true
			# ۴ب) و ۱۵ فریم بعد هم همان‌جا مانده (فیزیک جابه‌جایش نکرده)
			if frame >= ready_frame + 15:
				var p: Node3D = _player()
				_check(p != null and absf(p.global_position.x - SAVED_POSITION.x) < 0.01
						and absf(p.global_position.z - SAVED_POSITION.z) < 0.01,
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
			var d: SaveData = save_manager.load_game()
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


func _enemy() -> Node3D:
	if level == null:
		return null
	var e: Node = level.get_node_or_null("Enemy1")
	return e as Node3D if e != null else null


## چک: ریسورس ناوبری همان‌طور که در صحنه نوشته شده لود شده باشد.
## این چک دقیقاً همان باگی را می‌گیرد که فقط در اجرای واقعی معلوم می‌شد:
## نوع اشتباه (NavigationPolygon دو‌بعدی به‌جای NavigationMesh)، نام اشتباه پراپرتی
## (`navigation_map` به‌جای `navigation_mesh`) و فرمت اشتباهِ `polygons`
## (لیست مسطح int به‌جای آرایه‌ای از PackedInt32Array) — در این حالت‌ها صحنه
## بدون کرش بالا می‌آمد ولی منطقه‌ی ناوبری بی‌استفاده بود.
func _check_navigation_mesh() -> void:
	var region: Node3D = level.get_node_or_null("NavigationRegion") as Node3D
	_check(region != null, "P0: نود NavigationRegion3D در صحنه هست")
	if region == null:
		return

	var navmesh: NavigationMesh = region.navigation_mesh
	_check(navmesh != null, "P0: navigation_mesh روی منطقه ست شده (نه null)")
	if navmesh == null:
		return

	_check(navmesh.get_vertices().size() == 4, "P0: navmesh هر ۴ رأس را دارد")
	_check(navmesh.get_polygon_count() == 2, "P0: navmesh هر ۲ مثلث را دارد")


## چک: دشمن واقعاً روی navmesh گشت می‌زند (نه اینکه فقط بی‌خطا کرش نکند).
## این چک هم‌زمان دو چیز را می‌سنجد: درست بودن navmesh و متصل بودن رفرنس
## `enemy` در State های دشمن (که قبلاً Null بود).
func _check_enemy_patrols() -> void:
	var enemy: Node3D = _enemy()
	_check(enemy != null, "P0: نود دشمن در صحنه هست")
	if enemy == null:
		return
	var moved: float = enemy.global_position.distance_to(enemy_start_position)
	_check(moved > 0.1, "P0: دشمن روی navmesh حرکت کرد (%.2f متر در %d فریم فیزیک)"
			% [moved, NAV_PROBE_PHYSICS_FRAMES])


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
		# در Godot 4.7 پارامتر has_node از نوع NodePath است و StringName به‌صورت ضمنی
		# به NodePath تبدیل نمی‌شود (can_convert_strict: NODE_PATH فقط از STRING).
		# پس صریح تبدیل می‌کنیم: StringName → String → NodePath.
		if not root.has_node(NodePath(n)):
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
