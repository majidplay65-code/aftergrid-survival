## InventoryUI
## رابط کاربری اینونتوری و ساخت (فاز ۶ — لایه‌ی UI).
## پنل با کلید Tab باز/بسته می‌شود: فهرست اینونتوری + دکمه‌های ساخت (فعال/غیرفعال).
## رابط در کد ساخته می‌شود (پنل/برچسب/دکمه) تا .tscn حداقلی بماند و قابل تست headless باشد.
## ارتباط با سیستم‌ها فقط از autoloadهای InventoryManager/CraftingSystem و EventBus.
class_name InventoryUI
extends CanvasLayer

const INVENTORY_ACTION: StringName = &"inventory"

## true = پنل باز و ماوس رها.
var is_open: bool = false

var background: Control
var panel: PanelContainer
var inventory_list: VBoxContainer
var crafting_list: VBoxContainer
var recipe_buttons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	# اگر autoloadها در محیطی ناقص در دسترس نباشند، بی‌صدا کنار می‌رویم
	# (در اجرای عادی همیشه در دسترس‌اند).
	if InventoryManager == null or CraftingSystem == null:
		return
	_build_ui()
	panel.visible = false
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.item_crafted.connect(_on_item_crafted)
	EventBus.craft_failed.connect(_on_craft_failed)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INVENTORY_ACTION):
		set_open(not is_open)


## باز/بسته‌کردن پنل + مدیریت ماوس (باز = رها، بسته = قفل برای نگاه دوربین).
## پس‌زمینه‌ی تمام‌صفحه هنگام باز بودن کلیک‌ها را می‌بلعد تا به بازیکن/دنیا نرسند.
func set_open(open: bool) -> void:
	is_open = open
	panel.visible = open
	background.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if open:
		refresh()


## بازسازی کامل فهرست اینونتوری و دکمه‌های ساخت.
func refresh() -> void:
	_refresh_inventory()
	_refresh_crafting()


## تلاش برای ساخت یک دستور روی اینونتوریِ واقعی autoload.
func craft_recipe(recipe: RecipeData) -> bool:
	return CraftingSystem.craft(recipe, InventoryManager.inventory)


## دکمه‌ی ساختِ یک دستور (برای تست/UI). اگر نبود null.
func get_craft_button(recipe_id: StringName) -> Button:
	var button: Variant = recipe_buttons.get(recipe_id, null)
	return button as Button


func _build_ui() -> void:
	background = Control.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(center)

	panel = PanelContainer.new()
	panel.visible = false
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title: Label = Label.new()
	title.text = "اینونتوری"
	content.add_child(title)

	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 2)
	content.add_child(inventory_list)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var craft_title: Label = Label.new()
	craft_title.text = "ساخت"
	content.add_child(craft_title)

	crafting_list = VBoxContainer.new()
	crafting_list.add_theme_constant_override("separation", 2)
	content.add_child(crafting_list)

	var hint: Label = Label.new()
	hint.text = "Tab — بستن"
	content.add_child(hint)


func _refresh_inventory() -> void:
	_clear_children(inventory_list)
	var items: Dictionary = InventoryManager.get_items()
	if items.is_empty():
		var empty: Label = Label.new()
		empty.text = "خالی"
		inventory_list.add_child(empty)
		return
	for item_id in items:
		var item: ItemData = null
		if InventoryManager.catalog != null:
			item = InventoryManager.catalog.get_item(item_id)
		var label: Label = Label.new()
		label.text = "%s ×%d" % [_item_name(item_id), int(items[item_id])]
		# قراضه و غیرمصرفی‌ها فقط Label می‌مانند تا تست UI اولین فرزند را Label ببیند.
		if item != null and item.is_consumable:
			var row: HBoxContainer = HBoxContainer.new()
			row.add_child(label)
			var use_btn: Button = Button.new()
			use_btn.text = "مصرف"
			use_btn.focus_mode = Control.FOCUS_NONE
			use_btn.pressed.connect(_on_use_pressed.bind(item_id))
			row.add_child(use_btn)
			inventory_list.add_child(row)
		else:
			inventory_list.add_child(label)


func _refresh_crafting() -> void:
	_clear_children(crafting_list)
	recipe_buttons.clear()
	var catalog: ItemCatalog = CraftingSystem.catalog
	if catalog == null:
		return
	for recipe in catalog.recipes:
		var button: Button = Button.new()
		button.text = _recipe_label(recipe)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not CraftingSystem.can_craft(recipe, InventoryManager.inventory)
		button.pressed.connect(_on_craft_pressed.bind(recipe))
		crafting_list.add_child(button)
		recipe_buttons[recipe.recipe_id] = button


func _on_craft_pressed(recipe: RecipeData) -> void:
	craft_recipe(recipe)


func _on_use_pressed(item_id: StringName) -> void:
	InventoryManager.use_item(item_id)


func _on_inventory_changed() -> void:
	refresh()


func _on_item_crafted(recipe_id: StringName) -> void:
	EventBus.toast_requested.emit("ساخته شد: %s" % _recipe_name(recipe_id))


func _on_craft_failed(_recipe_id: StringName, reason: String) -> void:
	EventBus.toast_requested.emit("ساخت ناموفق: %s" % _failure_text(reason))


## نام نمایشی یک آیتم از کاتالوگ واقعی؛ اگر نبود، شناسه به‌صورت متنی.
func _item_name(item_id: StringName) -> String:
	var catalog: ItemCatalog = InventoryManager.catalog
	if catalog != null:
		var item: ItemData = catalog.get_item(item_id)
		if item != null and not item.item_name.is_empty():
			return item.item_name
	return str(item_id)


## نام نمایشی یک دستور از کاتالوگ واقعی؛ اگر نبود، شناسه به‌صورت متنی.
func _recipe_name(recipe_id: StringName) -> String:
	var catalog: ItemCatalog = CraftingSystem.catalog
	if catalog != null:
		var recipe: RecipeData = catalog.get_recipe(recipe_id)
		if recipe != null and not recipe.recipe_name.is_empty():
			return recipe.recipe_name
	return str(recipe_id)


## برچسب دکمه‌ی ساخت: «نام — مواد → خروجی».
func _recipe_label(recipe: RecipeData) -> String:
	var ingredients_text: String = ""
	var first: bool = true
	for item_id in recipe.ingredients:
		if not first:
			ingredients_text += " + "
		first = false
		ingredients_text += "%d×%s" % [int(recipe.ingredients[item_id]), _item_name(item_id)]
	return "%s — %s → %s" % [recipe.recipe_name, ingredients_text, _item_name(recipe.result_item_id)]


## ترجمه‌ی دلیل شکست ساخت به متن فارسی.
func _failure_text(reason: String) -> String:
	match reason:
		"insufficient_materials":
			return "مواد کافی نیست"
		"inventory_full":
			return "اینونتوری پر است"
		"result_item_unknown":
			return "خروجی نامعتبر است"
		"unknown_recipe":
			return "دستور نامعتبر است"
		"no_inventory":
			return "اینونتوری در دسترس نیست"
		"too_far":
			return "نزدیک میز ساخت نیستی"
		_:
			return reason


## حذف فوری همه‌ی فرزندان یک ظرف (queue_free تأخیری است و در بازسازی‌های متوالی تکرار می‌سازد).
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()
