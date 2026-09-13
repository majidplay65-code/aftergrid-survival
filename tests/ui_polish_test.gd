## تست headless پولیش UI (فاز ۶+ — نوار پیشرفت ساخت، تولتیپ، toast، جهت‌نمای صدا، افکت رهاکردن آیتم).
## هر آیتم UI با یک سیگنال «واقعی» از EventBus اجرا می‌شود (نه ساختن مستقیم نود):
##   - noise_emitted → نشانگر جهت صدا (NoiseIndicator)
##   - toast_requested / item_dropped → toast با متن و شمارش واقعی
##   - mouse_entered/mouse_exited (built-in ردیف) + inventory_changed → تولتیپ
##   - pressed (built-in دکمه) → نوار پیشرفت ساخت؛ پایان با item_crafted / craft_failed واقعی
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/ui_polish_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 54

## سقف فریم انتظار برای پایان انیمیشن ساخت (~۱ ثانیه در headless حدود ۱۵۰ فریم است).
const CRAFT_WAIT_FRAME_LIMIT: int = 900

var frame: int = 0
var phase: int = 0
var aborted: bool = false
var finished: bool = false
var level: Node = null
var event_bus: Variant = null
var inv_manager: Variant = null
var crafting: Variant = null
var save_manager: Variant = null
var hud: Variant = null
var ui: Variant = null
var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	inv_manager = root.get_node_or_null("InventoryManager")
	crafting = root.get_node_or_null("CraftingSystem")
	save_manager = root.get_node_or_null("SaveManager")
	if event_bus == null or inv_manager == null or crafting == null or save_manager == null:
		_check(false, "P0: autoloadهای لازم در دسترس نیستند")
		aborted = true
		return
	# شروع تمیز: حذف سیو قبلی تا اینونتوری از سیو لود نشود.
	if save_manager.has_save_file():
		save_manager.delete_save_file()
	_start_level()


func _process(_delta: float) -> bool:
	if finished:
		return true
	if aborted:
		_finish()
		return true
	frame += 1
	match phase:
		0:
			if frame >= 3:
				_phase_presence()
				phase = 1
		1:
			if frame >= 6:
				_phase_noise()
				phase = 2
		2:
			if frame >= 9:
				_phase_toast_drop()
				phase = 3
		3:
			if frame >= 12:
				_phase_tooltip()
				phase = 4
		4:
			if frame >= 15:
				_phase_craft_start()
				phase = 5
		5:
			if not bool(ui.is_crafting):
				_phase_craft_done()
				phase = 6
			elif frame > CRAFT_WAIT_FRAME_LIMIT:
				_timeout("پایان ساخت موفق")
		6:
			_phase_fail_start()
			phase = 7
		7:
			if not bool(ui.is_crafting):
				_phase_fail_done()
				_finish()
				return true
			elif frame > CRAFT_WAIT_FRAME_LIMIT * 2:
				_timeout("پایان ساخت ناموفق")
	return false


## فاز ۰ — حضور نودهای پولیش UI در صحنه‌ی واقعی و وضعیت اولیه‌ی درست.
func _phase_presence() -> void:
	level = root.get_node_or_null("TestLevel")
	_check(level != null, "سطح آزمونی لود شد")
	hud = level.get_node_or_null("HUD") if level != null else null
	_check(hud != null, "HUD در صحنه حاضر است")
	var noise_ind: Variant = hud.noise_indicator if hud != null else null
	_check(noise_ind != null, "جهت‌نمای صدا زیر HUD ساخته شده است")
	_check(noise_ind.get_marker_count() == 0 if noise_ind != null else false,
			"در ابتدا هیچ نشانگر صدایی نیست")
	ui = level.get_node_or_null("InventoryUI") if level != null else null
	_check(ui != null, "InventoryUI در صحنه حاضر است")
	_check(ui.craft_progress_row != null and not bool(ui.craft_progress_row.visible) if ui != null else false,
			"ردیف پیشرفت ساخت ساخته شده و در ابتدا پنهان است")
	_check(ui.item_tooltip != null and not bool(ui.item_tooltip.visible) if ui != null else false,
			"تولتیپ آیتم ساخته شده و در ابتدا پنهان است")
	_check(bool(ui.is_crafting) == false if ui != null else false,
			"در ابتدا هیچ ساختِ در جریانی نیست")
	_check(hud.get_toast_count() == 0 if hud != null else false,
			"در ابتدا هیچ toastی نیست")
	if level == null or hud == null or ui == null:
		aborted = true


## فاز ۱ — سیگنال واقعی noise_emitted → نشانگر جهت صدا (شمارش، نام، سقف، حذف قدیمی، شفافیت).
func _phase_noise() -> void:
	var camera: Camera3D = root.get_viewport().get_camera_3d()
	_check(camera != null, "دوربین فعال viewport در دسترس است")
	if camera == null:
		aborted = true
		return
	var noise_ind: Variant = hud.noise_indicator
	var front: Vector3 = camera.global_position - camera.global_transform.basis.z * 3.0
	var behind: Vector3 = camera.global_position + camera.global_transform.basis.z * 3.0
	# ۱) صدای جلوی دوربین → یک نشانگر.
	event_bus.noise_emitted.emit(front, 14.0)
	_check(noise_ind.get_marker_count() == 1, "نویز جلوی دوربین → دقیقاً ۱ نشانگر")
	var first_marker: Node = noise_ind.marker_parent.get_child(0) if noise_ind.get_marker_count() == 1 else null
	_check(first_marker != null and StringName(first_marker.name) == &"NoiseMarker",
			"نشانگر با نام NoiseMarker ساخته می‌شود")
	# ۲) صدای پشت دوربین → بی‌اثر (بدون نشانگر جدید).
	event_bus.noise_emitted.emit(behind, 9.0)
	_check(noise_ind.get_marker_count() == 1, "نویز پشت دوربین نادیده گرفته می‌شود")
	# ۳) هفت نویز دیگر → رسیدن به سقف ۸ نشانگر.
	for i in range(7):
		event_bus.noise_emitted.emit(front, 14.0)
	_check(noise_ind.get_marker_count() == 8, "سقف ۸ نشانگر هم‌زمان رعایت می‌شود")
	# ۴) دو نویز دیگر (بلندی کم) → حذف دو قدیمی‌ترین، همچنان ۸.
	for i in range(2):
		event_bus.noise_emitted.emit(front, 2.5)
	_check(noise_ind.get_marker_count() == 8, "فراتر از سقف → قدیمی‌ها حذف می‌شوند (همچنان ۸)")
	var newest: Node = noise_ind.marker_parent.get_child(7) if noise_ind.get_marker_count() == 8 else null
	_check(newest != null and is_equal_approx(0.35, float(newest.modulate.a)),
			"شفافیت نشانگر با بلندی کم به کف ۰٫۳۵ می‌رسد")


## فاز ۲ — سیگنال واقعی toast_requested و item_dropped → toast با متن واقعی.
func _phase_toast_drop() -> void:
	event_bus.toast_requested.emit("پیام تست toast")
	_check(hud.get_toast_count() == 1, "toast_requested واقعی → یک toast ساخته می‌شود")
	var first_toast: Label = hud.notification_container.get_child(0) if hud.get_toast_count() >= 1 else null
	_check(first_toast != null and first_toast.text == "پیام تست toast",
			"متن toast همان پیام سیگنال است")
	# افکت رهاکردن آیتم (پولیش UI): سیگنال واقعی item_dropped.
	event_bus.item_dropped.emit(&"scrap_metal", 1)
	_check(hud.get_toast_count() == 2, "item_dropped واقعی → toast دوم ساخته می‌شود")
	var second_toast: Label = hud.notification_container.get_child(1) if hud.get_toast_count() >= 2 else null
	_check(second_toast != null and second_toast.text == "-1 scrap metal",
			"متن toast رهاکردن «-1 scrap metal» است")


## فاز ۳ — تولتیپ آیتم: hover با سیگنال built-in ردیف + همگام‌سازی با inventory_changed واقعی.
func _phase_tooltip() -> void:
	_check(int(inv_manager.add_item(&"scrap_metal", 3)) == 3, "۳ قراضه به اینونتوری اضافه شد")
	var row: Control = ui.inventory_list.get_child(0) as Control if ui.inventory_list.get_child_count() > 0 else null
	var hovered: bool = false
	if row != null:
		row.mouse_entered.emit()
		hovered = bool(ui.item_tooltip.visible)
	_check(hovered, "ورود موس به ردیف (سیگنال built-in) → تولتیپ نمایان می‌شود")
	var tooltip_text: String = String(ui.item_tooltip.text) if hovered else ""
	_check(tooltip_text.contains("قطعه آهن‌قراضه"), "تولتیپ نام واقعی آیتم را از کاتالوگ می‌آورد")
	_check(tooltip_text.contains("تعداد: 3"), "تولتیپ تعداد واقعی اینونتوری را نشان می‌دهد")
	var unhovered: bool = false
	if row != null:
		row.mouse_exited.emit()
		unhovered = not bool(ui.item_tooltip.visible)
	_check(unhovered, "خروج موس از ردیف → تولتیپ پنهان می‌شود")
	if row != null:
		row.mouse_entered.emit()
	_check(bool(ui.item_tooltip.visible) if row != null else false,
			"hover دوباره → تولتیپ دوباره نمایان می‌شود")
	# همگام‌سازی: حذف آیتم با سیگنال واقعی item_dropped → inventory_changed → تولتیپ پنهان.
	event_bus.item_dropped.emit(&"scrap_metal", 3)
	_check(not bool(ui.item_tooltip.visible),
			"inventory_changed واقعی (حذف آیتم) → تولتیپ بی‌درنگ پنهان می‌شود")


## فاز ۴ — شروع ساخت با سیگنال built-in دکمه (pressed) → نوار پیشرفت.
func _phase_craft_start() -> void:
	# مواد لازم: ۲ قراضه برای فیلتر آب.
	inv_manager.add_item(&"scrap_metal", 2)
	var water_btn: Button = ui.get_craft_button(&"craft_water_filter")
	_check(water_btn != null and not water_btn.disabled,
			"دکمه‌ی فیلتر آب با ۲ قراضه فعال است")
	var medkit_btn: Button = ui.get_craft_button(&"craft_medkit")
	_check(medkit_btn != null and medkit_btn.disabled,
			"دکمه‌ی مدکیت بدون کنسرو غیرفعال است")
	if water_btn == null:
		aborted = true
		return
	water_btn.pressed.emit()
	_check(bool(ui.is_crafting), "pressed دکمه (سیگنال built-in) → ساخت در جریان")
	_check(bool(ui.craft_progress_row.visible), "ردیف پیشرفت ساخت نمایان می‌شود")
	_check(is_equal_approx(1.0, float(ui.craft_progress_bar.max_value)),
			"حداکثر نوار = craft_time واقعی دستور (۱٫۰)")
	_check(float(ui.craft_progress_bar.value) == 0.0,
			"مقدار نوار در لحظه‌ی شروع صفر است")
	_check(water_btn.disabled, "در حال ساخت، دکمه‌ها قفل می‌شوند (ضد ساخت هم‌زمان)")


## فاز ۵ — پایان ساخت موفق: سیگنال واقعی item_crafted (از CraftingSystem) نوار را می‌بندد.
func _phase_craft_done() -> void:
	_check(not bool(ui.craft_progress_row.visible),
			"item_crafted واقعی → ردیف پیشرفت پنهان می‌شود")
	_check(is_equal_approx(float(ui.craft_progress_bar.max_value), float(ui.craft_progress_bar.value)),
			"پس از موفقیت، نوار پر است")
	_check(int(inv_manager.count_item(&"water_bottle")) == 1,
			"ساخت واقعی: ۱ بطری آب به اینونتوری اضافه شد")
	_check(int(inv_manager.count_item(&"scrap_metal")) == 0,
			"ساخت واقعی: قراضه‌ها مصرف شدند")
	_check(_toast_exists("ساخته شد"), "toast «ساخته شد» از مسیر واقعی ساخته شد")
	_check(bool(ui.is_crafting) == false, "پس از item_crafted وضعیت crafting خاموش است")


## فاز ۶ — آماده‌سازی ساخت ناموفق: اینونتوری پُر (سقف ۱۲) → craft_failed واقعی.
func _phase_fail_start() -> void:
	_check(int(inv_manager.add_item(&"water_bottle", 4)) == 4, "۴ بطری آب دیگر (جمع ۵ از ۵)")
	_check(int(inv_manager.add_item(&"scrap_metal", 2)) == 2, "۲ قراضه برای تلاش بعدی")
	_check(int(inv_manager.add_item(&"canned_food", 5)) == 5, "۵ کنسرو (جمع کل = ۱۲)")
	_check(int(inv_manager.total_count()) == 12, "اینونتوری دقیقاً به سقف ۱۲ پُر شد")
	var water_btn: Button = ui.get_craft_button(&"craft_water_filter")
	_check(water_btn != null and not water_btn.disabled,
			"دکمه با مواد موجود فعال است (پُری اینونتوری را نمی‌بیند)")
	if water_btn == null:
		aborted = true
		return
	water_btn.pressed.emit()
	_check(bool(ui.is_crafting), "تلاش ساخت در جریان است")
	_check(bool(ui.craft_progress_row.visible), "ردیف پیشرفت برای تلاش ناموفق هم نمایان است")


## فاز ۷ — پایان ساخت ناموفق: سیگنال واقعی craft_failed + rollback کامل مواد.
func _phase_fail_done() -> void:
	_check(not bool(ui.craft_progress_row.visible),
			"craft_failed واقعی → ردیف پیشرفت پنهان می‌شود")
	_check(int(inv_manager.count_item(&"scrap_metal")) == 2,
			"شکست با اینونتوری پُر → مواد rollback شدند (قراضه ۲)")
	_check(int(inv_manager.count_item(&"water_bottle")) == 5,
			"خروجی به اینونتوری پُر اضافه نشد (آب ۵)")
	_check(int(inv_manager.count_item(&"canned_food")) == 5,
			"کنسرو دست‌نخورده ماند (۵)")
	_check(_toast_exists("ساخت ناموفق"), "toast «ساخت ناموفق» از مسیر واقعی ساخته شد")
	var water_btn: Button = ui.get_craft_button(&"craft_water_filter")
	_check(water_btn != null and not water_btn.disabled,
			"پس از شکست دکمه دوباره فعال است")


## آیا toastی با این متن موجود است؟ (جست‌وجو در فرزندان واقعی کانتینر اعلان‌ها)
func _toast_exists(needle: String) -> bool:
	var container: VBoxContainer = hud.notification_container as VBoxContainer
	if container == null:
		return false
	for child in container.get_children():
		if child is Label and String((child as Label).text).contains(needle):
			return true
	return false


## ابروت در انتظار پایان انیمیشن — چک صریح شکست + توقف (شمارش چک‌ها دیگر مهم نیست،
## محافظ EXPECTED_CHECK_COUNT ناهماهنگی را صادقانه fail می‌کند).
func _timeout(label: String) -> void:
	_check(false, "تایم‌اوت در انتظار %s (فریم %d)" % [label, frame])
	aborted = true


func _start_level() -> void:
	var packed: PackedScene = load(LEVEL_PATH)
	level = packed.instantiate()
	root.add_child(level)


## اگر اسکریپت با -s اجرا شود و autoload ها لود نشده باشند، دستی اضافه کن.
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
		# در Godot 4.7 پارامتر has_node از نوع NodePath است و StringName به‌صورت ضمنی
		# به NodePath تبدیل نمی‌شود؛ پس صریح تبدیل می‌کنیم: StringName → NodePath.
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
	finished = true
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجرا‌شده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (ui polish)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
