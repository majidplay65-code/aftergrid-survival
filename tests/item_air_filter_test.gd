## تست کارکردی headless: آیتم جدید «فیلتر هوا» (air_filter.tres)
## - بارگذاری .tres و راستی‌آزمایی مقادیر ItemData
## - حضور آیتم در کاتالوگ اصلی
## - رعایت max_stack (۲) در Inventory واقعی
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/item_air_filter_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const FILTER_PATH: String = "res://resources/items/air_filter.tres"
const CATALOG_PATH: String = "res://resources/item_catalog.tres"

## تعداد چک‌هایی که باید در یک اجرای کامل اجرا شوند (محافظِ «خطای خاموشِ API»).
const EXPECTED_CHECK_COUNT: int = 16

var frame: int = 0
var started: bool = false
var checks_run: int = 0
var failures: int = 0


func _process(_delta: float) -> bool:
	# autoloadها/فریم‌های اول صبر می‌کنیم تا موتور پایدار باشد (الگوی مشترک تست‌ها).
	frame += 1
	if not started and frame >= 3:
		started = true
		_run()
		_finish()
		return true
	return false


func _run() -> void:
	var raw: Resource = ResourceLoader.load(FILTER_PATH)
	_check(raw != null, "air_filter.tres لود می‌شود")
	if raw == null:
		return
	_check(raw is ItemData, "air_filter.tres از نوع ItemData است")
	var item: ItemData = raw as ItemData
	_check(item.item_id == &"air_filter", "air_filter شناسه‌ی air_filter دارد")
	_check(item.item_name == "فیلتر هوا", "air_filter نام فارسی درست دارد")
	_check(item.description != "", "air_filter توضیح خالی ندارد")
	_check(item.category == ItemData.ItemCategory.TOOL, "air_filter دسته‌ی TOOL دارد")
	_check(item.max_stack == 2, "air_filter max_stack=2 دارد")
	_check(item.is_consumable == false, "air_filter غیرقابل‌مصرف است")
	_check(item.stat_restore_amount == 0.0, "air_filter مقدار بازیابی آمار صفر دارد")

	var catalog: Resource = ResourceLoader.load(CATALOG_PATH)
	_check(catalog != null and catalog is ItemCatalog, "کاتالوگ اصلی لود و از نوع ItemCatalog است")
	var cat: ItemCatalog = catalog as ItemCatalog
	if cat == null:
		return
	_check(cat.has_item(&"air_filter"), "air_filter در کاتالوگ اصلی ثبت شده است")
	_check(cat.get_item(&"air_filter") == item, "نمونه‌ی کاتالوگ همان air_filter.tres است")

	# max_stack در Inventory واقعی رعایت می‌شود (سقف انباشت ۲).
	var inv: Inventory = Inventory.new()
	inv.catalog = cat
	_check(inv.add_item(&"air_filter", 2) == 2, "۲ فیلتر هوا به Inventory اضافه می‌شود")
	_check(inv.add_item(&"air_filter", 1) == 0, "پس از پر شدن stack، فیلتر هوا اضافه نمی‌شود")
	_check(inv.count_item(&"air_filter") == 2, "تعداد فیلتر هوا روی ۲ می‌ماند")


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
		print("ALL TESTS PASSED (item air filter)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
