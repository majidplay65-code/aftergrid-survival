## تست کارکردی headless: آیتم جدید «طناب» (rope.tres)
## - بارگذاری .tres و راستی‌آزمایی مقادیر ItemData
## - حضور آیتم در کاتالوگ اصلی
## - رعایت max_stack (۳) در Inventory واقعی
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه):
##   godot --headless --path . -s res://tests/item_rope_test.gd
##
## کد خروجی ۰ = همه‌ی تست‌ها پاس، ۱ = شکست.
extends SceneTree

const ROPE_PATH: String = "res://resources/items/rope.tres"
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
	var raw: Resource = ResourceLoader.load(ROPE_PATH)
	_check(raw != null, "rope.tres لود می‌شود")
	if raw == null:
		return
	_check(raw is ItemData, "rope.tres از نوع ItemData است")
	var item: ItemData = raw as ItemData
	_check(item.item_id == &"rope", "rope شناسه‌ی rope دارد")
	_check(item.item_name == "طناب", "rope نام فارسی درست دارد")
	_check(item.description != "", "rope توضیح خالی ندارد")
	_check(item.category == ItemData.ItemCategory.TOOL, "rope دسته‌ی TOOL دارد")
	_check(item.max_stack == 3, "rope max_stack=3 دارد")
	_check(item.is_consumable == false, "rope غیرقابل‌مصرف است")
	_check(item.stat_restore_amount == 0.0, "rope مقدار بازیابی آمار صفر دارد")

	var catalog: Resource = ResourceLoader.load(CATALOG_PATH)
	_check(catalog != null and catalog is ItemCatalog, "کاتالوگ اصلی لود و از نوع ItemCatalog است")
	var cat: ItemCatalog = catalog as ItemCatalog
	if cat == null:
		return
	_check(cat.has_item(&"rope"), "rope در کاتالوگ اصلی ثبت شده است")
	_check(cat.get_item(&"rope") == item, "نمونه‌ی کاتالوگ همان rope.tres است")

	# max_stack در Inventory واقعی رعایت می‌شود (سقف انباشت ۳).
	var inv: Inventory = Inventory.new()
	inv.catalog = cat
	_check(inv.add_item(&"rope", 3) == 3, "۳ طناب به Inventory اضافه می‌شود")
	_check(inv.add_item(&"rope", 1) == 0, "پس از پر شدن stack، طناب اضافه نمی‌شود")
	_check(inv.count_item(&"rope") == 3, "تعداد طناب روی ۳ می‌ماند")


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
		print("ALL TESTS PASSED (item rope)")
		quit(0)
	else:
		printerr("%d TEST(S) FAILED" % failures)
		quit(1)
