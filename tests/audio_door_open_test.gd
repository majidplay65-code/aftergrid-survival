## تست کارکردی headless: صدای رویه‌ای «باز شدن در» (door_open.wav)
## - فایل پروسیجرال موجود است و به‌عنوان AudioStream (WAV) لود می‌شود
## - نگاشت EventBus.interaction_performed در AudioManager: تعامل با Door → صدای در
##   (تابع خالص/قابل‌تست؛ برای تعامل‌های غیردر مسیر خالی برمی‌گردد)
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/audio_door_open_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
## نکته: در headless AudioManager اتصال‌های EventBus را نمی‌سازد (درایور صدا نیست)،
## بنابراین منطق نگاشت با تابع خالصِ interaction_sound_path تست می‌شود.
## نکته: نمونه‌ی در از صحنه‌ی واقعی فروشگاه گرفته می‌شود (الگوی tests/interiors_test.gd) —
## بدون ارجاع کامپایل‌تایم به کلاس Door.
extends SceneTree

const DOOR_PATH: String = "res://assets/audio/door_open.wav"
const SHOP_PATH: String = "res://entities/world/safe_shop.tscn"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 13

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var am: Variant = null
var shop: Node = null


func _initialize() -> void:
	_ensure_autoloads()
	am = root.get_node_or_null("AudioManager")


func _process(_delta: float) -> bool:
	# autoloadها در حالت -s پیش از _initialize() ثبت می‌شوند ولی _ready()شان
	# فقط در نخستین فریم اجرا می‌شود (الگوی مشترک تست‌ها).
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(ResourceLoader.exists(DOOR_PATH), "door_open.wav در پروژه موجود است")
	var stream: Resource = load(DOOR_PATH)
	_check(stream != null, "door_open.wav لود می‌شود")
	_check(stream is AudioStream, "فایل یک AudioStream است")
	_check(stream is AudioStreamWAV, "فایل از نوع AudioStreamWAV است")
	_check(am != null, "AudioManager autoload در دسترس است")
	if am == null:
		return
	_check(str(am.DOOR_OPEN) == DOOR_PATH, "ثابت DOOR_OPEN به فایل درست اشاره دارد")

	# نمونه‌ی واقعی در از صحنه‌ی فروشگاه (الگوی interiors_test).
	var shop_packed: PackedScene = load(SHOP_PATH)
	_check(shop_packed != null, "صحنه‌ی فروشگاه لود می‌شود")
	if shop_packed == null:
		return
	shop = shop_packed.instantiate()
	root.add_child(shop)
	var door: Variant = shop.get_node_or_null("Door")
	_check(door != null, "نمونه‌ی واقعی در در صحنه‌ی فروشگاه موجود است")
	if door == null:
		return
	var door_script: Script = door.get_script()
	_check(door_script != null and String(door_script.get_global_name()) == "Door",
			"اسکریپت در از نظر class_name از نوع Door است")
	_check(str(am.interaction_sound_path(door)) == DOOR_PATH, "نگاشت: تعامل با Door → صدای در")
	var other: Node3D = Node3D.new()
	_check(str(am.interaction_sound_path(other)) == "", "نگاشت: تعامل غیردر → مسیر خالی")
	_check(ResourceLoader.exists(DOOR_PATH), "مسیر برگشتی در موجود است")
	other.free()
	shop.queue_free()


func _ensure_autoloads() -> void:
	var ordered: Array = [
		[&"EventBus", "res://autoloads/event_bus.gd"],
		[&"AudioManager", "res://autoloads/audio_manager.gd"],
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
	# محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید دقیقاً برابر مقدار انتظار
	# باشد (+۱ چون خودِ این چک هم شمرده می‌شود).
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (audio door open)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
