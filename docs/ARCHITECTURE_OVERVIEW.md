# معماری Aftergrid در یک صفحه — راهنمای توسعه‌دهنده‌ی تازه‌وارد

> نسخه: 0.28.0 — موتور: Godot 4.7.2 — زبان: GDScript با تایپ کامل
> این سند «قانون» نیست؛ برای درک سریع ساختار است. قانون‌ها در `AGENTS.md` هستند.

Aftergrid یک بازی بقای سه‌بعدی است که روی سه ستون ساخته شده. اگر فقط همین سه ستون را بفهمید، بقیه‌ی کد خودش معنا می‌شود: **داده در Resource**، **رفتار در StateMachine**، **ارتباط در EventBus**. هیچ سیستم‌ای حق ندارد با `get_node()` عمیق به سیستم دیگر نفوذ کند — همه‌چیز از طریق رویداد می‌گذرد.

## ستون ۱ — داده: الگوی Resource

هر چیزی که «مقدار» است، یک `Resource` است؛ نه صحنه و نه اسکریپتِ روی نودِ رفتاری. این یعنی همان چیزی که در ادیتور Godot قابل ویرایش است و در تست بدون صحنه قابل ساخت است.

- `resources/stats/player_stats.gd` — جان/استقامت/گرسنگی/تشنگی با setterهای clampشده و سیگنال `stat_changed`. مرگ فقط اینجا معنا دارد (سیگنال `died`).
- `resources/save_data.gd` — یک Data Object خالص: همه‌ی آمار + موقعیت بازیکن + محتوای اینونتوری + شماره‌ی شب + وضعیت رادیو. `save_version = 2`.
- `resources/items/item_data.gd` و `.tres`ها — هر آیتم (بطری آب، کنسرو، مدکیت، قراضه) یک فایل `.tres` است با `stat_restore_amount`.
- `resources/items/recipe_data.gd` و `resources/recipes/*.tres` — دستور ساخت به‌صورت داده: مواد لازم، خروجی، `craft_time`.
- `resources/inventory/inventory.gd` — کوله به‌عنوان Resource (سقف ۱۲ آیتم) — قابل تست بدون UI.
- `resources/world/world_clock.gd` — زمان روز به‌صورت نرمال‌شده (۰٫۰ تا ۱٫۰). «شب» یعنی `time_of_day >= 0.65` یا `< 0.20`.

**قاعده‌ی عملی:** اگر کد جدیدتان «مقداری» است که در ادیتور تنظیم می‌شود یا در تست ساخته می‌شود → Resource. اگر «کاری» است → نود/State.

## ستون ۲ — رفتار: StateMachine مبتنی بر نود

`core/state_machine/state.gd` کلاس `State` را می‌دهد (متدهای `enter(msg)`، `exit()`، `update`، `physics_update`، `handle_input`) و `state_machine.gd` فرزندانش را به‌عنوان حالت ثبت می‌کند. انتقال فقط با `transition_to(&"StateName")` از خود ماشین — هرگز مستقیم از بیرون.

نمونه‌ی اصلی: `entities/player/` (Idle/Walk/Run/Jump/Crouch/Dead و…) و `entities/enemy/states/` (Patrol → Chase → Attack → Investigate). سه نوع دشمن (Shambler/Stalker/Brute) **یک اسکریپت مشترک** `enemy.gd` دارند و فقط با overrideهای `@export` در `.tscn` تفاوت می‌کنند (جان، شنوایی، حافظه، سرعت، آسیب) — صحنه‌های دشمن تکراری نیستند؛ variantهای داده‌ای‌اند.

دشمن‌ها هیچ‌چیز را در `_process` poll نمی‌کنند؛ تغییر حالت فقط با سیگنال می‌آید (ورود به Area3D دید/حمله، شنیدن نویز). نکته‌ی مهم حافظه: بعد از قطع دید، دشمن `memory_seconds` ثانیه به نقطه‌ی آخر بازیکن می‌رود و جست‌وجو می‌کند.

## ستون ۳ — ارتباط: Autoload یک‌تکه به نام EventBus

`autoloads/event_bus.gd` تمام سیگنال‌های بین‌سیستمی را در یک جا دارد (حدود ۲۰ سیگنال). مثال‌های کلیدی:

- `noise_emitted(noise_position: Vector3, loudness: float)` — قلب سیستم آگاهی صوتی. پارامتر عمداً `noise_position` نام دارد تا با `Node3D.position` تداخل نامی نکند. منابع: قدم‌ها (خزیدن ۲٫۵ / راه‌رفتن ۶ / دویدن ۱۴)، پرش ۷، فرود ۹، فرود سخت ۱۴، ضربه ۸، ساخت ۱۰، درِ فروشگاه ۴.
- `enemy_died(death_position: Vector3)` → `core/loot/loot_spawner.gd` در محل مرگ قراضه می‌اندازد.
- `rest_requested(time_skip)` → `core/world/day_cycle.gd` زمان را جلو می‌بَرد.
- `night_survived(night_index)`، `time_of_day_changed(normalized)`، `toast_requested(message)`، `generator_charge_requested` و…

**قاعده‌ی عملی:** سیستم A سیستم B را «نمی‌شناسد»؛ فقط سیگنال می‌فرشد/می‌گیرد. UI فقط گوش می‌دهد.

## ترتیب Autoloadها (این ترتیب در `project.godot` تعهدشده است)

`EventBus` → `GameState` → `SceneManager` → `SaveManager` → `InventoryManager` → `CraftingSystem` → `AudioManager`

EventBus اول است چون بقیه در `_ready` به آن وصل می‌شوند. `GameState` مرجع بازیکن و وضعیت‌های global (توقف، شماره‌ی شب، رادیو) را نگه می‌دارد. `AudioManager` در حالت headless (CI) هیچ پخشی انجام نمی‌دهد.

## برای شروع کدنویسی

۱. یک دور به `levels/test_level.tscn` بزنید: اسپاون بازیکن `(0, 1, 7)`، فروشگاه امن `(-10, 0, 6)`، ژنراتور و کارگاه ناحیه‌ی `(10, 0, 10)`، رادیوی شرق `(26.5, 0, 22)`، چهار دشمن در گوشه‌ها. ۲. برای شناخت جریان سیگنال، از `noise_emitted` شروع کنید (منتشرکننده‌ها در `player.gd` و `crafting_system.gd`، شنونده در `enemy.gd: _on_noise_emitted`). ۳. قبل از استفاده‌ی هر API غیرقطعی، مستند رسمی Godot را چک کنید (قاعده‌ی ضد‌هذیان در `AGENTS.md`). ۴. برای هر فاز جدید، یک ورودی در `CHANGELOG.md` و (در صورت تغییر رفتار) به‌روزرسانی همین چک‌لیست‌ها.

> مدارک تکمیلی: `docs/ARCHITECT_REPORT.md` (حسابرسی مهندسی تا فاز ۲۷)، `docs/PHASE_HISTORY.md` (تاریخ فازها)، `docs/KNOWN_ISSUES.md` (بدهی‌های شناخته‌شده).
