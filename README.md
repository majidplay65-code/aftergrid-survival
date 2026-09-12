# Aftergrid

> **اسم کاری (Working Title).** این اسم عمداً ساده و بدون ادعا انتخاب شده و **قفل نشده است**.
> تا وقتی MVP بازی نشده و ثابت نشده که لذت‌بخش است، وقت‌گذاشتن روی برندسازی (اسم رسمی، شعار، لوگو)
> اتلاف وقت است. اگر بازی به مرحله‌ی جدی رسید، اسم عوض می‌شود.

بازی بقا در دنیایی که شبکه (برق/ارتباطات/شهر) از کار افتاده است.

- **نام ریپو:** `aftergrid-survival` (lowercase و kebab-case — استاندارد GitHub و Godot)
- **موتور:** Godot 4.7
- **وضعیت فعلی:** فازهای `۰` تا `۶` کامل و **تأیید**شده با CI + فازهای `۷` تا `۲۵` پیاده‌سازی‌شده (۰.۲۶.۰) — تست دستی کاربر برای ۷–۲۵ هنوز انجام نشده.

---

## وضعیت فازها

| فاز | عنوان | وضعیت |
| --- | --- | --- |
| ۰ | Setup — ساختار ریپو + پروژه‌ی Godot که بالا می‌آید | ✅ انجام شد |
| ۱ | Core Systems — اتوبوس رویداد، وضعیت بازی، مدیر صحنه، ذخیره‌سازی، ماشین حالت، دیتای Resource | ✅ انجام شد |
| ۲ | Player — کاراکتر سه‌بعدی با حالت‌های Idle/Walk/Run، آمار بقا، دوربین موس، چراغ‌قوه (F) | ✅ انجام شد |
| ۳ | **Survival Loop** — تعامل (E)، برداشتن/مصرف آب و غذا، تخلیه‌ی hunger/thirst، مرگ، HUD، **Save واقعی** | ✅ انجام شد (۰.۵.۰) |
| ۴ | **World Identity** — بلوک شهری، تکسچرها، اتمسفر گرگ‌ومیش، چراغ‌قوه | ✅ انجام شد (۰.۴.۰) |
| ۵ | **Threat/Enemy AI** — NavigationRegion + دشمن نمونه (Patrol/Chase/Attack)، Area3D-based، DamageComponent | ✅ انجام شد + تأیید CI (۰.۶.۰؛ فیکس مانع‌های ناوبری: ۰.۶.۲؛ تست دستی کاربر: در انتظار) |
| ۶ | Inventory/Crafting عمیق — داده، منطق، اتصال، UI | ✅ انجام شد + تأیید CI (۰.۷.۰؛ تست دستی: در انتظار) |
| ۷ | **Threat Variety** — Shambler / Stalker / Brute | ✅ پیاده شد (۰.۸.۰؛ تست دستی: در انتظار) |
| ۸ | **Noise-Based Awareness** — شنیدن event-driven | ✅ پیاده شد (۰.۹.۰؛ تست دستی: در انتظار) |
| ۹ | **World Expansion** — حیاط صنعتی شرقی | ✅ پیاده شد (۰.۱۰.۰؛ تست دستی: در انتظار) |
| ۱۰ | **Game Feel & Shareable Build** — صدا، منو، export | ✅ پیاده شد (۰.۱۱.۰؛ تست دستی: در انتظار) |
| ۱۱ | **Stealth Crouch** — خزیدن کم‌صدا | ✅ پیاده شد (۰.۱۲.۰؛ تست دستی: در انتظار) |
| ۱۲ | **Flashlight Battery** — تخلیه و شارژ ژنراتور | ✅ پیاده شد (۰.۱۳.۰؛ تست دستی: در انتظار) |
| ۱۳ | **Consume** — مصرف از اینونتوری | ✅ پیاده شد (۰.۱۴.۰؛ تست دستی: در انتظار) |
| ۱۴ | **Melee** — ضربه‌ی نزدیک + جان دشمن | ✅ پیاده شد (۰.۱۵.۰؛ تست دستی: در انتظار) |
| ۱۵ | **Enemy Loot** — قراضه روی مرگ | ✅ پیاده شد (۰.۱۶.۰؛ تست دستی: در انتظار) |
| ۱۶ | **Jump** — پرش روی StateMachine | ✅ پیاده شد (۰.۱۷.۰؛ تست دستی: در انتظار) |
| ۱۷ | **Death** — DeadState + Game Over | ✅ پیاده شد (۰.۱۸.۰؛ تست دستی: در انتظار) |
| ۱۸ | **Line of Sight** — تعقیب فقط با پرتو آزاد | ✅ پیاده شد (۰.۱۹.۰؛ تست دستی: در انتظار) |
| ۱۹ | **Interiors / Door** — فروشگاه قابل‌ورود | ✅ پیاده شد (۰.۲۰.۰؛ تست دستی: در انتظار) |
| ۲۰ | **یک کیف** — E برداشت، مصرف از Tab | ✅ پیاده شد (۰.۲۱.۰؛ تست دستی: در انتظار) |
| ۲۱ | **چرخه شب** — WorldClock + تاریکی | ✅ پیاده شد (۰.۲۲.۰؛ تست دستی: در انتظار) |
| ۲۲ | **برد شب** — تا سپیده زنده بمان | ✅ پیاده شد (۰.۲۳.۰؛ تست دستی: در انتظار) |
| ۲۳ | **پناه** — RestSpot داخل فروشگاه | ✅ پیاده شد (۰.۲۴.۰؛ تست دستی: در انتظار) |
| ۲۴ | **حافظه دشمن** — Investigate بعد از گم‌کردن دید | ✅ پیاده شد (۰.۲۵.۰؛ تست دستی: در انتظار) |
| ۲۵ | **سقوط** — آسیب فرود سخت | ✅ پیاده شد (۰.۲۶.۰؛ تست دستی: در انتظار) |

**اولویت بعدی:** تست دستی ۷–۲۵ در Godot؛ سپس فاز ۲۶ (میز ساخت). بدون merge تا «من شخصاً در Godot تست کردم».

---

## Definition of Done — فاز ۳ (Survival Loop)

- [x] تعامل با کلید E (پرتو نگاه + پرامپت)
- [x] برداشتن/مصرف آب و غذا (بازیابی تشنگی/گرسنگی)
- [x] تخلیه‌ی تدریجی hunger/thirst + آسیب هنگام اتمام
- [x] مرگ (صفر شدن جان → صفحه‌ی Game Over)
- [x] HUD بقا (نوارها، کراس‌هیر، پرامپت [E]، اعلان آیتم)
- [x] بازیابی استامینا در حالت Walk/Idle (۱۰/۱۶ واحد بر ثانیه)
- [x] بازگیری موس با کلیک (۰.۴.۱)
- [x] **Save واقعی/Load** (۰.۵.۰): `core/save/save_controller.gd` — سیو دستی `F5`، لود دستی `F8`،
      لود خودکار هنگام شروع (در نبود سیو → شروع پیش‌فرض بدون کرش)، auto-save هر ۶۰ ثانیه با Timer،
      toast «ذخیره شد» از طریق `EventBus.toast_requested`. فقط یک slot (`user://saves/save_slot_1.tres`).
- [x] تست کارکردی headless: `tests/save_load_test.gd` (۷ گروه بررسی؛ اجرا: `godot --headless --path . -s res://tests/save_load_test.gd`)
- [x] گزارش تست کاربر روی صحنه‌ی جدید (بصری/کالیژن) — تأیید شد ۲۰۲۶-۰۹-۱۱
- [ ] تأیید نهایی کاربر: بازی را ببند، دوباره باز کن، ادامه از نقطه‌ی رهاشده

---

## Definition of Done — فاز ۵ (Threat System)

- [x] `NavigationRegion3D` روی `test_level.tscn` با navmeshِ **کاروشده** + ۶ `NavigationObstacle3D` برای ساختمان‌ها
      (محوطه با `vertices`؛ پراپرتی `shape` در Godot 4.7.2 وجود ندارد. به‌همراه `affect_navigation_mesh` + `carve_navigation_mesh`)
      — چون این دو فلگ فقط در «bake» اثر دارند و navmesh این پروژه دستی نوشته شده و bake نمی‌شود، نتیجه‌ی همان carve
      داخل `polygons` نوشته شده (۱۳۴ رأس، ۱۷۲ مثلث) تا مسیرها واقعاً دور ساختمان‌ها بچرخند؛
      تست این را با مسیر واقعی موتور اثبات می‌کند: ۳۷.۴ متر دور ساختمان در برابر ۲۶ متر خط مستقیم.
- [x] `entities/enemy/enemy.gd`: `CharacterBody3D` + `NavigationAgent3D` با **همان الگوی** `core/state_machine/`
- [x] سه حالت: `PatrolState` (۴ نقطه‌ی گشت از پیش‌تعیین‌شده)، `ChaseState`، `AttackState`
- [x] تشخیص بازیکن فقط با `body_entered/body_exited` دو `Area3D` (شعاع دید ۷m، محدوده‌ی حمله ۱٫۴m) — بدون فاصله‌ی خام در `_process`
- [x] `DamageComponent` قابل‌استفاده‌ی مجدد (`core/damage/`) متصل به `PlayerStats.take_damage` (آسیب ۸، کول‌داون ۱.۲s)
- [x] یک دشمن نمونه در `test_level.tscn`، در بازوی شمالی تقاطع (قابل‌تست از نقطه‌ی شروع بازیکن)
- [x] `gdparse 4.5.0` روی همه‌ی فایل‌های جدید + وریفای ساختاری صحنه‌ها
- [x] اجرای واقعی در Godot 4.7 — **تأییدشده: CI روی Godot 4.7.2 (تست دستی کاربر هنوز انجام نشده):** اجرای واقعی headless در CI (GitHub Actions)؛ هر ۶۶ چک پاس می‌شوند و گاردِ ثابتِ CI هر خط `SCRIPT ERROR`/`ERROR:`/`WARNING:` را — حتی با exit code صفر — شکست می‌دهد.

## Definition of Done — فاز ۶ (Inventory/Crafting)

- [x] داده/Resource: `ItemData`، `RecipeData`، `ItemCatalog` (`resources/items/`)
- [x] منطق Inventory: `Inventory` (add/remove/stack با سقف max_stack از کاتالوگ) + `InventoryManager` (پل به EventBus)
- [x] داده‌ی واقعی `.tres`: ۴ آیتم (قراضه/کنسرو/آب/مدکیت) + ۲ دستور (فیلتر آب، مدکیت) + `item_catalog.tres`
- [x] منطق Crafting: `CraftingSystem` با `can_craft`/`craft` اتمیک + سیگنال‌های `item_crafted`/`craft_failed`
- [x] اتصال: autoloadهای InventoryManager/CraftingSystem؛ برداشتن قراضه → اینونتوری؛ سیو/لود واقعی اینونتوری
- [x] UI: پنل اینونتوری/ساخت (کلید Tab) — فهرست آیتم‌ها + دکمه‌های ساخت با حالت فعال/غیرفعال
- [x] تست headless برای هر لایه (۶ فایل `tests/*_test.gd`) + محافظ «خطای خاموش API»
- [x] تأیید CI روی Godot 4.7.2 (import + gdparse 4.5.0 + تست‌ها، بدون ERROR/WARNING)
- [ ] تأیید نهایی کاربر: بازکردن پنل با Tab، برداشتن قراضه، ساخت فیلتر آب/مدکیت، سیو/لود اینونتوری

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
├── assets/
│   └── textures/                   ← تکسچرهای tileable محیط
│       ├── ground_asphalt.jpg      ← آسفالت ترک‌خورده (زمین/خیابان)
│       ├── concrete_wall.jpg       ← بتن کهنه (ساختمان/دیوار/سنگ)
│       ├── rusted_metal.jpg        ← فلز زنگ‌زده (ژنراتور/بشکه/خودرو)
│       └── wood_planks.jpg         ← تخته‌چوب (جعبه/ستون برق/پله)
│
├── autoloads/                      ← سینگلتون‌های سراسری (به‌ترتیب لود: EventBus اول)
│   ├── event_bus.gd                ← اتوبوس سیگنال
│   ├── game_state.gd               ← وضعیت سراسری بازی (pause، رفرنس بازیکن، مرحله‌ی فعلی)
│   ├── scene_manager.gd            ← تعویض متمرکز و امن صحنه
│   ├── save_manager.gd             ← ذخیره/بارگذاری Resource باینری در user://saves/
│   └── audio_manager.gd            ← پخش صدای event-driven (فاز ۱۰)
├── core/
│   ├── damage/
│   │   └── damage_component.gd     ← کامپوننت آسیب قابل‌استفاده‌ی مجدد (→ PlayerStats.take_damage)
│   ├── interaction/                ← کلاس‌های پایه‌ی تعامل
│   │   └── interactable.gd         ← کلاس پایه‌ی StaticBody3D قابل تعامل
│   ├── save/
│   │   └── save_controller.gd      ← وصل‌کردن SaveManager به گیم‌پلی (F5/F8، auto-save ۶۰s، auto-load)
│   ├── state_machine/              ← ماشین حالت Node-based
│   │   ├── state.gd                ← کلاس پایه‌ی انتزاعی هر حالت
│   │   └── state_machine.gd        ← ثبت فرزندها + جابه‌جایی با transition_to()
│   ├── inventory/
│   │   └── inventory_manager.gd    ← autoload اینونتوری (پل به EventBus؛ افزودن/حذف/stack)
│   ├── crafting/
│   │   └── crafting_system.gd      ← autoload ساخت اتمیک (can_craft/craft + سیگنال‌ها)
│   └── loot/
│       └── loot_spawner.gd         ← دراپ قراضه روی EventBus.enemy_died
├── entities/
│   ├── enemy/
│   │   ├── enemy.tscn              ← Shambler پایه (NavigationAgent3D + ۲ Area3D + Damage)
│   │   ├── enemy_stalker.tscn      ← واریانت سریع/ضعیف/تیزبین (فاز ۷)
│   │   ├── enemy_brute.tscn        ← واریانت کند/کوبنده (فاز ۷)
│   │   ├── enemy.gd                ← CharacterBody3D دشمن + تشخیص Area3D + شنیدن نویز
│   │   └── states/                 ← حالت‌های دشمن (همان الگوی StateMachine بازیکن)
│   │       ├── patrol_state.gd     ← گشت بین نقاط از پیش‌تعیین‌شده
│   │       ├── chase_state.gd      ← تعقیب (ورود بازیکن به شعاع دید)
│   │       ├── attack_state.gd     ← حمله (ورود بازیکن به محدوده‌ی حمله)
│   │       └── investigate_state.gd ← بررسی محل نویز (فاز ۸)
│   ├── player/
│   │   ├── player.tscn             ← صحنه‌ی بازیکن + پرتو تعامل RayCast3D
│   │   ├── player.gd               ← کنترلر CharacterBody3D + تعامل + مصرف بقا + باتری/ضربه
│   │   └── states/                 ← حالت‌های بازیکن (Idle, Walk, Run, Crouch, Melee)
│   │       ├── idle_state.gd
│   │       ├── walk_state.gd
│   │       ├── run_state.gd
│   │       ├── crouch_state.gd
│   │       ├── melee_state.gd
│   │       ├── jump_state.gd
│   │       └── dead_state.gd
│   └── interactables/              ← اشیاء محیطی قابل تعامل
│       ├── item_pickup.gd          ← اسکریپت برداشتن و مصرف آیتم
│       ├── power_switch.gd         ← اسکریپت سوئیچ ژنراتور و روشنایی
│       ├── water_bottle.tscn       ← بطری آب (بازیابی تشنگی)
│       ├── canned_food.tscn        ← قوطی کنسرو (بازیابی گرسنگی)
│       ├── medkit.tscn             ← جعبه کمک‌های اولیه (بازیابی جان)
│       ├── scrap_metal.tscn        ← قطعه آهن‌قراضه (متریال ساخت)
│       ├── power_switch.tscn       ← کلید ژنراتور برق
│       └── door.gd                 ← در باز/بسته (فاز ۱۹)
│   └── world/
│       └── safe_shop.tscn          ← فروشگاه داخلی با در و لوت
├── resources/
│   ├── save_data.gd                ← کانتینر داده‌ی خالص برای سیو (بدون منطق)
│   ├── stats/
│   │   └── player_stats.gd         ← آمار بازیکن (health/stamina/hunger/thirst) + منطق ایمن تغییر
│   ├── items/                      ← ItemData/RecipeData/ItemCatalog + .tres آیتم‌ها
│   ├── inventory/
│   │   └── inventory.gd            ← Resource منطق add/remove/stack (سقف max_stack)
│   ├── recipes/                    ← دستورهای ساخت واقعی (.tres)
│   └── item_catalog.tres           ← کاتالوگ مرجع آیتم‌ها/دستورها
├── levels/
│   └── test_level.tscn             ← بلوک شهری + حیاط صنعتی شرقی، navmesh کاروشده،
│                                     چهار دشمن، اشیاء بقا و HUD
├── ui/
│   ├── hud/                        ← رابط کاربری درون بازی (HUD)
│   │   ├── hud.gd                  ← کنترل نوارها، اعلان تعامل، toast، Game Over، توقف ESC
│   │   └── hud.tscn                ← نوار جان/استامینا/غذا/آب، کراس‌هیر و پرامپت [E]
│   ├── inventory/                  ← پنل اینونتوری/ساخت (کلید Tab)
│   │   ├── inventory_ui.gd         ← ساخت رابط در کد (فهرست + دکمه‌های ساخت)
│   │   └── inventory_ui.tscn       ← صحنه‌ی حداقلی (CanvasLayer + اسکریپت)
│   └── menus/
│       ├── main_menu.gd            ← منوی اصلی (شروع / خروج)
│       └── main_menu.tscn          ← صحنه‌ی ورودی پروژه (فاز ۱۰)
├── tools/
│   ├── regen_navmesh.py            ← مولد navmesh دستی هم‌لبه (فاز ۹)
│   └── generate_sfx.py             ← مولد WAV پروسیجرال (فاز ۱۰)
├── assets/audio/                   ← ۷ افکت WAV پروسیجرال
└── tests/
    ├── save_load_test.gd           ← تست کارکردی headless برای save/load
    ├── inventory_data_test.gd      ← داده/Resource (ItemData/RecipeData/ItemCatalog)
    ├── inventory_logic_test.gd     ← منطق Inventory (add/remove/stack + EventBus)
    ├── item_catalog_test.gd        ← داده‌ی واقعی .tres + اتصال دستورها
    ├── crafting_test.gd            ← منطق Crafting اتمیک (موفق/کمبود/پر بودن)
    ├── inventory_wiring_test.gd    ← اتصال autoload/pickup/save-load انتها‌به‌انتها
    ├── inventory_ui_test.gd        ← UI پنل اینونتوری/ساخت
    ├── threat_variety_test.gd      ← سه واریانت دشمن (فاز ۷)
    ├── noise_awareness_test.gd     ← نویز event-driven (فاز ۸)
    ├── world_expansion_test.gd     ← حیاط صنعتی + navmesh (فاز ۹)
    ├── game_feel_test.gd           ← منو / صدا / توقف / export (فاز ۱۰)
    ├── stealth_crouch_test.gd      ← خزیدن (فاز ۱۱)
    ├── flashlight_battery_test.gd  ← باتری چراغ‌قوه (فاز ۱۲)
    ├── consume_item_test.gd        ← مصرف از اینونتوری (فاز ۱۳)
    ├── melee_combat_test.gd        ← ضربه نزدیک (فاز ۱۴)
    ├── enemy_loot_test.gd          ← لوت دشمن (فاز ۱۵)
    ├── jump_state_test.gd          ← پرش (فاز ۱۶)
    ├── player_death_test.gd        ← مرگ بازیکن (فاز ۱۷)
    ├── line_of_sight_test.gd       ← خط دید دشمن (فاز ۱۸)
    ├── interiors_test.gd           ← در و فضای داخلی (فاز ۱۹)
    ├── day_cycle_test.gd           ← چرخه شب (فاز ۲۱)
    └── night_survive_test.gd       ← برد شب (فاز ۲۲)
```

## قراردادها

- **نام فایل‌ها:** `snake_case.gd` و `snake_case.tscn`
- **نام کلاس‌ها / نودها:** `PascalCase`
- **ارتباط بین سیستم‌ها:** فقط از طریق `autoloads/event_bus.gd`. هیچ `get_node()` عمیقی بین ماژول‌ها.
- **معماری:** دیتا در `Resource`، رفتار در State Machine مبتنی بر Node، ارتباط در `EventBus`.
- **GDScript:** همیشه typed (نوع همه‌ی متغیرها، آرگومان‌ها و خروجی‌ها مشخص).
- **زبان کامنت‌ها:** فارسی.
- **هر فاز = یک ورودی در `CHANGELOG.md`.**

---

## راه‌اندازی و تست

1. Godot 4.7 را باز کن و پروژه را Import کن.
2. کلید `F5` را بزن — منوی اصلی می‌آید؛ «شروع» سطح تست را لود می‌کند.
3. با WASD حرکت کن، با Shift بدو، با `C` بخز (نویز کمتر). استامینا در توقف/راه‌رفتن/خزیدن بازیابی می‌شود.
4. کلید `F` چراغ‌قوه را روشن/خاموش می‌کند؛ باتری خالی می‌شود و با روشن‌کردن ژنراتور شارژ می‌شود.
5. `ESC` منوی توقف را باز/بسته می‌کند (ادامه / منوی اصلی).
6. به سمت اشیاء (بطری آب، کنسرو، جعبه کمک‌ها، سوئیچ برق) نگاه کن تا نشانگر `[E]` ظاهر شود.
7. کلید `E` را بزن تا آیتم را **برداری** (مصرف از Tab) یا ژنراتور را روشن/خاموش کنی.
8. نوارهای وضعیت سلامت، استامینا، گرسنگی، تشنگی و باتری را در پایین سمت چپ به صورت زنده مشاهده کن.
9. از تقاطع به سمت ساختمان‌ها برو؛ پنجره‌های روشن و چراغ‌های اضطراری در گرگ‌ومیش می‌درخشند.
10. `F5` بازی را ذخیره می‌کند (toast «ذخیره شد» + auto-save هر ۶۰ ثانیه). بازی را ببند و دوباره باز کن —
    از نقطه‌ی رهاشده (موقعیت/زاویه/آمار) ادامه می‌یابد. `F8` آخرین سیو را بارگذاری می‌کند.
11. تست خودکار save/load: `godot --headless --path . -s res://tests/save_load_test.gd`
12. سه نوع دشمن: Shambler در تقاطع (آسیب ۸)، Stalker سریع در جنوب‌شرق، Brute کوبنده در جنوب‌غرب.
    دویدن نویز ۱۴ متری می‌سازد و دشمنِ دور را خبر می‌کند؛ راه‌رفتن آرام‌تر است (۶ متر).
13. شرق نقشه حیاط صنعتی است (انبار، کانتینر، سوله) با آیتم و Enemy4.
14. صداهای قدم/ساخت/برداشت/ضربه از طریق EventBus پخش می‌شوند؛ دویدن FOV را کمی باز می‌کند.
15. Tab اینونتوری: «مصرف» برای آب/غذا/دارو. کلیک چپ یا `V` ضربه‌ی نزدیک (استامینا ۱۲، نویز ۸ متر). دشمن مرده قراضه می‌اندازد.
16. Space پرش (از خزیدن نه). اگر جانت صفر شود DeadState قفل می‌کند و Game Over می‌آید؛ «تلاش مجدد» سطح را از SceneManager لود می‌کند.
