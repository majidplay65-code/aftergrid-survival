## تست کارکردی headless — PlayerStats: افت گرسنگی/تشنگی (فیکس «یافته‌ها» Task 2)
## باگِ فیکس‌شده در این لایه: بدون clamp + آسیب **هر فریم** در حالی‌که مقدار <= 0
## بود (caller، _physics_process بازیکن، هر فریم صدا می‌زد → ≈ ۶۰-۹۰ DPS، حتی
## با لودِ سیوی که مقدارش صفر بود).
## رفتارِ فیکس‌شده (گزینه‌ی A، تأییدشده):
##  - hunger/thirst clamp در [0, max]
##  - آسیب فقط یک‌بار، در لحظه‌ی گذار از مثبت به صفر
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/hunger_thirst_decay_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 10

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0
var stats: Variant = null


func _initialize() -> void:
	stats = PlayerStats.new()


func _process(_delta: float) -> bool:
	frame += 1
	if not started and frame >= 2:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	_check(stats != null, "PlayerStats instantiate می‌شود")
	if stats == null:
		return
	_check(absf(stats.hunger - 100.0) < 0.001 and absf(stats.thirst - 100.0) < 0.001,
			"مقادیر اولیه ۱۰۰/۱۰۰ است")
	# () گذار از مثبت به صفر: دقیقاً یک آسیب + مقدار clamp روی ۰
	stats.decrease_hunger(100.0)
	_check(absf(stats.hunger - 0.0) < 0.001, "Edge: گرسنگی روی ۰ clamp می‌شود (منفی نمی‌شود)")
	_check(absf(stats.health - 99.0) < 0.001, "Edge: گذار به صفر → ۱٫۰ آسیب، یک‌بار")
	# (۲) ادامه‌ی افت در حالی‌که صفر است: آسیبِ هر-فریم **نباید** تکرار شود (regression)
	stats.decrease_hunger(0.12)
	stats.decrease_hunger(0.12)
	stats.decrease_hunger(0.12)
	_check(absf(stats.health - 99.0) < 0.001,
			"Edge: افت تکراری در صفر → آسیب جدید نمی‌دهد (نه ۶۰ آسیب در ثانیه)")
	# (۳) پرکردن و افت دوباره: در گذارِ تازه دوباره یک آسیب
	stats.eat(50.0)
	stats.decrease_hunger(60.0)
	_check(absf(stats.health - 98.0) < 0.001, "Edge: گذار تازه بعد از خوردن → یک آسیب دوباره")
	# (۴) تشنگی: رفتار هم‌نوع با ۱٫۵ آسیب
	stats.decrease_thirst(100.0)
	_check(absf(stats.thirst - 0.0) < 0.001, "Edge: تشنگی روی ۰ clamp می‌شود")
	_check(absf(stats.health - 96.5) < 0.001, "Edge: گذار تشنگی به صفر → ۱٫۵ آسیب")
	# (۵) سناریوی لود: مقدار از سیو صفر آمده باشد → فریم اول نباید آسیب بدهد
	var loaded: Variant = PlayerStats.new()
	loaded.hunger = 0.0
	loaded.thirst = 0.0
	var health_before_load: float = loaded.health
	loaded.decrease_hunger(0.12)
	loaded.decrease_thirst(0.25)
	_check(absf(loaded.health - health_before_load) < 0.001,
			"Edge: مقدار صفر در لحظه‌ی لود → آسیبِ فریمِ اول نمی‌دهد")


func _check(ok: bool, label: String) -> void:
	checks_run += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
			"همه‌ی %d چک اجرا شد (اجراشده: %d)" % [EXPECTED_CHECK_COUNT, checks_run + 1])
	if failures == 0:
		print("ALL TESTS PASSED (hunger thirst decay)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
