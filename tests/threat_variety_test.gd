## تست کارکردی headless فاز ۷ (Threat Variety):
## سه واریانت دشمن با سرعت/آسیب/شعاع دید متفاوت، data-driven از طریق @export.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/threat_variety_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const SHAMBLER_PATH: String = "res://entities/enemy/enemy.tscn"
const STALKER_PATH: String = "res://entities/enemy/enemy_stalker.tscn"
const BRUTE_PATH: String = "res://entities/enemy/enemy_brute.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 22

var checks_run: int = 0
var failures: int = 0
var aborted: bool = false
var level: Node = null


func _initialize() -> void:
	_ensure_autoloads()
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	_run()
	_finish()


func _run() -> void:
	_check(ResourceLoader.exists(SHAMBLER_PATH), "صحنه‌ی Shambler موجود است")
	_check(ResourceLoader.exists(STALKER_PATH), "صحنه‌ی Stalker موجود است")
	_check(ResourceLoader.exists(BRUTE_PATH), "صحنه‌ی Brute موجود است")

	var shambler: Node = _instantiate(SHAMBLER_PATH)
	var stalker: Node = _instantiate(STALKER_PATH)
	var brute: Node = _instantiate(BRUTE_PATH)
	_check(shambler != null and stalker != null and brute != null, "هر سه واریانت instantiate می‌شوند")
	if shambler == null or stalker == null or brute == null:
		aborted = true
		return

	_check(_approx(_state_speed(shambler, "PatrolState"), 2.0), "Shambler گشت ۲.۰")
	_check(_approx(_state_speed(shambler, "ChaseState"), 3.2), "Shambler تعقیب ۳.۲")
	_check(_approx(_damage_amount(shambler), 8.0), "Shambler آسیب ۸")
	_check(_approx(_sight_radius(shambler), 7.0), "Shambler شعاع دید ۷")

	_check(_approx(_state_speed(stalker, "PatrolState"), 3.2), "Stalker گشت ۳.۲")
	_check(_approx(_state_speed(stalker, "ChaseState"), 4.6), "Stalker تعقیب ۴.۶")
	_check(_approx(_damage_amount(stalker), 5.0), "Stalker آسیب ۵")
	_check(_approx(_sight_radius(stalker), 11.0), "Stalker شعاع دید ۱۱")

	_check(_approx(_state_speed(brute, "PatrolState"), 1.2), "Brute گشت ۱.۲")
	_check(_approx(_state_speed(brute, "ChaseState"), 2.3), "Brute تعقیب ۲.۳")
	_check(_approx(_damage_amount(brute), 18.0), "Brute آسیب ۱۸")
	_check(_approx(_sight_radius(brute), 5.5), "Brute شعاع دید ۵.۵")

	_check(_state_speed(stalker, "ChaseState") > _state_speed(shambler, "ChaseState"),
			"Stalker از Shambler سریع‌تر تعقیب می‌کند")
	_check(_damage_amount(brute) > _damage_amount(shambler),
			"Brute از Shambler آسیب بیشتری می‌زند")

	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)
	_check(level.get_node_or_null("Enemy1") != null, "Enemy1 (Shambler) در سطح هست")
	_check(level.get_node_or_null("Enemy2") != null, "Enemy2 (Stalker) در سطح هست")
	_check(level.get_node_or_null("Enemy3") != null, "Enemy3 (Brute) در سطح هست")

	shambler.free()
	stalker.free()
	brute.free()


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	return packed.instantiate()


func _state_speed(enemy: Node, state_name: String) -> float:
	var state: Node = enemy.get_node_or_null(NodePath("StateMachine/" + state_name))
	if state == null:
		return -1.0
	return float(state.get("speed"))


func _damage_amount(enemy: Node) -> float:
	var damage: Node = enemy.get_node_or_null("Damage")
	if damage == null:
		return -1.0
	return float(damage.get("damage_amount"))


func _sight_radius(enemy: Node) -> float:
	var shape_node: CollisionShape3D = enemy.get_node_or_null("SightArea/CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return -1.0
	var sphere: SphereShape3D = shape_node.shape as SphereShape3D
	if sphere == null:
		return -1.0
	return sphere.radius


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
		print("ALL TESTS PASSED (threat variety)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
