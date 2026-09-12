## InventoryManager
## سیستم لایه‌ی منطق فاز ۶ (Inventory/Crafting): صاحبِ اینونتوری بازیکن و پلِ بین
## Inventory و EventBus — طبق قرارداد پروژه، ارتباط بین سیستم‌ها فقط از EventBus است.
## - به EventBus.item_picked_up / EventBus.item_dropped گوش می‌دهد و محتوا را به‌روز می‌کند.
## - بعد از هر تغییر واقعی، EventBus.inventory_changed را emit می‌کند.
## (ثبت به‌عنوان Autoload / افزودن به صحنه در لایه‌ی «اتصال» انجام می‌شود، نه اینجا.)
class_name InventoryManager
extends Node

## مسیر کاتالوگ واقعی — برای autoload که نمی‌تواند @export از بیرون بگیرد.
const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## کاتالوگ مرجع آیتم‌ها (برای max_stack)؛ در autoload از CATALOG_PATH لود می‌شود،
## در تست‌ها از بیرون ست می‌شود.
@export var catalog: ItemCatalog = null

## اینونتوریِ تحت مدیریت (در _ready ساخته می‌شود).
var inventory: Inventory = null


func _ready() -> void:
	if catalog == null:
		catalog = _load_catalog()
	inventory = Inventory.new()
	inventory.catalog = catalog
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_dropped.connect(_on_item_dropped)
	inventory.contents_changed.connect(_on_inventory_changed)


## لود کاتالوگ واقعی برای استفاده‌ی autoload (وقتی catalog از بیرون ست نشده باشد).
func _load_catalog() -> ItemCatalog:
	var loaded: Resource = load(CATALOG_PATH)
	if loaded is ItemCatalog:
		return loaded as ItemCatalog
	return null


func _on_item_picked_up(item_id: StringName, amount: int) -> void:
	add_item(item_id, amount)


func _on_item_dropped(item_id: StringName, amount: int) -> void:
	remove_item(item_id, amount)


## تغییرِ واقعی در اینونتوری → اطلاع‌رسانی سراسری از طریق EventBus.
func _on_inventory_changed() -> void:
	EventBus.inventory_changed.emit()


## API عمومی: افزودن؛ تعدادِ واقعی افزوده‌شده را برمی‌گرداند (۰ اگر جا نبود).
func add_item(item_id: StringName, amount: int) -> int:
	return inventory.add_item(item_id, amount)


func remove_item(item_id: StringName, amount: int) -> int:
	return inventory.remove_item(item_id, amount)


func count_item(item_id: StringName) -> int:
	return inventory.count_item(item_id)


func has_item(item_id: StringName, amount: int = 1) -> bool:
	return inventory.has_item(item_id, amount)


func get_items() -> Dictionary:
	return inventory.get_items()


func is_empty() -> bool:
	return inventory.is_empty()


func total_count() -> int:
	return inventory.total_count()


## بازیابی کامل اینونتوری از داده‌ی سیو (فاز ۶ — لایه‌ی اتصال). SaveController صدا می‌زند.
func restore_items(saved_items: Dictionary) -> void:
	inventory.restore_items(saved_items)
