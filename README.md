# Aftergrid

> **اسم کاری (Working Title).** این اسم عمداً ساده و بدون ادعا انتخاب شده و **قفل نشده است**.
> تا وقتی MVP بازی نشده و ثابت نشده که لذت‌بخش است، وقت‌گذاشتن روی برندسازی (اسم رسمی، شعار، لوگو)
> اتلاف وقت است. اگر بازی به مرحله‌ی جدی رسید، اسم عوض می‌شود.

بازی بقا در دنیایی که شبکه (برق/ارتباطات/شهر) از کار افتاده است.

- **نام ریپو:** `aftergrid-survival` (lowercase و kebab-case — استاندارد GitHub و Godot)
- **موتور:** Godot 4.7
- **وضعیت فعلی:** فازهای `۰` تا `۲` انجام شده (Setup، Core Systems، Player). فاز بعدی: `۳` (World & Interaction).

---

## وضعیت فازها

| فاز | عنوان | وضعیت |
| --- | --- | --- |
| ۰ | Setup — ساختار ریپو + پروژه‌ی Godot که بالا می‌آید | ✅ انجام شد |
| ۱ | Core Systems — اتوبوس رویداد، وضعیت بازی، مدیر صحنه، ذخیره‌سازی، ماشین حالت، دیتای Resource | ✅ انجام شد |
| ۲ | Player — کاراکتر سه‌بعدی با حالت‌های Idle/Walk/Run، آمار بقا، دوربین موس | ✅ انجام شد |
| ۳ | World & Interaction — دنیای واقعی + سیستم تعامل (E) | ⬜ بعدی |

**معیار عبور از هر فاز:** یک نسخه‌ی قابل بازی که کسی بتواند ۵ دقیقه بازی‌اش کند و بگوید «ادامه بده».
اگر جواب «نه» بود، همان‌جا متوقف می‌شویم — نه بعد از نوشتن هزار خط کد.

---

## ساختار ریپو

```
aftergrid-survival/
├── README.md          ← معرفی پروژه + وضعیت فعلی فازها (همین فایل)
├── CHANGELOG.md       ← هر فاز که تمام شد، یک ورودی اضافه می‌شود
├── project.godot      ← تنظیمات پروژه‌ی Godot (نسخه 4.7، autoload ها، Input Map، صحنه‌ی اصلی)
├── icon.svg
├── .gitignore
│
├── autoloads/                      ← سینگلتون‌های سراسری (به‌ترتیب لود: EventBus اول)
│   ├── event_bus.gd                ← اتوبوس سیگنال (جایگزین game_events.gd قدیمی)
│   ├── game_state.gd               ← وضعیت سراسری بازی (pause، رفرنس بازیکن، مرحله‌ی فعلی)
│   ├── scene_manager.gd            ← تعویض متمرکز و امن صحنه
│   └── save_manager.gd             ← ذخیره/بارگذاری Resource باینری در user://saves/
├── core/
│   └── state_machine/              ← ماشین حالت Node-based
│       ├── state.gd                ← کلاس پایه‌ی انتزاعی هر حالت
│       └── state_machine.gd        ← ثبت فرزندها + جابه‌جایی با transition_to()
├── entities/
│   └── player/
│       ├── player.tscn             ← صحنه‌ی بازیکن (طبق درخت «قدم ۴» پایین)
│       ├── player.gd               ← کنترلر CharacterBody3D (حرکت خام، پرش، دوربین موس)
│       └── states/                 ← حالت‌های بازیکن (نام نود = نام حالت)
│           ├── idle_state.gd
│           ├── walk_state.gd
│           └── run_state.gd        ← مصرف استامینا + برگشت خودکار به Walk
├── resources/
│   ├── save_data.gd                ← کانتینر داده‌ی خالص برای سیو (بدون منطق)
│   └── stats/
│       └── player_stats.gd         ← آمار بازیکن (health/stamina/hunger/thirst) + منطق ایمن تغییر
├── levels/
│   └── test_level.tscn             ← صحنه‌ی تست: زمین + نمونه‌ی Player (صحنه‌ی اصلی پروژه)
└── ui/                             ← منوها، HUD، دیالوگ‌ها (فعلاً خالی — فازهای بعد)
```

> پوشه‌های خالی در git ردیابی نمی‌شوند، برای همین در هرکدام یک `.gitkeep` گذاشته شده است.
> به محض گذاشتن اولین فایل واقعی، آن `.gitkeep` را پاک کن.

## قراردادها

- **نام فایل‌ها:** `snake_case.gd` و `snake_case.tscn`
- **نام کلاس‌ها / نودها:** `PascalCase`
- **ارتباط بین سیستم‌ها:** فقط از طریق `autoloads/event_bus.gd`. هیچ `get_node()` عمیقی بین ماژول‌ها.
- **معماری:** دیتا در `Resource`، رفتار در State Machine مبتنی بر Node، ارتباط در `EventBus`.
- **GDScript:** همیشه typed (نوع همه‌ی متغیرها، آرگومان‌ها و خروجی‌ها مشخص).
- **زبان کامنت‌ها:** فارسی (این ریپو شخصی است و خوانایی برای خودت مهم‌تر از استاندارد جهانی است).
- **هر فاز = یک ورودی در `CHANGELOG.md`.**

---

## راه‌اندازی (Setup) — فاز ۰ تا ۲

> همه‌ی موارد زیر از قبل داخل `project.godot` و صحنه‌ها اعمال شده و با `F5` اجرا می‌شود.
> این بخش سند مرجع است: اگر پروژه را از صفر در ادیتور ساختی، قدم‌ها را به همین ترتیب انجام بده.

## قدم ۱ — ساخت پروژه

1. Godot 4.7 (نسخه‌ی Standard) را باز کن.
2. New Project بزن، Renderer را روی **Forward+** یا **Mobile** بگذار (برای شروع Mobile سبک‌تر است).
3. فایل‌های این ریپو را داخل `res://` داشته باش، دقیقاً با همین نام پوشه‌ها.

## قدم ۲ — ثبت Autoload ها (بسیار مهم و به‌ترتیب)

مسیر: **Project → Project Settings → Autoload**

به همین ترتیب اضافه کن (ترتیب مهم است چون EventBus باید قبل از بقیه لود شود):

| Path | Node Name |
|---|---|
| `res://autoloads/event_bus.gd` | `EventBus` |
| `res://autoloads/game_state.gd` | `GameState` |
| `res://autoloads/scene_manager.gd` | `SceneManager` |
| `res://autoloads/save_manager.gd` | `SaveManager` |

بعد از اضافه‌کردن هر کدام، دکمه‌ی **Add** را بزن. اسم نود (ستون دوم) باید دقیقاً همین‌ها باشد
چون در کدها با همین نام‌ها صدایشان می‌زنیم (مثلاً `EventBus.player_died.emit()`).

## قدم ۳ — تعریف Input Map

مسیر: **Project → Project Settings → Input Map**

این اکشن‌ها را بساز و برای هرکدام حداقل یک کلید اختصاص بده:

| Action Name | کلید پیشنهادی |
|---|---|
| `move_forward` | W |
| `move_back` | S |
| `move_left` | A |
| `move_right` | D |
| `run` | Shift |
| `jump` | Space |
| `interact` | E |

(اکشن `ui_cancel` از قبل توسط Godot ساخته شده است — Esc.)

## قدم ۴ — ساختار صحنه‌ی بازیکن (Player.tscn)

فایل `res://entities/player/player.tscn` با این ساختار دقیق نودها ساخته شده است:

```
Player  (CharacterBody3D)  <- اسکریپت: entities/player/player.gd
├── CollisionShape3D        <- یک CapsuleShape3D بهش بده
├── MeshInstance3D           <- یک CapsuleMesh موقت برای دیدن بازیکن
├── CameraPivot  (Node3D)    <- در ارتفاع Y = 1.6 (شبیه ارتفاع چشم)
│   └── Camera3D             <- کمی عقب‌تر (نمای سوم‌شخص برای تست)
└── StateMachine  (Node)     <- اسکریپت: core/state_machine/state_machine.gd
    ├── IdleState  (Node)    <- اسکریپت: entities/player/states/idle_state.gd
    ├── WalkState  (Node)    <- اسکریپت: entities/player/states/walk_state.gd
    └── RunState   (Node)    <- اسکریپت: entities/player/states/run_state.gd
```

نکات حیاتی:

- نام هر نود (IdleState, WalkState, RunState) باید **دقیقاً** همین باشد، چون `transition_to(&"WalkState")` با نام نود کار می‌کند.
- روی نود `StateMachine`، در Inspector، فیلد `Initial State` به `IdleState` وصل است.
- روی هر یک از سه نود State (Idle/Walk/Run)، در Inspector فیلد `Player` به نود ریشه‌ی `Player` وصل است.
- `CameraPivot` در Y = 1.6 قرار دارد تا شبیه ارتفاع چشم باشد.

## قدم ۵ — تست

1. صحنه‌ی تست `res://levels/test_level.tscn` شامل یک `StaticBody3D` صاف به‌عنوان زمین + نور + سه جعبه‌ی نشانه (برای فهمیدن حرکت) + نمونه‌ی `Player.tscn` است.
2. این صحنه به‌عنوان Main Scene تنظیم شده: **Project Settings → Application → Run → Main Scene**.
3. Run بزن (F5). باید بتوانی با WASD حرکت کنی، با Shift بدوی، و با Space بپری.

## چک‌لیست صحت (Definition of Done فاز ۰+۱+۲)

- [ ] بازیکن با WASD حرکت می‌کند و شتاب/اصطکاک طبیعی دارد
- [ ] با نگه‌داشتن Shift سرعت افزایش می‌یابد و استامینا (در کد، از طریق `player.stats.stamina`) کم می‌شود
- [ ] با رهاکردن Shift یا اتمام استامینا، به‌صورت خودکار به WalkState برمی‌گردد
- [ ] Space باعث پرش می‌شود
- [ ] موس دوربین را می‌چرخاند و Esc موس را آزاد/قفل می‌کند
- [ ] در خروجی Output هیچ Error یا Warning قرمزی دیده نمی‌شود

اگر همه‌ی این‌ها تیک خورد، فاز ۰+۱+۲ رسماً کامل است و می‌روی سراغ فاز ۳ (World & Interaction).

---

## اجرا

1. Godot 4.7 یا بالاتر را نصب کن.
2. Godot را باز کن و **Import** را بزن، `project.godot` را انتخاب کن.
3. `F5` — صحنه‌ی `levels/test_level.tscn` اجرا می‌شود: با WASD حرکت، Shift دویدن، Space پرش، E تعامل (فاز ۳)، Esc آزاد/قفل موس.

## نکته درباره‌ی استفاده از AI برای فازهای بعدی

برای هر فاز بعدی، این متن را دقیقاً به‌عنوان context اول به مدل بده:
«من از Godot 4.7 با GDScript typed استفاده می‌کنم. معماری من: Resource برای داده، Node-based State Machine برای رفتار، EventBus Autoload برای ارتباط بین سیستم‌ها. این فایل‌های موجودم هستند: [فایل‌های این پوشه را پیست کن]. حالا فاز بعدی (Interaction System) را با همین سبک و بدون تغییر معماری فعلی پیاده‌سازی کن.»
