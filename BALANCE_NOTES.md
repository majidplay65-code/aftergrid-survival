# BALANCE_NOTES.md — مستندسازی مقادیر بالانس فعلی

> ⚠️ **این فایل صرفاً مستندسازی است.** هیچ مقداری در هیچ کدی تغییر نکرده و تغییر نخواهد کرد.
> تمام اعداد مستقیماً از کد واقعی پروژه (سینتکس `const`/`@export` و فرمول‌های عینی) خوانده شده‌اند؛
> منبع هر عدد در ستون «منبع» ذکر شده است. تاریخ گردآوری: جلسه‌ی پولیش UI/نوت‌های روایی (شماره‌ی خط از کد فعلی است).

## ۱) بازیکن — حرکت و فیزیک (`entities/player/player.gd`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| سرعت راه‌رفتن | `WALK_SPEED` | 3.5 | player.gd:7 |
| سرعت دویدن | `RUN_SPEED` | 6.5 | player.gd:8 |
| سرعت خزیدن | `CROUCH_SPEED` | 1.6 | player.gd:9 |
| شتاب افقی | `ACCELERATION` | 10.0 | player.gd:10 |
| اصطکاک | `FRICTION` | 12.0 | player.gd:11 |
| سرعت اولیه‌ی پرش | `JUMP_VELOCITY` | 4.5 | player.gd:12 |
| کنترل هوایی | `AIR_CONTROL_SPEED` | 3.0 | player.gd:13 |
| حساسیت موس | `MOUSE_SENSITIVITY` | 0.0025 | player.gd:18 |
| FOV عادی / دویدن | `WALK_FOV` / `RUN_FOV` | 75.0 / 85.0 | player.gd:19-20 |
| ارتفاع کپسول ایستاده / خزیده | `STAND_CAPSULE_HEIGHT` / `CROUCH_CAPSULE_HEIGHT` | 1.8 / 1.2 | player.gd:23-24 |

## ۲) بازیکن — بقای و آسیب (`player.gd` + `resources/stats/player_stats.gd`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| کاهش تشنگی | `THIRST_DECAY_RATE` | 0.25 در ثانیه | player.gd:33 |
| کاهش گرسنگی | `HUNGER_DECAY_RATE` | 0.12 در ثانیه | player.gd:34 |
| آسیب وقتی تشنگی صفر | — | 1.5 در ثانیه | player_stats.gd (`decrease_thirst`) |
| آسیب وقتی گرسنگی صفر | — | 1.0 در ثانیه | player_stats.gd (`decrease_hunger`) |
| سقف و مقدار اولیه‌ی همه‌ی آمارها | `max_*` | 100.0 | player_stats.gd (پیش‌فرض @export) |
| حد آسیب‌دار سقوط | `FALL_DAMAGE_SPEED` | 12.0 (سرعت قله‌ی سقوط) | player.gd:16 |
| فرمول آسیب فرود سخت | — | `(peak − 12.0) × 4.0` | player.gd (`land_from_jump`) |
| استقامت مصرفی ضربه‌ی نزدیک | `MELEE_STAMINA_COST` | 12.0 | player.gd:27 |
| آسیب ضربه‌ی نزدیک | `MELEE_DAMAGE` | 15.0 | player.gd:30 |
| برد ضربه‌ی نزدیک | `MELEE_RANGE` | 2.0 | player.gd:29 |
| مصرف استقامت دویدن | `STAMINA_COST_PER_SECOND` | 15.0 | states/run_state.gd:6 |
| بازیابی استقامت (ایستاده) | `STAMINA_REGEN_RATE` | 16.0 در ثانیه | states/idle_state.gd:6 |
| بازیابی استقامت (راه‌رفتن) | `STAMINA_REGEN_RATE` | 10.0 در ثانیه | states/walk_state.gd:6 |
| بازیابی استقامت (خزیدن) | `STAMINA_REGEN_RATE` | 10.0 در ثانیه | states/crouch_state.gd:7 |
| سقف باتری چراغ‌قوه | `MAX_FLASHLIGHT_BATTERY` | 100.0 | player.gd:26 |
| تخلیه‌ی باتری چراغ‌قوه | `FLASHLIGHT_DRAIN_RATE` | 8.0 در ثانیه (وقتی روشن) | player.gd:25 |

## ۳) صدا (Noise) — همه از منابع موجود، بدون شلیک

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| صدای قدم دویدن | — | بلندی 14.0، هر 0.32s | player.gd:127-128 (`_tick_footstep_noise`) |
| صدای قدم راه‌رفتن | — | بلندی 6.0، هر 0.48s | player.gd:129-130 |
| صدای قدم خزیدن | — | بلندی 2.5، هر 0.70s | player.gd:131-132 |
| صدای پرش | `JUMP_NOISE` | 7.0 | player.gd:14 |
| صدای فرود عادی | `LAND_NOISE` | 9.0 | player.gd:15 |
| صدای فرود سخت | `HARD_LAND_NOISE` | 14.0 | player.gd:17 |
| صدای ضربه‌ی نزدیک | `MELEE_NOISE` | 8.0 | player.gd:28 |
| صدای بازکردن در | `OPEN_NOISE` | 4.0 | entities/interactables/door.gd:10 |
| صدای ساخت | — | 10.0 (دور از بازیکن، در محل او) | core/crafting/crafting_system.gd:111 |

## ۴) دشمن‌ها (پایه در `entities/enemy/enemy.gd`؛ مقادیر instanced در صحنه‌ها)

| مقدار | شامبلر (پایه) | بروت (enemy_brute.tscn) | استاکر (enemy_stalker.tscn) | منبع |
|---|---|---|---|---|
| سلامتی | 40.0 | 70.0 | 25.0 | enemy.gd:32 + override در tscn |
| شنوایی (`hearing_multiplier`) | 1.0 | 0.6 | 1.5 | enemy.gd:29 + override در tscn |
| حافظه (`memory_seconds`) | 4.0 | 2.5 | 6.0 | enemy.gd:50 + override در tscn |
| آسیب هر ضربه (`damage_amount`) | 8.0 | 18.0 | 5.0 | DamageComponent داخل tscn |
| کول‌داون ضربه (`cooldown`) | 1.2s | 1.8s | 0.9s | DamageComponent داخل tscn |
| شتاب / اصطکاک | 8.0 / 10.0 | 8.0 / 10.0 | 8.0 / 10.0 | enemy.gd:12-13 (بدون override) |
| ارتفاع چشم | `EYE_HEIGHT` 1.1 | 1.1 | 1.1 | enemy.gd:14 |

> نکته: مقدار پیش‌فرض اسکریپت `DamageComponent.damage_amount` برابر 10.0 است، اما هر سه صحنه‌ی دشمن آن را override می‌کنند؛ اعداد جدول همان مقادیر واقعی داخل صحنه‌ها هستند.

## ۵) دشمن — حالت‌ها (`entities/enemy/states/`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| سرعت تعقیب | `speed` | 3.2 | chase_state.gd:11 |
| سرعت بررسی | `speed` | 2.4 | investigate_state.gd:13 |
| سرعت گشت | `speed` | 2.0 | patrol_state.gd:11 |
| فاصله‌ی رسیدن (بررسی) | `ARRIVE_DISTANCE` | 0.8 | investigate_state.gd:9 |
| فاصله‌ی رسیدن (گشت) | `ARRIVE_DISTANCE` | 0.6 | patrol_state.gd:7 |
| زمان رهاکردن (بررسی) | `GIVE_UP_SECONDS` | 6.0 (پیش‌فرض؛ اگر `memory_seconds > 0` باشد همان حافظه‌ی دشمن ملاک است) | investigate_state.gd:10,30 |

## ۶) ساخت (`core/crafting/crafting_system.gd` + `resources/recipes/`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| شعاع دسترسی به میز ساخت | `STATION_RANGE` | 3.0 | crafting_system.gd:23 |
| دستور «فیلتر آب» | `craft_water_filter` | 2× قراضه → ۱ بطری آب، `craft_time` = 1.0s | resources/recipes/craft_water_filter.tres |
| دستور «کیت کمک‌های اولیه» | `craft_medkit` | 1× کنسرو + 1× قراضه → ۱ مدکیت، `craft_time` = 3.0s | resources/recipes/craft_medkit.tres |

## ۷) آیتم‌ها (`resources/items/*.tres`)

| آیتم | دسته (`category`) | بیشینه‌ی پشته | مصرفی | بازیابی (`stat_restore_amount`) | منبع |
|---|---|---|---|---|---|
| بطری آب (`water_bottle`) | WATER = 1 | 5 | بله | تشنگی 30.0 | water_bottle.tres |
| کنسرو (`canned_food`) | FOOD = 2 | 5 | بله | گرسنگی 35.0 | canned_food.tres |
| مدکیت (`medkit`) | MEDKIT = 3 | 3 | بله | جان 40.0 | medkit.tres |
| قراضه‌ی فلز (`scrap_metal`) | SCRAP = 4 | 10 | خیر | — | scrap_metal.tres |

## ۸) اینونتوری (`resources/inventory/inventory.gd`)

| مقدار | نام | مقدار عددی | منبع |
|---+---|---|---|---|
| سقف مجموع آیتم‌ها | `MAX_TOTAL_ITEMS` | 12 | inventory.gd:23 |
| پشته‌ی نامحدود برای آیتم‌های ناشناخته | `UNLIMITED_STACK` | 2147483647 | inventory.gd:21 |

## ۹) تعامل‌ها (`entities/interactables/`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| رادیو — هزینه‌ی فعال‌سازی | `COST_ITEM` × `COST_AMOUNT` | 1× `scrap_metal` | radio_beacon.gd:6-7 |
| پناهگاه — بازیابی گرسنگی/تشنگی | `hunger_restore` / `thirst_restore` | 8.0 / 8.0 | rest_spot.gd:6-7 |
| پناهگاه — پرش زمان | `time_skip` | 0.08 (از چرخه‌ی روز) | rest_spot.gd:8 |
| در — صدای بازکردن | `OPEN_NOISE` | 4.0 | door.gd:10 |

## ۱۰) چرخه‌ی شبانه‌روز (`resources/world/world_clock.gd` + `core/world/day_cycle.gd`)

| مقدار | نام | مقدار عددی | منبع |
|---|---|---|---|
| شروع `time_of_day` | `time_of_day` | 0.40 (بعدازظهر) | world_clock.gd:7 |
| طول روز | `day_length_seconds` | 360.0s (۶ دقیقه) | world_clock.gd:9 |
| سپیده‌دم | `DAWN` | 0.25 | day_cycle.gd:57 |
| بازه‌ی شب | — | از 0.65 تا 0.20 چرخه (۲۰٪ از روز) | world_clock.gd:21 (`is_night`) |

## خلاصه‌ی طراحی بقا (تحلیل مستند — بدون تغییر کد)

- یک بطری آب +30 تشنگی؛ با نرخ تخلیه 0.25/s معادل حدود **۱۲۰ ثانیه‌ی بقا**.
- یک کنسرو +35 گرسنگی؛ با نرخ 0.12/s معادل حدود **۲۹۱ ثانیه‌ی بقا**.
- یک مدکیت +40 جان (از 100).
- چراغ‌قوه از 100 تا 0 در حدود **۱۲.۵ ثانیه‌ی روشن** خالی می‌شود (100/8) — شارژ مجدد از ژنراتور لازم است.
- دویدن 15.0 استقامت/ثانیه مصرف می‌کند؛ بازیابی ایستاده 16.0/ثانیه است (خالص ایستادن بازیابی می‌دهد).
- سقوط با سرعت قله‌ی زیر ۱۲ کاملاً امن است؛ فرود سخت `(peak − 12) × 4` آسیب می‌زند (سرعت ۱۵ ⇒ ۱۲ آسیب).
- اینونتوری تنها ۱۲ آیتم مجموع نگه می‌دارد — جمع‌آوری قراضه باید همراه مصرف/ساخت باشد.
- شب ۲۰٪ از چرخه‌ی ۶ دقیقه‌ای است (**۷۲ ثانیه**)؛ هر شب یک «شب زنده‌ماندن» شمرده می‌شود.
