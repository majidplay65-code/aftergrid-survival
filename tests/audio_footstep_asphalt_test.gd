## تست کارکردی headless: صدای رویه‌ای «قدم روی آسفالت» (footstep_asphalt.wav)
## - فایل پروسیجرال موجود است و به‌عنوان AudioStream (WAV) لود می‌شود
## - نگاشت EventBus در AudioManager: قدم (راه‌رفتن) → صدای آسفالت (تابع خالص/قابل‌تست)
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/audio_footstep_asphalt_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
## نکته: در headless AudioManager اتصال‌های EventBus را نمی‌سازد (درایور صدا نیست)،
## بنابراین منطق نگاشت با تابع خالصِ footstep_sound_path تست می‌شود.
extends SceneTree

const ASPHALT_PATH: String = "res://assets/audio/footstep_asphalt.wav"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 11

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
	_check(ResourceLoader.exists(ASPHALT_PATH), "footstep_asphalt.wav در پروژه موجود است")
	var stream: Resource = load(ASPHALT_PATH)
	_check(stream != null, "footstep_asphalt.wav لود می‌شود")
	_check(stream is AudioStream, "فایل یک AudioStream است")
	_check(stream is AudioStreamWAV, "فایل از نوع AudioStreamWAV است")
	_check(am != null, "AudioManager autoload در دسترس است")
	if am == null:
		return
	_check(str(am.FOOTSTEP_ASPHALT) == ASPHALT_PATH, "ثابت FOOTSTEP_ASPHALT به فایل درست اشاره دارد")
	var walk_path: String = str(am.footstep_sound_path(false))
	var run_path: String = str(am.footstep_sound_path(true))
	_check(walk_path == ASPHALT_PATH, "نگاشت: راه‌رفتن → صدای آسفالت")
	_check(run_path == "res://assets/audio/footstep_metal.wav", "نگاشت: دویدن → صدای فلز")
	_check(ResourceLoader.exists(walk_path), "مسیر برگشتی راه‌رفتن موجود است")
	_check(ResourceLoader.exists(run_path), "مسیر برگشتی دویدن موجود است")


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
		print("ALL TESTS PASSED (audio footstep asphalt)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
