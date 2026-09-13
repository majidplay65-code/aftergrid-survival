# Known Issues — شناسایی‌شده، بدون فیکس تا تأیید صریح مالک

این فایل یافته‌هایی را ثبت می‌کند که شناسایی شده‌اند ولی کد productionشان **دست‌نخورده** مانده است
(طبق قانون repo: فیکس فقط با تأیید صریح مالک). هر یافته شاهدِ دقیق دارد (commit / runِ CI).

---

## C. شاخه‌ی `is_instance_valid(target)` در `enemy.gd` از مسیر GDScript غیرقابل‌دسترس است

**کد:** `entities/enemy/enemy.gd` — تابع `has_line_of_sight_to(target: Node3D)`؛
گارد در commit [f49c81b](https://github.com/majidplay65-code/aftergrid-survival/commit/f49c81bedbb82b8ea7f48ed9d82ab01e4ea7a22b) (merge PR#15، فاز LoS) وارد شده:

```gdscript
func has_line_of_sight_to(target: Node3D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
```

**چرا غیرقابل‌دسترس است:** در Godot 4، پاس‌دادن instanceِ **freed** به پارامترِ **typed**
(`Node3D`) در **call-site** رد می‌شود — پیش از ورود به بدنه‌ی تابع — با این خطا:

```
SCRIPT ERROR: Invalid type in function 'has_line_of_sight_to' in base 'CharacterBody3D (Enemy)'.
The Object-derived class of argument 1 (previously freed) is not a subclass of the expected argument class.
```

یعنی هیچ فراخوانِ GDScript نمی‌تواند instanceِ freed را وارد این تابع کند؛ نیمه‌ی
`is_instance_valid` گارد هرگز برای فراخوانِ GDScript اجرا نمی‌شود. نیمه‌ی قابل‌دسترس فقط
`target == null` است. شاخه‌ی is_instance_valid صرفاً **defensive** است (فراخوان‌های غیر-GDScript
یا تغییرات آتی) و باگ عملیاتی نیست.

**شواهد (اجراهای واقعی CI):**
- run [34744092185](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34744092185)
  روی commit `ee04342` (branch `arena/01a0998b-aftergrid-survival`): تست `has_line_of_sight_to`
  را با instanceِ freed صدا زده بود → دقیقاً همان خطای بالا (run قرمز).
- بعد از تغییر edge-case (2) در `tests/line_of_sight_test.gd` به نیمه‌ی قابل‌دسترس
  (`target = null`)، همان سوئیت سبز شد: run [34744167176](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34744167176)
  (SHA `18790e679ca5b39a4d4249ee14623948cc3d5185`) و run [34744080225](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34744080225)
  روی PR#20 (SHA `82da154979fc687967d0570d74b65781da36bf62`).

**وضعیت:** بدون فیکس — awaiting owner decision (نگه‌داشتن گارد defensive یا ساده‌کردن به
`target == null`). تصمیم‌گیری با مالک repo.

---

## مرجع سریع — cooldown صدای هشدارِ جان کم (اعداد را حدس نزنید)

`autoloads/audio_manager.gd` → `low_health_warning_due(current_value, max_value, now_ms)`:
آستانه‌ی `LOW_HEALTH_WARNING_RATIO = 0.2` (فوق‌العاده‌ی «زیر» ۲۰٪ — **دقیقاً روی ۲۰٪ هشدار نمی‌دهد**)
+ cooldown `LOW_HEALTH_WARNING_COOLDOWN_MS = 4000` (۴ ثانیه، بر پایه‌ی `Time.get_ticks_msec()`)
+ event-driven از `EventBus.player_stat_changed` (stat `"health"`) — بدون polling.
تست: `tests/audio_low_health_warning_test.gd` (۱۷ چک + متا).

---

## تله‌۱ (لایه‌ی تست) — شناسه‌ی خام autoload در اسکریپتِ تستِ `-s`

در اسکریپتی که به‌عنوان main-loop با `godot --headless --path . -s res://tests/xxx_test.gd`
اجرا می‌شود، autoloadها به‌عنوان شناسه‌ی global **کمپایل نمی‌شوند**:

```
SCRIPT ERROR: Compile Error: Identifier not found: GameState
```

درحالی‌که همان شناسه‌ی خام در اسکریپتِ لودشده از صحنه (مثل `enemy.gd`) بدون مشکل کار می‌کند.
**الگوی درست در تست‌ها:** گرفتن مرجع با `root.get_node_or_null("Name")`
(نمونه: `tests/night_survive_test.gd:28`) —autoloadها در `_initialize()` با `_ensure_autoloads()`
به root اضافه می‌شوند.
**شاهد:** runهای قرمز [34743902856](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34743902856)
و [34743901651](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34743901651)
روی SHA `dcec537ca9c37246fa9c6d6f61f4dc04c9f64df9`.

## تله‌۲ (لایه‌ی تست) — instanceِ freed به پارامترِ typed

نمی‌توان تستی نوشت که «instanceِ freed را به متدِ typed بدهد» — زبان در call-site ردش می‌کند
(شاهد: run [34744092185](https://github.com/majidplay65-code/aftergrid-survival/actions/runs/34744092185)).
برای آزمونِ guardهای guard-against-freed، نیمه‌ی قابل‌رسیدن (null) را تست کنید و نیمه‌ی
دیگر را اینجا ثبت کنید (همان کاری که Finding C انجام داده).
