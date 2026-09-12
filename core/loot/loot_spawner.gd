## LootSpawner
## گوش به EventBus.enemy_died می‌دهد و یک قراضه در محل مرگ می‌اندازد.
## بدون ارجاع مستقیم به Enemy/Player — فقط EventBus.
class_name LootSpawner
extends Node

const SCRAP_SCENE_PATH: String = "res://entities/interactables/scrap_metal.tscn"

@export var loot_scene: PackedScene


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _exit_tree() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)


func _on_enemy_died(death_position: Vector3) -> void:
	var packed: PackedScene = loot_scene
	if packed == null:
		packed = load(SCRAP_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("LootSpawner: loot scene missing")
		return
	var drop: Node = packed.instantiate()
	var host: Node = get_parent()
	if host == null:
		host = get_tree().root
	host.add_child(drop)
	if drop is Node3D:
		(drop as Node3D).global_position = death_position + Vector3(0.0, 0.15, 0.0)
