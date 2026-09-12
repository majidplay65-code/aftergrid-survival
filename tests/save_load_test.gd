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

## تعداد رأس/مثلث‌های navmesh کاروشده در `levels/test_level.tscn`.
## چرا این اعداد؟ سطحِ صافِ `[-40,40]²` منهای ۶ محوطه‌ی ساختمان‌ها، با شبکه‌ای
## هم‌ترازِ لبه‌های همان محوطه‌ها (بدون T-junction؛ چون موتور لبه‌ها را فقط وقتی
## به هم وصل می‌کند که «هر دو سرِ لبه» یکی باشند) = ۸۶ خانه × ۲ مثلث = ۱۷۲ مثلث
## و ۱۳۴ رأس. عدد دقیق، محافظِ رگرسیون است: هر تغییرِ ناخواسته در navmesh را می‌گیرد.
const NAVMESH_VERTEX_COUNT: int = 341
const NAVMESH_POLYGON_COUNT: int = 494

## نام ۶ مانع ناوبری (پایه‌ی ساختمان‌ها) در `test_level.tscn`.
const OBSTACLE_NAMES: Array[String] = ["ObstacleB1", "ObstacleB2", "ObstacleB3",
		"ObstacleB4", "ObstacleB5", "ObstacleB6",
		"ObstacleW1", "ObstacleW2", "ObstacleC1", "ObstacleC2", "ObstacleC3", "ObstacleShed"]

## نقاطی که بعد از کارو (بریدن محوطه‌ی ساختمان‌ها از navmesh) باید هنوز روی navmesh
## باشند: اسپاون بازیکن، نقطه‌ی سیو/لود تست، اسپاون دشمن و ۴ نقطه‌ی گشت دشمن.
## اگر کارو زیاده‌روی کرده باشد، یکی از این‌ها از شبکه جدا می‌شود.
const NAV_FREE_POINTS: Array[Vector3] = [
	Vector3(0.0, 0.0, 7.0), Vector3(26.0, 0.0, 0.0), Vector3(-1.5, 0.0, -12.0),
	Vector3(0.0, 0.0, -12.0), Vector3(-12.0, 0.0, 0.0), Vector3(0.0, 0.0, 12.0), Vector3(12.0, 0.0, 0.0),
]

## ۴ نقطه‌ی گشت دشمن — همان مقادیر `patrol_points` در `entities/enemy/enemy.tscn`.
const PATROL_POINTS: Array[Vector3] = [
	Vector3(0.0, 0.0, 12.0), Vector3(-12.0, 0.0, 0.0), Vector3(0.0, 0.0, -12.0), Vector3(12.0, 0.0, 0.0),
]

## دو نقطه در دو طرف ساختمان Bldg1 (محوطه‌ی مانع: x∈[-26.5,-7.5]، z∈[-25.5,-8.5]).
## خط مستقیم بین این دو ۲۶ متر است و از وسط ساختمان می‌گذرد؛ روی navmeshِ کاروشده
## موتور باید مسیر را دور ساختمان بچرخاند (طول واقعی ≈ ۴۳ متر).
const CARVE_PROBE_WEST: Vector3 = Vector3(-30.0, 0.5, -17.0)
const CARVE_PROBE_EAST: Vector3 = Vector3(-4.0, 0.5, -17.0)
const CARVE_STRAIGHT_METERS: float = 26.0

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (شاملِ خودِ چکِ محافظ).
## چرا این محافظ لازم است؟ اگر یک تابع به‌خاطر «Invalid call» (API ناموجود در ۴.۷.۲)
## وسط راه قطع شود، Godot فقط SCRIPT ERROR چاپ می‌کند و exit code صفر می‌ماند؛ آن‌وقت
## بخشی از چک‌ها هرگز اجرا نمی‌شوند و هیچ‌کس متوجه نمی‌شود (دقیقاً همان اتفاقی که در
## اجرای اولِ همین چک‌ها افتاد: PASS=19 با دو SCRIPT ERROR و در عین حال CI سبز).
## این شمارنده آن حالت را به FAIL تبدیل می‌کند.
const EXPECTED_CHECK_COUNT: int = 98

var frame: int = 0
var phase: int = 0
var checks_run: int = 0
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

	_check(navmesh.get_vertices().size() == NAVMESH_VERTEX_COUNT,
			"P0: navmesh هر %d رأس را دارد" % NAVMESH_VERTEX_COUNT)
	_check(navmesh.get_polygon_count() == NAVMESH_POLYGON_COUNT,
			"P0: navmesh هر %d مثلث را دارد" % NAVMESH_POLYGON_COUNT)
	_check_navigation_carve(navmesh)


## چک: فیکسِ `NavigationObstacle3D` واقعاً کار می‌کند (نه فقط ادعا).
## تاریخِ باگ: نودهای مانع پراپرتی `shape` داشتند که در Godot 4.7.2 اصلاً وجود ندارد
## (فقط به‌صورت خاموش نادیده گرفته می‌شد) و `sync_to_physics` هم در ۴.x حذف شده است؛
## یعنی هیچ‌کدام از ۶ مانع کاری نمی‌کردند و مسیر دشمن از وسط ساختمان‌ها می‌گذشت.
## فیکس: `vertices` (محوطه) + `affect_navigation_mesh` + `carve_navigation_mesh`.
## چون این دو فلگ فقط در «bake» اثر دارند و navmesh این پروژه دستی نوشته شده
## (هیچ‌وقت bake نمی‌شود)، نتیجه‌ی همان bake به‌صورت چندضلعی‌های کاروشده داخل
## `polygons` نوشته شده است. این تابع هر دو طرف را چک می‌کند:
##   ۱) داده‌ی مانع‌ها همان چیزی است که باید باشد،
##   ۲) داخل محوطه‌های مانع هیچ سطحی از navmesh نیست (کارو انجام شده)،
##   ۳) نقاط حیاتی بازی هنوز روی navmesh هستند (کارو زیاده‌روی نکرده).
func _check_navigation_carve(navmesh: NavigationMesh) -> void:
	for obstacle_name in OBSTACLE_NAMES:
		var obstacle: NavigationObstacle3D = level.get_node_or_null(NodePath(obstacle_name)) as NavigationObstacle3D
		_check(obstacle != null, "P0: مانع %s در صحنه هست" % obstacle_name)
		if obstacle == null:
			continue
		_check(obstacle.get_vertices().size() == 4,
				"P0: %s محوطه را با vertices تعریف کرده (نه shape ناموجود)" % obstacle_name)
		_check(obstacle.affect_navigation_mesh and obstacle.carve_navigation_mesh,
				"P0: %s علامت‌های affect + carve را دارد" % obstacle_name)
		_check(obstacle.height >= 4.5,
				"P0: %s ارتفاع ساختمان را دارد (%.1f متر)" % [obstacle_name, obstacle.height])
		var footprint: Rect2 = _obstacle_footprint(obstacle)
		_check(not _navmesh_covers_xz(navmesh, footprint.get_center()),
				"P0: مرکز محوطه‌ی %s از navmesh کارو شده" % obstacle_name)

	for point in NAV_FREE_POINTS:
		_check(_navmesh_covers_xz(navmesh, Vector2(point.x, point.z)),
				"P0: نقطه‌ی حیاتی (%.0f، %.0f) هنوز روی navmesh است" % [point.x, point.z])


## محوطه‌ی جهانیِ مانع در صفحه‌ی XZ (از روی `vertices` محلی × ترنسفورم گره).
func _obstacle_footprint(obstacle: NavigationObstacle3D) -> Rect2:
	var local: PackedVector3Array = obstacle.get_vertices()
	if local.is_empty():
		return Rect2()
	var first: Vector3 = obstacle.global_transform * local[0]
	var min_x: float = first.x
	var max_x: float = first.x
	var min_z: float = first.z
	var max_z: float = first.z
	for v in local:
		var world: Vector3 = obstacle.global_transform * v
		min_x = minf(min_x, world.x)
		max_x = maxf(max_x, world.x)
		min_z = minf(min_z, world.z)
		max_z = maxf(max_z, world.z)
	return Rect2(min_x, min_z, max_x - min_x, max_z - min_z)


## آیا این نقطه‌ی XZ روی یکی از چندضلعی‌های navmesh می‌افتد؟
## (چندضلعی‌ها محدب‌اند؛ تست علامتِ ضربِ خارجی برای هر ضلع.)
## توجه: در Godot 4.7.2 متد `NavigationMesh.get_polygons()` وجود ندارد (فقط
## `get_polygon_count()` و `get_polygon(idx)`) — همان اشتباهی که چکِ زیر می‌گرفت.
func _navmesh_covers_xz(navmesh: NavigationMesh, point_xz: Vector2) -> bool:
	var vertices: PackedVector3Array = navmesh.get_vertices()
	for index in navmesh.get_polygon_count():
		var poly: PackedInt32Array = navmesh.get_polygon(index)
		var count: int = poly.size()
		var positive: int = 0
		var negative: int = 0
		for i in count:
			var a: Vector3 = vertices[poly[i]]
			var b: Vector3 = vertices[poly[(i + 1) % count]]
			var cross: float = (b.x - a.x) * (point_xz.y - a.z) - (b.z - a.z) * (point_xz.x - a.x)
			if cross > 0.000001:
				positive += 1
			elif cross < -0.000001:
				negative += 1
		if positive == 0 or negative == 0:
			return true
	return false


## آیا این نقطه داخل محوطه‌ی یکی از مانع‌ها است؟ (`erode` = چند متر داخل‌تر)
func _point_inside_any_obstacle(point_xz: Vector2, erode: float) -> bool:
	for obstacle_name in OBSTACLE_NAMES:
		var obstacle: NavigationObstacle3D = level.get_node_or_null(NodePath(obstacle_name)) as NavigationObstacle3D
		if obstacle == null:
			continue
		if _obstacle_footprint(obstacle).grow(-erode).has_point(point_xz):
			return true
	return false


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
	_check_navigation_paths(enemy)


## چک: اثباتِ موتوربنیانِ کارو روی navigation map زنده‌ی موتور (نه فقط خواندن ریسورس).
## در این لحظه دشمن با همین map واقعاً حرکت کرده، پس map sync شده است.
func _check_navigation_paths(enemy: Node3D) -> void:
	# در Godot 4.7.2 نودِ `Node3D` متد `get_navigation_map()` ندارد؛ فقط
	# `NavigationAgent3D` آن را دارد (و `World3D.get_navigation_map()`).
	var agent: NavigationAgent3D = enemy.get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	_check(agent != null, "P0: نود NavigationAgent3D دشمن در دسترس است")
	if agent == null:
		return
	var map: RID = agent.get_navigation_map()
	_check(map.is_valid(), "P0: navigation map دشمن معتبر است")
	if not map.is_valid():
		return

	# ۱) مسیر دو طرف ساختمان Bldg1: روی navmeshِ کارونشده باید دور ساختمان بچرخد.
	var path: PackedVector3Array = NavigationServer3D.map_get_path(
			map, CARVE_PROBE_WEST, CARVE_PROBE_EAST, true)
	_check(path.size() >= 2, "P0: مسیر ناوبری بین دو طرف ساختمان پیدا شد (%d نقطه)" % path.size())
	var length: float = 0.0
	for i in path.size() - 1:
		length += path[i].distance_to(path[i + 1])
	_check(length > CARVE_STRAIGHT_METERS + 4.0,
			"P0: مسیر دور ساختمان می‌چرخد (%.1f متر > خط مستقیم %.1f متر)"
			% [length, CARVE_STRAIGHT_METERS])
	var inside: bool = false
	for point in path:
		if _point_inside_any_obstacle(Vector2(point.x, point.z), 0.1):
			inside = true
	_check(not inside, "P0: هیچ نقطه‌ی مسیر داخل محوطه‌ی ساختمان‌ها نیست (کارو واقعی است)")

	# ۲) اتصال شبکه بعد از کارو: هر چهار پای گشت دشمن باید مسیر کامل داشته باشند.
	for i in PATROL_POINTS.size():
		var from_point: Vector3 = PATROL_POINTS[i]
		var to_point: Vector3 = PATROL_POINTS[(i + 1) % PATROL_POINTS.size()]
		var leg: PackedVector3Array = NavigationServer3D.map_get_path(map,
				from_point + Vector3(0.0, 0.5, 0.0), to_point + Vector3(0.0, 0.5, 0.0), true)
		var reached: bool = false
		if leg.size() >= 2:
			var end_xz: Vector2 = Vector2(leg[leg.size() - 1].x, leg[leg.size() - 1].z)
			reached = end_xz.distance_to(Vector2(to_point.x, to_point.z)) < 0.5
		_check(reached, "P0: پای گشت %d→%d بعد از کارو متصل است (%d نقطه)"
				% [i, (i + 1) % PATROL_POINTS.size(), leg.size()])


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
	checks_run += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"P0: همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (save/load)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
