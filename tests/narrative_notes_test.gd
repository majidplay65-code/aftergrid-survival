## تست headless نوت‌های روایی قابل‌جمع‌آوری (فاز ۶+ — Task 2: فقط داده/متن، بدون گیم‌پلی جدید).
## چه چیزی اثبات می‌شود:
##   - هر ۵ فایل .tres نوت به‌درستی لود می‌شود، NarrativeNote است و داده‌هایش
##     (note_id یکتا، order_index ترتیبی، title/body/location_hint غیرخالی) معتبر است؛
##   - هر ۵ صحنه‌ی pickup فقط از اسکریپت موجود ItemPickup استفاده می‌کند (بدون اسکریپت جدید)،
##     مصرف‌فوری نیست، item_id دقیقاً narrative_note_* و دسته GENERIC (۰ عددی) است؛
##   - برداشت واقعی با interact() → سیگنال واقعی EventBus.item_picked_up → InventoryManager
##     نوت را به کیف می‌برد (مسیر موجود، بدون کد جدید) و شیء pickup با queue_free حذف می‌شود.
##
## نکته‌ی فنی (قرارداد ریپو): اسکریپت ItemPickup در زمان کامپایل به شناسه‌ی سراسری
## InventoryManager وابسته است؛ در حالت -s (قبل از ثبت globals) کامپایل زودهنگامِ آن
## شکست می‌خورد. پس مطابق تست‌های موجود (inventory_wiring_test.gd) فقط از نوع پایه‌ی
## Interactable (بدون وابستگی به autoload) استفاده می‌کنیم و خواصِ اختصاصی ItemPickup
## را در زمان اجرا با get() می‌خوانیم.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/narrative_notes_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"

## مسیر ۵ فایل داده‌ی نوت (به ترتیب order_index از ۱ تا ۵).
const NOTE_PATHS: Array[String] = [
	"res://resources/narrative/note_01_grid_falls.tres",
	"res://resources/narrative/note_02_market_diary.tres",
	"res://resources/narrative/note_03_workshop_log.tres",
	"res://resources/narrative/note_04_beacon_operator.tres",
	"res://resources/narrative/note_05_dawn_letter.tres",
]

## مسیر ۵ صحنه‌ی pickup (هم‌تراز با NOTE_PATHS).
const PICKUP_PATHS: Array[String] = [
	"res://resources/narrative/note_01_pickup.tscn",
	"res://resources/narrative/note_02_pickup.tscn",
	"res://resources/narrative/note_03_pickup.tscn",
	"res://resources/narrative/note_04_pickup.tscn",
	"res://resources/narrative/note_05_pickup.tscn",
]

## item_id انتظاری هر pickup (دقیقاً narrative_note_* مطابق فایل‌های صحنه).
const EXPECTED_ITEM_IDS: Array[StringName] = [
	&"narrative_note_grid_falls",
	&"narrative_note_market_diary",
	&"narrative_note_workshop_log",
	&"narrative_note_beacon_operator",
	&"narrative_note_dawn_letter",
]

## مقدار عددی دسته‌ی GENERIC در enum ItemCategory (بر پایه‌ی اسکریپت موجود item_pickup.gd).
const GENERIC_CATEGORY_VALUE: int = 0

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
## ۳۰ (داده نوت‌ها) + ۲۵ (وضعیت ایستای pickup) + ۱۶ (برداشت واقعی) + ۶ (حذف) + ۱ (خودی) = ۷۸.
const EXPECTED_CHECK_COUNT: int = 78

var frame: int = 0
var phase: int = 0
var aborted: bool = false
var finished: bool = false
var level: Node = null
var event_bus: Variant = null
var inv_manager: Variant = null
var save_manager: Variant = null
var pickups: Array[Interactable] = []
var checks_run: int = 0
var failures: int = 0


func _initialize() -> void:
	_ensure_autoloads()
	event_bus = root.get_node_or_null("EventBus")
	inv_manager = root.get_node_or_null("InventoryManager")
	save_manager = root.get_node_or_null("SaveManager")
	if event_bus == null or inv_manager == null or save_manager == null:
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
				_phase_note_data()
				phase = 1
		1:
			if frame >= 6:
				_phase_pickup_static()
				phase = 2
		2:
			if frame >= 9:
				_phase_pickup_interact()
				phase = 3
		3:
			if frame >= 12:
				_phase_after_free()
				_finish()
				return true
	return false


## فاز ۰ — اعتبار داده‌ی ۵ نوت: لود، نوع، note_id یکتا و ترتیب order_index و متن‌های فارسی.
func _phase_note_data() -> void:
	var seen_ids: Array[StringName] = []
	for i in range(NOTE_PATHS.size()):
		var note: NarrativeNote = load(NOTE_PATHS[i]) as NarrativeNote
		var ok_note: bool = note != null
		_check(ok_note, "نوت %d لود می‌شود و از نوع NarrativeNote است" % (i + 1))
		var nid: StringName = StringName(note.note_id) if ok_note else &""
		_check(ok_note and nid != &"" and not seen_ids.has(nid),
			"note_id نوت %d غیرخالی و یکتاست" % (i + 1))
		_check(ok_note and note.order_index == i + 1,
			"order_index نوت %d برابر %d است" % [i + 1, i + 1])
		_check(ok_note and not String(note.title).is_empty(),
			"عنوان نوت %d غیرخالی است" % (i + 1))
		_check(ok_note and not String(note.body).is_empty(),
			"متن کامل نوت %d غیرخالی است" % (i + 1))
		_check(ok_note and not String(note.location_hint).is_empty(),
			"مکان‌نمای نوت %d غیرخالی است" % (i + 1))
		if ok_note:
			seen_ids.append(nid)


## فاز ۱ — وضعیت ایستای ۵ pickup: فقط اسکریپت موجود ItemPickup، بدون مصرف فوری، item_id دقیق، دسته GENERIC.
## خواص اختصاصی ItemPickup در زمان اجرا با get() خوانده می‌شوند (قرارداد ریپو — توضیح کامل در کامنت ابتدای فایل).
func _phase_pickup_static() -> void:
	for i in range(PICKUP_PATHS.size()):
		var pickup: Interactable = load(PICKUP_PATHS[i]).instantiate() as Interactable
		var ok_pickup: bool = pickup != null
		if ok_pickup:
			level.add_child(pickup)
			pickups.append(pickup)
		_check(ok_pickup, "pickup نوت %d لود می‌شود و ریشه‌اش Interactable/ItemPickup (اسکریپت موجود) است" % (i + 1))
		_check(ok_pickup and not bool(pickup.get("is_consumable_on_pickup")),
			"نوت %d در لحظه‌ی برداشت مصرف نمی‌شود (به کیف می‌رود)" % (i + 1))
		_check(ok_pickup and StringName(pickup.get("item_id")) == EXPECTED_ITEM_IDS[i],
			"item_id نوت %d دقیقاً narrative_note_* مطابق صحنه است" % (i + 1))
		_check(ok_pickup and int(pickup.get("item_category")) == GENERIC_CATEGORY_VALUE,
			"دسته‌ی نوت %d GENERIC (مقدار عددی ۰) است" % (i + 1))
		_check(ok_pickup and not String(pickup.get("prompt_message")).is_empty()
			and String(pickup.get("prompt_message")).begins_with("خواندن یادداشت:"),
			"پیام تعامل نوت %d با «خواندن یادداشت:» شروع می‌شود" % (i + 1))


## فاز ۲ — برداشت واقعی: interact بازیکن → سیگنال واقعی EventBus.item_picked_up → اینونتوری.
func _phase_pickup_interact() -> void:
	var player: Node3D = level.get_node_or_null("Player") as Node3D
	_check(player != null, "بازیکن برای تعامل حاضر است")
	for i in range(pickups.size()):
		var pickup: Interactable = pickups[i]
		var item_id: StringName = EXPECTED_ITEM_IDS[i]
		var before: int = int(inv_manager.count_item(item_id))
		_check(before == 0, "نوت %d پیش از برداشت در کیف نیست" % (i + 1))
		if pickup != null and player != null:
			pickup.interact(player)
		_check(int(inv_manager.count_item(item_id)) == 1,
			"interact واقعی → سیگنال item_picked_up → نوت %d به کیف رفت" % (i + 1))
		_check(pickup != null and pickup.is_queued_for_deletion(),
			"شیء pickup نوت %d پس از برداشت برای حذف در صف است" % (i + 1))


## فاز ۳ — پس از گذشت فریم: همه‌ی pickupها واقعاً آزاد شده‌اند و ۵ نوت در کیف است.
func _phase_after_free() -> void:
	for i in range(pickups.size()):
		_check(not is_instance_valid(pickups[i]),
			"pickup نوت %d پس از queue_free آزاد شده است" % (i + 1))
	_check(int(inv_manager.total_count()) == 5,
		"جمع واقعی کیف پس از برداشت هر ۵ نوت = ۵ است")


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
		print("ALL TESTS PASSED (narrative notes)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
