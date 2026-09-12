## تست کارکردی headless (رفع بدهی فنی: ارث‌بری صحنه‌ی دشمن):
## enemy_brute.tscn و enemy_stalker.tscn دیگر کپی کامل ۱۷-گرهی enemy.tscn
## نیستند؛ صحنه‌ی ارث‌بری‌شده (instance=ExtResource روی ریشه) هستند. این تست
## مقادیری را چک می‌کند که tests/threat_variety_test.gd پوشش نمی‌دهد
## (hearing_multiplier، memory_seconds، max_health، NavigationAgent3D،
## تعداد patrol_points) تا مطمئن شویم ارث‌بری چیزی را در سکوت خراب نکرده.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/enemy_variant_integrity_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const SHAMBLER_PATH: String = "res://entities/enemy/enemy.tscn"
const STALKER_PATH: String = "res://entities/enemy/enemy_stalker.tscn"
const BRUTE_PATH: String = "res://entities/enemy/enemy_brute.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 20

var checks_run: int = 0
var failures: int = 0
var aborted: bool = false


func _initialize() -> void:
	_ensure_autoloads()
	_run()
	_finish()


func _run() -> void:
	# تأیید ارث‌بری واقعی: فایل صحنه باید یک ext_resource از نوع PackedScene
	# به enemy.tscn داشته باشد (نه کپی کامل بدون ارجاع).
	_check(_scene_extends_base(BRUTE_PATH), "enemy_brute.tscn از enemy.tscn ارث‌بری می‌کند (instance، نه کپی)")
	_check(_scene_extends_base(STALKER_PATH), "enemy_stalker.tscn از enemy.tscn ارث‌بری می‌کند (instance، نه کپی)")

	var shambler: Node = _instantiate(SHAMBLER_PATH)
	var stalker: Node = _instantiate(STALKER_PATH)
	var brute: Node = _instantiate(BRUTE_PATH)
	_check(shambler != null and stalker != null and brute != null, "هر سه واریانت instantiate می‌شوند")
	if shambler == null or stalker == null or brute == null:
		aborted = true
		return

	_check(_approx(float(shambler.max_health), 40.0), "Shambler max_health = ۴۰")
	_check(_approx(float(brute.max_health), 70.0), "Brute max_health = ۷۰")
	_check(_approx(float(stalker.max_health), 25.0), "Stalker max_health = ۲۵")

	_check(_approx(float(shambler.get("hearing_multiplier")), 1.0), "Shambler hearing_multiplier = ۱.۰ (پیش‌فرض)")
	_check(_approx(float(brute.get("hearing_multiplier")), 0.6), "Brute hearing_multiplier = ۰.۶ (سنگین‌گوش)")
	_check(_approx(float(stalker.get("hearing_multiplier")), 1.5), "Stalker hearing_multiplier = ۱.۵ (تیزگوش)")

	_check(_approx(float(shambler.get("memory_seconds")), 4.0), "Shambler memory_seconds = ۴.۰ (پیش‌فرض)")
	_check(_approx(float(brute.get("memory_seconds")), 2.5), "Brute memory_seconds = ۲.۵")
	_check(_approx(float(stalker.get("memory_seconds")), 6.0), "Stalker memory_seconds = ۶.۰")

	_check(shambler.patrol_points.size() == 4, "Shambler دقیقاً ۴ patrol_point دارد")
	_check(brute.patrol_points.size() == 4, "Brute دقیقاً ۴ patrol_point دارد")
	_check(stalker.patrol_points.size() == 4, "Stalker دقیقاً ۴ patrol_point دارد")
	_check(brute.patrol_points[0] != shambler.patrol_points[0], "patrol_points برای Brute مستقل از Shambler override شده")
	_check(stalker.patrol_points[0] != shambler.patrol_points[0], "patrol_points برای Stalker مستقل از Shambler override شده")

	var nav_brute: NavigationAgent3D = brute.get_node("NavigationAgent3D")
	var nav_stalker: NavigationAgent3D = stalker.get_node("NavigationAgent3D")
	_check(_approx(nav_brute.max_speed, 2.5), "Brute NavigationAgent3D.max_speed = ۲.۵ (کند)")
	_check(_approx(nav_stalker.max_speed, 5.0), "Stalker NavigationAgent3D.max_speed = ۵.۰ (سریع)")

	shambler.free()
	stalker.free()
	brute.free()


## آیا فایل صحنه واقعاً از enemy.tscn ارث‌بری می‌کند (ext_resource از نوع
## PackedScene با آن مسیر) — به‌جای کپی کامل گره‌ها؟
func _scene_extends_base(scene_path: String) -> bool:
	var f: FileAccess = FileAccess.open(scene_path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()
	return text.find("res://entities/enemy/enemy.tscn") != -1 and text.find("PackedScene") != -1


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	return packed.instantiate()


func _approx(value: float, expected: float) -> bool:
	return absf(value - expected) < 0.01


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
		[&"InventoryManager", "res://core/inventory/inventory_manager.gd"],
		[&"CraftingSystem", "res://core/crafting/crafting_system.gd"],
	]
	for pair in ordered:
		var n: StringName = pair[0]
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
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (enemy variant integrity)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
