## تست کارکردی headless: صدای رویه‌ای «موفقیت ساخت» (craft_success.wav)
## - فایل پروسیجرال موجود است و به‌عنوان AudioStream (WAV) لود می‌شود
## - نگاشت EventBus.item_crafted در AudioManager → چایم موفقیت (تابع خالص/قابل‌تست)
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/audio_craft_success_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
## نکته: در headless AudioManager اتصال‌های EventBus را نمی‌سازد (درایور صدا نیست)،
## بنابراین منطق نگاشت با تابع خالصِ craft_sound_path تست می‌شود.
extends SceneTree

const CRAFT_SUCCESS_PATH: String = "res://assets/audio/craft_success.wav"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 10

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var am: Variant = null


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
	_check(ResourceLoader.exists(CRAFT_SUCCESS_PATH), "craft_success.wav در پروژه موجود است")
	var stream: Resource = load(CRAFT_SUCCESS_PATH)
	_check(stream != null, "craft_success.wav لود می‌شود")
	_check(stream is AudioStream, "فایل یک AudioStream است")
	_check(stream is AudioStreamWAV, "فایل از نوع AudioStreamWAV است")
	_check(am != null, "AudioManager autoload در دسترس است")
	if am == null:
		return
	_check(str(am.CRAFT_SUCCESS) == CRAFT_SUCCESS_PATH, "ثابت CRAFT_SUCCESS به فایل درست اشاره دارد")
	var path: String = str(am.craft_sound_path())
	_check(path == CRAFT_SUCCESS_PATH, "نگاشت: item_crafted → چایم موفقیت")
	_check(ResourceLoader.exists(path), "مسیر برگشتی موجود است")
	_check(am.has_method("_on_item_crafted"), "handler سیگنال item_crafted وجود دارد")


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
		print("ALL TESTS PASSED (audio craft success)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
