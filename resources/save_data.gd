## SaveData
## کانتینر داده‌ی خالص برای ذخیره/بارگذاری. هیچ منطقی اینجا نیست، فقط داده.
class_name SaveData
extends Resource

@export var save_version: int = 2
@export var level_path: String = ""
@export var player_position: Vector3 = Vector3.ZERO
@export var player_rotation_y: float = 0.0
@export var player_pitch: float = 0.0

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0
@export var hunger: float = 100.0
@export var max_hunger: float = 100.0
@export var thirst: float = 100.0
@export var max_thirst: float = 100.0
## باتری چراغ‌قوه. سیوهای قدیمی این فیلد را ندارند → پیش‌فرض ۱۰۰.
@export var flashlight_battery: float = 100.0

## Dictionary[StringName, int] -> item_id به‌مقدار stack
@export var inventory_items: Dictionary = {}
## شمارهٔ شب. سیوهای قدیمی این فیلد را ندارند → پیش‌فرض ۱.
@export var night_index: int = 1
@export var radio_is_on: bool = false
