## Headless performance harness for test_level.tscn.
##
## Run from the project root:
##   godot --headless --path . -s res://tools/stress_test.gd
##
## This is intentionally separate from the functional tests and does not modify
## production entities. It reports measurements; it does not declare pass/fail.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const ENEMY_PATHS: Array[String] = [
	"res://entities/enemy/enemy.tscn",
	"res://entities/enemy/enemy_stalker.tscn",
	"res://entities/enemy/enemy_brute.tscn",
]
const PICKUP_PATH: String = "res://entities/interactables/water_bottle.tscn"
const ENEMY_STEPS: Array[int] = [10, 25, 50, 100]
const FRAMES_PER_STEP: int = 300
const PICKUP_CYCLES: int = 200
const RESULTS_PATH: String = "res://stress_test_results.json"

var level: Node = null
var stress_enemies: Node3D = null
var pickup_container: Node3D = null
var frame: int = 0
var phase: String = "boot"
var step_index: int = 0
var frames_left: int = 0
var pickup_index: int = 0
var started: bool = false
var baseline_node_count: int = 0
var enemy_despawn_node_count: int = 0
var baseline_process_mean: float = 0.0
var baseline_physics_mean: float = 0.0
var process_samples: Array[float] = []
var physics_samples: Array[float] = []
var fps_samples: Array[float] = []
var enemy_results: Array[Dictionary] = []
var pickup_result: Dictionary = {}


func _initialize() -> void:
	_ensure_autoloads()
	var packed: PackedScene = load(LEVEL_PATH) as PackedScene
	if packed == null:
		printerr("[stress-test] Could not load ", LEVEL_PATH)
		quit(2)
		return
	level = packed.instantiate()
	root.add_child(level)
	stress_enemies = Node3D.new()
	stress_enemies.name = "StressTestEnemies"
	level.add_child(stress_enemies)
	pickup_container = Node3D.new()
	pickup_container.name = "StressTestPickups"
	level.add_child(pickup_container)


func _process(_delta: float) -> bool:
	frame += 1
	if not started:
		if frame >= 5:
			started = true
			baseline_node_count = get_node_count()
			phase = "spawn_enemies"
			step_index = 0
			frames_left = 0
		return false

	match phase:
		"spawn_enemies":
			_run_enemy_step()
		"despawn_enemies":
			_run_enemy_despawn()
		"pickup_cycles":
			_run_pickup_cycle()
		"finish":
			_finish()
	return false


func _run_enemy_step() -> void:
	var target: int = ENEMY_STEPS[step_index]
	while stress_enemies.get_child_count() < target:
		_spawn_enemy(stress_enemies.get_child_count())
	if frames_left < FRAMES_PER_STEP:
		process_samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)))
		physics_samples.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)))
		fps_samples.append(float(Performance.get_monitor(Performance.TIME_FPS)))
		frames_left += 1
		return
	var sample: Dictionary = _measure_step(target)
	process_samples.clear()
	physics_samples.clear()
	fps_samples.clear()
	if step_index == 0:
		baseline_process_mean = float(sample["process_mean_seconds"])
		baseline_physics_mean = float(sample["physics_mean_seconds"])
		sample["performance_warning"] = false
	else:
		var process_warning: bool = baseline_process_mean > 0.0 and float(sample["process_mean_seconds"]) > baseline_process_mean * 2.0
		var physics_warning: bool = baseline_physics_mean > 0.0 and float(sample["physics_mean_seconds"]) > baseline_physics_mean * 2.0
		sample["performance_warning"] = process_warning or physics_warning
		if bool(sample["performance_warning"]):
			print("[هشدار عملکرد] enemy_target=", target, " frame time exceeded 2x the 10-enemy baseline")
	enemy_results.append(sample)
	_print_step(sample)
	step_index += 1
	frames_left = 0
	if step_index >= ENEMY_STEPS.size():
		for enemy: Node in stress_enemies.get_children():
			enemy.queue_free()
		phase = "despawn_enemies"
		frames_left = 0


func _run_enemy_despawn() -> void:
	if frames_left < 3:
		frames_left += 1
		return
	enemy_despawn_node_count = get_node_count()
	if enemy_despawn_node_count != baseline_node_count:
		print("نشتی نود مشکوک: enemy despawn node count=", enemy_despawn_node_count, "; baseline=", baseline_node_count)
	phase = "pickup_cycles"
	pickup_index = 0
	frames_left = 0


func _spawn_enemy(index: int) -> void:
	var packed: PackedScene = load(ENEMY_PATHS[index % ENEMY_PATHS.size()]) as PackedScene
	if packed == null:
		printerr("[stress-test] Could not load enemy scene ", ENEMY_PATHS[index % ENEMY_PATHS.size()])
		return
	var enemy: Node3D = packed.instantiate() as Node3D
	if enemy == null:
		return
	var column: int = index % 10
	var row: int = index / 10
	enemy.position = Vector3(-30.0 + float(column) * 6.0, 0.0, -30.0 + float(row) * 6.0)
	stress_enemies.add_child(enemy)


func _measure_step(target: int) -> Dictionary:
	return {
		"enemy_target": target,
		"frames": FRAMES_PER_STEP,
		"process_mean_seconds": _mean(process_samples),
		"process_min_seconds": _minimum(process_samples),
		"process_max_seconds": _maximum(process_samples),
		"physics_mean_seconds": _mean(physics_samples),
		"physics_min_seconds": _minimum(physics_samples),
		"physics_max_seconds": _maximum(physics_samples),
		"fps_mean": _mean(fps_samples),
		"node_count": get_node_count(),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"orphan_node_count": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"physics_3d_active_objects": int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)),
	}


func _run_pickup_cycle() -> void:
	if pickup_index >= PICKUP_CYCLES:
		phase = "finish"
		return
	var packed: PackedScene = load(PICKUP_PATH) as PackedScene
	if packed != null:
		var pickup: Node3D = packed.instantiate() as Node3D
		if pickup != null:
			pickup_container.add_child(pickup)
			pickup.queue_free()
	pickup_index += 1


func _finish() -> void:
	if phase != "finish":
		return
	phase = "finishing"
	for _frame_index: int in range(3):
		await process_frame
	var after_despawn_node_count: int = get_node_count()
	var after_despawn_orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var suspected_leak: bool = after_despawn_node_count != baseline_node_count
	pickup_result = {
		"cycles": PICKUP_CYCLES,
		"node_count_before": baseline_node_count,
		"node_count_after": after_despawn_node_count,
		"orphan_node_count_after": after_despawn_orphans,
		"suspected_node_leak": suspected_leak,
	}
	if suspected_leak:
		print("نشتی نود مشکوک: node count after despawn=", after_despawn_node_count, "; baseline=", baseline_node_count)
	var report: Dictionary = {
		"schema_version": 1,
		"godot_monitor_names": [
			"TIME_FPS",
			"TIME_PROCESS",
			"TIME_PHYSICS_PROCESS",
			"OBJECT_COUNT",
			"OBJECT_ORPHAN_NODE_COUNT",
			"PHYSICS_3D_ACTIVE_OBJECTS",
		],
		"level": LEVEL_PATH,
		"baseline_node_count": baseline_node_count,
		"enemy_despawn_node_count": enemy_despawn_node_count,
		"enemy_despawn_suspected_node_leak": enemy_despawn_node_count != baseline_node_count,
		"frames_per_enemy_step": FRAMES_PER_STEP,
		"enemy_steps": enemy_results,
		"pickup_despawn": pickup_result,
	}
	var file: FileAccess = FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print(JSON.stringify(report, "  "))
	quit(0)


func _print_step(sample: Dictionary) -> void:
	print("enemy_target=", sample["enemy_target"],
		" process(mean/min/max)=", sample["process_mean_seconds"], "/", sample["process_min_seconds"], "/", sample["process_max_seconds"],
		" physics(mean/min/max)=", sample["physics_mean_seconds"], "/", sample["physics_min_seconds"], "/", sample["physics_max_seconds"],
		" nodes=", sample["node_count"],
		" objects=", sample["object_count"],
		" orphans=", sample["orphan_node_count"],
		" physics3d_active=", sample["physics_3d_active_objects"])


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


func _minimum(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var result: float = values[0]
	for value: float in values:
		result = minf(result, value)
	return result


func _maximum(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var result: float = values[0]
	for value: float in values:
		result = maxf(result, value)
	return result


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"GameState", "res://autoloads/game_state.gd"],
		[&"SceneManager", "res://autoloads/scene_manager.gd"],
		[&"SaveManager", "res://autoloads/save_manager.gd"],
		[&"InventoryManager", "res://core/inventory/inventory_manager.gd"],
		[&"CraftingSystem", "res://core/crafting/crafting_system.gd"],
	]
	for pair: Array in ordered:
		var node_name: StringName = pair[0]
		if not root.has_node(NodePath(node_name)):
			var node: Node = load(pair[1]).new()
			node.name = node_name
			root.add_child(node)
