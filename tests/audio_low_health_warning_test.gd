## تست کارکردی headless: صدای اخطار «جان کم» (low_health_warn.wav)
## - فایل پروسیجرال موجود است و به‌عنوان AudioStream (WAV) لود می‌شود
## - تصمیم هشدار (آستانه‌ی ۲۰٪ + cooldown ۴ ثانیه) با تابع خالصِ قابل‌تست
##   low_health_warning_due پوشش می‌شود: بالای آستانه → نه؛ زیر آستانه → بله؛
##   زیر آستانه داخل cooldown → نه؛ بعد از اتمام cooldown → بله.
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/audio_low_health_warning_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
## نکته: در headless AudioManager اتصال‌های EventBus را نمی‌سازد (درایور صدا نیست)،
## بنابراین منطق تصمیم با تابع خالص تست می‌شود (الگوی tests/audio_craft_success_test.gd).
extends SceneTree

const LOW_HEALTH_WARN_PATH: String = "res://assets/audio/low_health_warn.wav"
const AUDIO_SCRIPT: String = "res://autoloads/audio_manager.gd"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 18

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
	_check(ResourceLoader.exists(LOW_HEALTH_WARN_PATH), "low_health_warn.wav در پروژه موجود است")
	var stream: Resource = load(LOW_HEALTH_WARN_PATH)
	_check(stream != null, "low_health_warn.wav لود می‌شود")
	_check(stream is AudioStream, "فایل یک AudioStream است")
	_check(stream is AudioStreamWAV, "فایل از نوع AudioStreamWAV است")
	_check(am != null, "AudioManager autoload در دسترس است")
	if am == null:
		return
	_check(str(am.LOW_HEALTH_WARNING) == LOW_HEALTH_WARN_PATH, "ثابت LOW_HEALTH_WARNING به فایل درست اشاره دارد")
	_check(am.has_method("low_health_warning_due"), "تابع تصمیم low_health_warning_due وجود دارد")
	_check(am.has_method("_on_player_stat_changed"), "handler سیگنال player_stat_changed وجود دارد")
	_check(_file_contains(AUDIO_SCRIPT, "low_health_warning_due(current_value, max_value, Time.get_ticks_msec())"),
			"handler واقعاً از تابع تصمیم با زمان جاری استفاده می‌کند (سیم‌بندی)")
	# ── آستانه و cooldown (تابع خالص؛ زمان‌های ترکیبی — بدون polling) ──
	_check(am.low_health_warning_due(60.0, 100.0, 1000) == false,
			"جان بالای آستانه (۶۰٪) → هشدار نمی‌شود")
	_check(am.low_health_warning_due(15.0, 100.0, 2000) == true,
			"جان زیر آستانه (۱۵٪) → هشدار می‌شود")
	_check(am.low_health_warning_due(12.0, 100.0, 3500) == false,
			"دوباره زیر آستانه داخل cooldown (۱٫۵ ثانیه) → هشدار دوم نمی‌شود")
	_check(am.low_health_warning_due(12.0, 100.0, 5999) == false,
			"مرز cooldown (۳٫۹۹۹ ثانیه) → هنوز هشدار نمی‌شود")
	_check(am.low_health_warning_due(12.0, 100.0, 6000) == true,
			"پایان cooldown (۴ ثانیه) → هشدار دوباره می‌شود")
	_check(am.low_health_warning_due(20.0, 100.0, 10000) == false,
			"دقیقاً روی آستانه (۲۰٪) → هشدار نمی‌شود (فوق‌العاده‌ی «زیر»)")
	_check(am.low_health_warning_due(0.0, 0.0, 11000) == false,
			"max_health صفر → خطا/تقسیم بر صفر نمی‌دهد")
	_check(am.low_health_warning_due(4.0, 20.0, 12000) == false,
			"نسبت روی مقیاس‌های دیگر هم درست است (۴ از ۲۰ = ۲۰ درصد → نه)")


func _file_contains(path: String, snippet: String) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	return f.get_as_text().contains(snippet)


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
		print("ALL TESTS PASSED (audio low health warning)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
