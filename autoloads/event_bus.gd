## EventBus
## Autoload سراسری برای ارتباط بین سیستم‌های مستقل بدون وابستگی مستقیم.
## هیچ منطق گیم‌پلی اینجا نوشته نمی‌شود؛ این فایل فقط سیگنال تعریف می‌کند.
##
## نحوه ثبت: Project Settings -> Autoload -> اضافه‌کردن این فایل با نام "EventBus"
extends Node

# --- Player ---
signal player_stat_changed(stat_name: StringName, current_value: float, max_value: float)
signal player_died
signal player_respawned

# --- Inventory ---
signal item_picked_up(item_id: StringName, amount: int)
signal item_dropped(item_id: StringName, amount: int)
signal inventory_changed

# --- Crafting ---
signal item_crafted(recipe_id: StringName)
signal craft_failed(recipe_id: StringName, reason: String)

# --- World / Interaction ---
signal interactable_focused(interactable_name: String)
signal interactable_unfocused
signal interaction_performed(interactable: Node)

# --- Game Flow ---
signal game_paused(is_paused: bool)
signal game_saved
signal game_loaded

# --- UI ---
## هر سیستمی که بخواهد پیامی روی HUD نشان دهد (toast) این سیگنال را emit می‌کند.
signal toast_requested(message: String)
