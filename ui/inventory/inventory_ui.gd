## InventoryUI
## رابط کاربری اینونتوری و ساخت (فاز ۶ — لایه‌ی UI).
## پنل با کلید Tab باز/بسته می‌شود: فهرست اینونتوری + دکمه‌های ساخت (فعال/غیرفعال).
## رابط در کد ساخته می‌شود (پنل/برچسب/دکمه) تا .tscn حداقل بماند و قابل تست headless باشد.
## ارتباط با سیستم‌ها فقط از autoloadهای InventoryManager/CraftingSystem و EventBus.
## پولیش UI: نوار پیشرفت ساخت (تایمینگ UI-side از RecipeData.craft_time؛ پایان با سیگنال واقعی
## item_crafted/craft_failed) و تولتیپ آیتم (hover + به‌روزرسانی محتوا با سیگنال واقعی inventory_changed).
class_name InventoryUI
extends CanvasLayer

const INVENTORY_ACTION: StringName = &"inventory"

## true = پنل باز و موس رها.
var is_open: bool = false

var background: Control
var panel: PanelContainer
var inventory_list: VBoxContainer
var crafting_list: VBoxContainer
var recipe_buttons: Dictionary[StringName, Button] = {}

## نوار پیشرفت ساخت (پولیش UI).
var craft_progress_row: HBoxContainer
var craft_progress_bar: ProgressBar
var is_crafting: bool = false
## tween فعالِ پیشرفت ساخت (برای توقف مطمئن هنگام تکمیل/لغو — بدون callback معلق).
var _craft_tween: Tween

## تولتیپ آیتم (پولیش UI).
var item_tooltip: Label
## آیتمی که موس روی ردیفش است (&"" = هیچ) — برای به‌روزرسانی تولتیپ با inventory_changed.
var _hovered_item_id: StringName = &""


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


## باز/بسته‌کردن پنل + مدیریت موس (باز = رها، بسته = قفل برای نگاه دوربین).
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
	_sync_tooltip_with_inventory()


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

	# تولتیپ آیتم (پولیش UI) — زیر فهرست، در ابتدا پنهان.
	item_tooltip = Label.new()
	item_tooltip.name = "ItemTooltip"
	item_tooltip.visible = false
	item_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_tooltip.add_theme_font_size_override("font_size", 12)
	item_tooltip.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	content.add_child(item_tooltip)

	var separator: HSeparator = HSeparator.new()
	content.add_child(separator)

	var craft_title: Label = Label.new()
	craft_title.text = "ساخت"
	content.add_child(craft_title)

	# نوار پیشرفت ساخت (پولیش UI) — بین عنوان «ساخت» و دکمه‌ها، در ابتدا پنهان.
	craft_progress_row = HBoxContainer.new()
	craft_progress_row.name = "CraftProgressRow"
	craft_progress_row.visible = false
	craft_progress_row.add_theme_constant_override("separation", 8)
	content.add_child(craft_progress_row)

	var progress_label: Label = Label.new()
	progress_label.text = "در حال ساخت…"
	craft_progress_row.add_child(progress_label)

	craft_progress_bar = ProgressBar.new()
	craft_progress_bar.name = "CraftProgressBar"
	craft_progress_bar.custom_minimum_size = Vector2(160.0, 12.0)
	craft_progress_bar.min_value = 0.0
	craft_progress_row.add_child(craft_progress_bar)

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
		# مصرفی‌ها HBox(Label + Button) می‌شوند؛ غیرمصرفی‌ها فقط Label.
		# (تست‌های موجود ساختار «اولین فرزند Label» را انتظار دارند — حفظ شد.)
		var row: Control = null
		if item != null and item.is_consumable:
			var box: HBoxContainer = HBoxContainer.new()
			box.add_child(label)
			var use_btn: Button = Button.new()
			use_btn.text = "مصرف"
			use_btn.focus_mode = Control.FOCUS_NONE
			use_btn.pressed.connect(_on_use_pressed.bind(item_id))
			box.add_child(use_btn)
			row = box
		else:
			row = label
		# تولتیپ hover (پولیش UI): ردیف موس را دریافت می‌کند و با ورود/خروج موس
		# سیگنال‌های واقعی built-in، تولتیپ نمایش/پنهان می‌شود (بدون polling).
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_row_hovered.bind(item_id))
		row.mouse_exited.connect(_on_row_unhovered)
		inventory_list.add_child(row)


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
		# حین انیمیشن پیشرفت ساخت، دکمه‌ها قفل‌اند (ضد ساخت همزمان).
		button.disabled = is_crafting or not CraftingSystem.can_craft(recipe, InventoryManager.inventory)
		button.pressed.connect(_on_craft_pressed.bind(recipe))
		crafting_list.add_child(button)
		recipe_buttons[recipe.recipe_id] = button


## آغاز پیشرفت ساخت (پولیش UI): نوار ظاهر می‌شود و با tween (بدون polling) تا
## craft_time واقعی دستور پیش می‌رود؛ سپس ساخت به autoload واقعی سپرده می‌شود.
## پایان نوار با سیگنال واقعی item_crafted (موفقیت) یا craft_failed (شکست) اعلام می‌شود.
func _start_craft_progress(recipe: RecipeData) -> void:
	is_crafting = true
	craft_progress_bar.max_value = maxf(recipe.craft_time, 0.001)
	craft_progress_bar.value = 0.0
	craft_progress_row.visible = true
	# دکمه‌ها را قفل کن (بدون بازسازی — فقط حالت disabled).
	for recipe_id in recipe_buttons:
		var button: Button = recipe_buttons[recipe_id]
		if button != null:
			button.disabled = true

	if recipe.craft_time <= 0.0:
		# ساخت فوری: بدون انیمیشن، مستقیم اجرا.
		_submit_pending_craft(recipe)
		return

	var tween: Tween = create_tween()
	_craft_tween = tween
	tween.tween_method(
		_set_craft_progress.bind(recipe),
		0.0,
		recipe.craft_time,
		recipe.craft_time
	)
	tween.tween_callback(_submit_pending_craft.bind(recipe))


## به‌روزرسانی مقدار نوار (callback از tween — بدون _process).
func _set_craft_progress(elapsed: float, recipe: RecipeData) -> void:
	if is_crafting:
		craft_progress_bar.value = elapsed


## اجرای واقعی ساخت پس از پایان پیشرفت (همان مسیر موجود craft_recipe).
func _submit_pending_craft(recipe: RecipeData) -> void:
	craft_recipe(recipe)


## پایان موفق: سیگنال واقعی item_crafted از CraftingSystem — نوار کامل و پنهان می‌شود.
func _complete_craft_progress() -> void:
	_kill_craft_tween()
	is_crafting = false
	craft_progress_bar.value = craft_progress_bar.max_value
	craft_progress_row.visible = false
	refresh()


## توقف tween فعال پیشرفت ساخت (اگر باشد) — بدون خطا اگر tween نباشد.
func _kill_craft_tween() -> void:
	if _craft_tween != null and is_instance_valid(_craft_tween):
		_craft_tween.kill()
	_craft_tween = null


## شکست: سیگنال واقعی craft_failed — نوار بی‌درنگ پنهان می‌شود (toast خطا موجود است).
func _cancel_craft_progress() -> void:
	_kill_craft_tween()
	is_crafting = false
	craft_progress_row.visible = false
	refresh()


func _on_craft_pressed(recipe: RecipeData) -> void:
	if is_crafting:
		return
	_start_craft_progress(recipe)


func _on_use_pressed(item_id: StringName) -> void:
	InventoryManager.use_item(item_id)


func _on_inventory_changed() -> void:
	refresh()
	_sync_tooltip_with_inventory()


func _on_item_crafted(recipe_id: StringName) -> void:
	_complete_craft_progress()
	EventBus.toast_requested.emit("ساخته شد: %s" % _recipe_name(recipe_id))


func _on_craft_failed(_recipe_id: StringName, reason: String) -> void:
	_cancel_craft_progress()
	EventBus.toast_requested.emit("ساخت ناموفق: %s" % _failure_text(reason))


## نمایش تولتیپ با ورود موس به ردیف آیتم (سیگنال built-in — بدون polling).
func _on_row_hovered(item_id: StringName) -> void:
	_hovered_item_id = item_id
	_update_tooltip()


## پنهان‌کردن تولتیپ با خروج موس (سیگنال built-in).
func _on_row_unhovered() -> void:
	_hovered_item_id = &""
	_update_tooltip()


## متن تولتیپ از داده‌ی واقعی کاتالوگ: «نام — توضیح (تعداد: N)».
func _update_tooltip() -> void:
	if item_tooltip == null:
		return
	if _hovered_item_id == &"":
		item_tooltip.visible = false
		item_tooltip.text = ""
		return
	var text: String = _tooltip_text(_hovered_item_id)
	if text.is_empty():
		item_tooltip.visible = false
		item_tooltip.text = ""
		return
	item_tooltip.text = text
	item_tooltip.visible = true


## ساخت متن تولتیپ یک آیتم از کاتالوگ واقعی؛ اگر آیتم شناخته نشد "" (بدون تولتیپ).
func _tooltip_text(item_id: StringName) -> String:
	var count: int = 0
	if InventoryManager.inventory != null:
		count = int(InventoryManager.inventory.count_item(item_id))
	var catalog: ItemCatalog = InventoryManager.catalog
	if catalog != null:
		var item: ItemData = catalog.get_item(item_id)
		if item != null:
			var text: String = item.item_name
			if not item.description.is_empty():
				text += " — %s" % item.description
			text += " (تعداد: %d)" % count
			return text
	return ""


## همگام‌سازی تولتیپ با سیگنال واقعی inventory_changed:
## اگر آیتمِ زیر موس هنوز موجود است متن/تعداد به‌روز می‌شود، وگرنه تولتیپ پنهان می‌شود.
func _sync_tooltip_with_inventory() -> void:
	if _hovered_item_id == &"":
		return
	if InventoryManager.inventory != null and int(InventoryManager.inventory.count_item(_hovered_item_id)) > 0:
		_update_tooltip()
	else:
		_hovered_item_id = &""
		_update_tooltip()


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
