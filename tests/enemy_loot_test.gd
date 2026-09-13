## تست کارکردی headless فاز ۱۵ (Enemy Loot):
## مرگ دشمن از EventBus یک قراضه در محل مرگ می‌اندازد.
##
## نحوه‌ی اجرا:
##   godot --headless --path . -s res://tests/enemy_loot_test.gd
##
## نکته: LootSpawner در _ready() به EventBus.enemy_died وصل می‌شود و _ready() در حالت -s
## فقط در نخستین فریم اجرا می‌شود؛ بنابراین چک‌ها بعد از چند فریم در _process() انجام می‌شوند
## (الگوی مشترک tests/inventory_wiring_test.gd).
extends SceneTree

const SPAWNER_PATH: String = "res://core/loot/loot_spawner.gd"
const ENEMY_PATH: String = "res://entities/enemy/enemy.tscn"
const EXPECTED_CHECK_COUNT: int = 14

var checks_run: int = 0
var failures: int = 0
var frame: int = 0
var started: bool = false
var host: Node3D = null
var spawner: Variant = null


func _initialize() -> void:
	_ensure_autoloads()
	host = Node3D.new()
	host.name = "LootHost"
	root.add_child(host)
	spawner = load(SPAWNER_PATH).new()
	host.add_child(spawner)


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(ResourceLoader.exists(SPAWNER_PATH), "اسکریپت LootSpawner موجود است")
	var enemy: Variant = load(ENEMY_PATH).instantiate()
	host.add_child(enemy)
	enemy.global_position = Vector3(12.0, 1.0, 18.0)
	var before: int = _scrap_count(host)
	enemy.take_damage(enemy.max_health)
	var after: int = _scrap_count(host)
	_check(after == before + 1, "مرگ دشمن یک قراضه می‌سازد")
	var drop: Node3D = _first_scrap(host)
	_check(drop != null, "قراضه‌ی لوت در درخت هست")
	if drop != null:
		_check(drop.global_position.distance_to(Vector3(12.0, 1.15, 18.0)) < 0.2,
				"قراضه نزدیک محل مرگ است")
		_check(drop.global_position.distance_to(Vector3(0.0, 1.0, 7.0)) > 5.0,
				"لوت روی اسپاون بازیکن نمی‌افتد")
		_check(drop.global_position.distance_to(Vector3(26.0, 1.0, 0.0)) > 5.0,
				"لوت روی نقطه‌ی سیو تست نمی‌افتد")
		_check(drop.get("item_id") == &"scrap_metal", "لوت scrap_metal است")
	# ── edge-caseها (هرکدام یک باگ بالقوه‌ی مشخص می‌گیرد) ──
	# (۱) آسیب غیرکشنده: نه لوت می‌افتد، نه دشمن می‌میرد
	# (باگ: اگر اسپاون لوت یا مرگ به «هر مقدار آسیب» گره خورده باشد،
	# یک ضربه‌ی ساده قراضه‌ی اضافی می‌سازد — سواستفاده از اقتصاد بازی).
	var enemy2: Variant = load(ENEMY_PATH).instantiate()
	host.add_child(enemy2)
	enemy2.global_position = Vector3(10.0, 1.0, 10.0)
	var count_before_hit: int = _scrap_count(host)
	enemy2.take_damage(10.0)
	_check(absf(enemy2.health - 30.0) < 0.01, "Edge: آسیب غیرکشنده → جان ۳۰ می‌ماند")
	_check(_scrap_count(host) == count_before_hit, "Edge: آسیب غیرکشنده → قراضه نمی‌سازد")
	# (۲) مرگ دوتایی: دقیقاً یک قراضه
	# (باگ: اگر _is_dead guard نبود، enemy_died دو بار emit می‌شد و لوت
	# دو برابر می‌افتید — سواستفاده از اقتصاد بازی).
	var count_before_kill2: int = _scrap_count(host)
	enemy2.take_damage(999.0)
	var count_after_kill2: int = _scrap_count(host)
	_check(count_after_kill2 == count_before_kill2 + 1, "Edge: مرگ → دقیقاً یک قراضه")
	enemy2.take_damage(999.0)
	_check(_scrap_count(host) == count_after_kill2, "Edge: take_damage بعد از مرگ → قراضه‌ی دوم نمی‌سازد")
	# (۳) دو مرگ در دو مکان: دو قراضه، هرکدام در محل مرگ خودش
	# (باگ: اگر اسپاونر نود قبلی را reuse کند یا موقعیت را نادیده بگیرد،
	# دومین drop در محل اشتباه ظاهر می‌شود).
	var enemy3: Variant = load(ENEMY_PATH).instantiate()
	host.add_child(enemy3)
	enemy3.global_position = Vector3(30.0, 1.0, 30.0)
	enemy3.take_damage(999.0)
	_check(_scrap_count(host) == count_after_kill2 + 1, "Edge: مرگ دوم → قراضه‌ی دوم")
	var drop3: Node3D = _first_scrap_far_from(host, Vector3(12.0, 1.15, 18.0), Vector3(10.0, 1.15, 10.0))
	_check(drop3 != null and drop3.global_position.distance_to(Vector3(30.0, 1.15, 30.0)) < 0.2,
			"Edge: قراضه‌ی دوم در محلِ مرگِ دوم است")
	host.free()


func _first_scrap_far_from(host: Node, a: Vector3, b: Vector3) -> Node3D:
	for child in host.get_children():
		if child.get("item_id") == &"scrap_metal":
			var n3d: Node3D = child as Node3D
			if n3d != null and n3d.global_position.distance_to(a) > 5.0 \
					and n3d.global_position.distance_to(b) > 5.0:
				return n3d
	return null


func _scrap_count(host: Node) -> int:
	var count: int = 0
	for child in host.get_children():
		if child.get("item_id") == &"scrap_metal":
			count += 1
	return count


func _first_scrap(host: Node) -> Node3D:
	for child in host.get_children():
		if child.get("item_id") == &"scrap_metal":
			return child as Node3D
	return null


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
		[&"InventoryManager", "res://core/inventory/inventory_manager.gd"],
		[&"CraftingSystem", "res://core/crafting/crafting_system.gd"],
		[&"AudioManager", "res://autoloads/audio_manager.gd"],
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
		print("ALL TESTS PASSED (enemy loot)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
