# تغییرات

قالب این فایل از [Keep a Changelog](https://keepachangelog.com/fa-IR/1.1.0/) و
شماره‌گذاری از [Semantic Versioning](https://semver.org/lang/fa/) پیروی می‌کند.

## [0.24.0] - 2026-09-12

فاز ۲۳ (پناه): RestSpot داخل فروشگاه.

### Added

- `RestSpot` Interactable؛ `EventBus.rest_requested` زمان را جلو می‌برد و سیو می‌کند. نویز صفر.
- تست headless `tests/rest_spot_test.gd` (۸ چک).

## [0.23.0] - 2026-09-12

فاز ۲۲ (برد شب): زنده ماندن تا سپیده.

### Added

- `EventBus.night_survived` هنگام عبور از سپیده.
- HUD: برچسب شب و پنل «زنده ماندی».
- `SaveData.night_index` پیش‌فرض ۱.
- تست headless `tests/night_survive_test.gd` (۹ چک).

## [0.22.0] - 2026-09-12

فاز ۲۱ (چرخه شب): زمان Resource و تاریکی محیط.

### Added

- `WorldClock` Resource و `DayCycle` روی سطح تست.
- `EventBus.time_of_day_changed(normalized)`.
- نیمه‌شب `ambient_light_energy` زیر ۰.۲؛ باتری چراغ‌قوه اجباری می‌شود.
- تست headless `tests/day_cycle_test.gd` (۱۲ چک).

## [0.21.0] - 2026-09-12

فاز ۲۰ (یک کیف): برداشت از دنیا به اینونتوری می‌رود.

### Changed

- آب/غذا/دارو: `is_consumable_on_pickup = false`؛ مصرف فقط از Tab.
- سقف مجموع کیف ۱۲ واحد؛ اگر جا نبود شیء سر جایش می‌ماند.
- `inventory_wiring_test`: آب به کیف می‌رود و تشنگی عوض نمی‌شود (۲۱ چک).

## [0.20.0] - 2026-09-12

فاز ۱۹ (در و فضای داخلی): فروشگاه قابل‌ورود با در Interactable.

### Added

- `Door` از `Interactable` (E باز/بسته، نویز ۴ متر، لغزش روی لولا).
- `entities/world/safe_shop.tscn`: سه دیوار + دهانه شرقی، آب و کنسرو داخل، نور ضعیف.
- `ObstacleShop` + navmesh کاروشده ۳۹۴ رأس / ۵۸۲ مثلث (`tools/regen_navmesh.py`).
- تست headless `tests/interiors_test.gd` (۱۷ چک).

### Changed

- `save_load_test` ۱۰۳ چک؛ `world_expansion_test` شمار رأس/مثلث به‌روز.

## [0.19.0] - 2026-09-12

فاز ۱۸ (Line of Sight): تعقیب فقط با پرتو فیزیک آزاد.

### Added

- `has_line_of_sight_to` با `PhysicsRayQueryParameters3D` از چشم دشمن تا سینهٔ بازیکن.
- Area3D فقط کرهٔ دید است؛ Chase وقتی دیوار وسط باشد شروع نمی‌شود.
- Patrol/Investigate وقتی بازیکن از گوشه بیرون می‌آید دوباره امتحان می‌کنند.
- تست headless `tests/line_of_sight_test.gd` (۱۲ چک).

### Fixed

- `ChaseState` از identifier ناموجود `SPEED` به `speed` اصلاح شد (تعقیب در runtime می‌شکست).

## [0.18.0] - 2026-09-12

فاز ۱۷ (Death): مرگ واقعی روی StateMachine.

### Added

- `DeadState`؛ قفل پرش/ضربه/تعامل؛ بدون سیو بعد از مرگ.
- Game Over → `SceneManager.reload_current_scene`.
- تست headless `tests/player_death_test.gd` (۱۲ چک).

## [0.17.0] - 2026-09-12

فاز ۱۶ (Jump): پرش روی StateMachine.

### Added

- `JumpState`، نویز پرش ۷ متر / فرود ۹ متر؛ خزیدن پرش ندارد.
- تست headless `tests/jump_state_test.gd` (۱۱ چک).

## [0.16.0] - 2026-09-12

فاز ۱۵ (Enemy Loot): قراضه روی مرگ دشمن.

### Added

- `LootSpawner` گوش به `EventBus.enemy_died`؛ دراپ `scrap_metal` در محل مرگ.
- تست headless `tests/enemy_loot_test.gd` (۸ چک).

## [0.15.0] - 2026-09-12

فاز ۱۴ (Melee): ضربه‌ی نزدیک بدون سلاح گرم.

### Added

- `MeleeState`، اکشن `melee` (کلیک چپ / V)، استامینا ۱۲، نویز ۸ متر، آسیب ۱۵.
- جان دشمن: Shambler ۴۰، Stalker ۲۵، Brute ۷۰؛ مرگ → `enemy_died`.
- تست headless `tests/melee_combat_test.gd` (۱۳ چک).

## [0.14.0] - 2026-09-12

فاز ۱۳ (Consume): مصرف آب/غذا/دارو از اینونتوری.

### Added

- `ItemData.stat_restore_amount` (آب ۳۰ / غذا ۳۵ / مدکیت ۴۰).
- `InventoryManager.use_item` + `EventBus.item_consumed`.
- دکمه «مصرف» فقط برای آیتم‌های مصرفی؛ قراضه Label تنها می‌ماند.
- تست headless `tests/consume_item_test.gd` (۱۲ چک).

## [0.13.0] - 2026-09-12

فاز ۱۲ (Flashlight Battery): تخلیه و شارژ ژنراتور.

### Added

- تخلیه ۸ واحد/ثانیه؛ شارژ از `EventBus.generator_charge_requested` هنگام روشن‌کردن کلید ژنراتور.
- نوار باتری HUD؛ سیو `flashlight_battery` با پیش‌فرض ۱۰۰ برای فایل‌های قدیمی.
- تست headless `tests/flashlight_battery_test.gd` (۱۲ چک).

## [0.12.0] - 2026-09-12

فاز ۱۱ (Stealth Crouch): خزیدن کم‌صدا.

### Added

- `CrouchState`، اکشن `crouch` (C)، سرعت ۱.۶، نویز ۲.۵ متر، دوربین/کپسول نرم.
- تست headless `tests/stealth_crouch_test.gd` (۱۲ چک).

## [0.11.0] - 2026-09-12

فاز ۱۰ (Game Feel & Shareable Build): صدا، منو، توقف، FOV، export.

### Added

- **صدا:** ۷ افکت WAV پروسیجرال (`assets/audio/`) + autoload `AudioManager` که فقط از EventBus تغذیه می‌شود (در headless پخش نمی‌شود تا CI WARNING ندهد).
- **منوی اصلی** `ui/menus/main_menu.tscn` — همان مسیری که `SceneManager` از قبل می‌شناخت؛ حالا `main_scene` است.
- **منوی توقف با ESC** در HUD (`process_mode = ALWAYS`).
- **FOV نرم هنگام دویدن** (۷۵→۸۵).
- **`export_presets.cfg`:** Linux و Windows Desktop.
- تست headless `tests/game_feel_test.gd` (۱۹ چک).

## [0.10.0] - 2026-09-12

فاز ۹ (World Expansion): حیاط صنعتی شرقی.

### Added

- دو انبار، سه کانتینر، یک سوله + ۶ `NavigationObstacle3D` + ۴ آیتم + Enemy4.
- مولد `tools/regen_navmesh.py` با وفاداری اثبات‌شده نسبت به navmesh قبلی (۱۳۴ رأس / ۱۷۲ مثلث) و خروجی جدید ۳۴۱/۴۹۴.
- تست headless `tests/world_expansion_test.gd` (۲۲ چک).

### Changed

- `tests/save_load_test.gd`: شمار رأس/مثلث و فهرست مانع‌ها به‌روز شد (۹۸ چک).

## [0.9.0] - 2026-09-12

فاز ۸ (Noise-Based Awareness): شنیدن event-driven.

### Added

- سیگنال `EventBus.noise_emitted(noise_position, loudness)` — نام پارامتر عمداً `position` نیست.
- نویز از راه‌رفتن (۶m)، دویدن (۱۴m) و ساخت آیتم (۱۰m)؛ بدون فرض شلیک.
- `InvestigateState`؛ چک فاصله فقط در هندلر سیگنال.
- ضریب شنوایی: Stalker ×۱٫۵، Brute ×۰٫۶، Shambler ×۱٫۰.
- تست headless `tests/noise_awareness_test.gd` (۱۴ چک).

## [0.8.0] - 2026-09-12

فاز ۷ (Threat Variety): سه واریانت دشمن data-driven.

### Added

- سرعت گشت/تعقیب `@export` شد.
- `enemy_stalker.tscn` (سریع/ضعیف/تیزبین) و `enemy_brute.tscn` (کند/کوبنده).
- Enemy2 و Enemy3 در سطح تست.
- تست headless `tests/threat_variety_test.gd` (۲۲ چک).

## [0.7.0] - 2026-09-12

فاز ۶ (Inventory/Crafting عمیق): داده → منطق → اتصال → UI، در شش لایه‌ی منطقی.

### Added

- **داده (`resources/items/`):** `ItemData`، `RecipeData` و `ItemCatalog` — مدل داده‌ی آیتم و دستور ساخت.
- **منطق Inventory (`resources/inventory/` + `core/inventory/`):** `Inventory` (add/remove/stack با سقف max_stack از کاتالوگ) و `InventoryManager` (پل به EventBus؛ autoload).
- **داده‌ی واقعی (`.tres`):** ۴ آیتم (قراضه/کنسرو/آب/مدکیت) + ۲ دستور (فیلتر آب: ۲ قراضه→آب؛ مدکیت: ۱ کنسرو+۱ قراضه→مدکیت) + `resources/item_catalog.tres`.
- **منطق Crafting (`core/crafting/`):** `CraftingSystem` (autoload) با `can_craft`/`craft` اتمیک (اول check کامل، بعد commit) + سیگنال‌های `item_crafted`/`craft_failed`.
- **اتصال:** برداشتن آیتم غیرمصرفی (قراضه) → اینونتوری؛ مصرفی (آب/غذا/دارو) → اثر آماری + toast؛ سیو/لود واقعی اینونتوری (`SaveData.inventory_items`).
- **UI (`ui/inventory/`):** پنل اینونتوری/ساخت با کلید Tab — فهرست آیتم‌ها (نام واقعی از کاتالوگ) + دکمه‌های ساخت با حالت فعال/غیرفعال + toast موفقیت/شکست.
- **تست headless:** ۶ فایل `tests/*_test.gd` (داده، منطق، کاتالوگ، ساخت، اتصال، UI) — هر کدام با محافظ «خطای خاموش API».

### Fixed

- سیگنال `Inventory` از `changed` به `contents_changed` (تداخل با سیگنال داخلی `Resource`).
- حذف `class_name` از InventoryManager/CraftingSystem (تداخل «Class hides an autoload singleton» با autoload همنام).

### Known / در انتظار

- تأیید CI روی Godot 4.7.2 (import + gdparse 4.5.0 + هر ۶ تست) انجام شد؛ تست دستی کاربر هنوز انجام نشده.
- خارج از محدوده: نوار پیشرفت زمان ساخت، دور انداختن آیتم، پیشرفت بازشدن دستورها.

## [0.6.2] - 2026-09-12

فیکس فاز ۵: `NavigationObstacle3D`ها هیچ کاری نمی‌کردند و مسیر دشمن از وسط ساختمان‌ها می‌گذشت.

### Fixed

- **`levels/test_level.tscn` (۶ مانع ناوبری):** پراپرتی `shape` — که در Godot 4.7.2 اصلاً وجود ندارد — (و `sync_to_physics`
  که در ۴.x حذف شده) با `vertices` (محوطه‌ی مستطیلی) + `height` + `affect_navigation_mesh` + `carve_navigation_mesh`
  جایگزین شد. مبدأ مانع‌ها هم به تراز زمین (`y = 0`) آمد، چون carve از `global_position.y` تا `+height` را می‌بُرد.
- **`levels/test_level.tscn` (navmesh):** دو فلگ carve فقط در «bake» مصرف می‌شوند (`nav_mesh_generator_3d.cpp`، مسیر
  projected obstructions) و navmesh این پروژه دستی نوشته شده و هیچ‌وقت bake نمی‌شود؛ پس نتیجه‌ی همان bake داخل `polygons`
  نوشته شد: سطح `[-40,40]²` منهای محوطه‌ی ۶ ساختمان، به‌صورت شبکه‌ای هم‌لبه (بدون T-junction — موتور لبه‌ها را فقط وقتی
  وصل می‌کند که «هر دو سرِ لبه» یکی باشند) = ۱۳۴ رأس و ۱۷۲ مثلث. حاشیه‌ی ۰.۵ متری دور ساختمان‌ها همان شعاع دشمن است
  (معادلِ erode شدن در bake).
- **`tests/save_load_test.gd`:** ۴۷ چک جدید — وجود `vertices`/فلگ‌ها روی هر ۶ مانع، کارو شدن مرکز محوطه‌ها، باقی‌ماندن
  نقاط حیاتی روی navmesh، اتصال هر ۴ پای گشت، و اثبات موتوربنیان با `NavigationServer3D.map_get_path`: مسیر دو طرف Bldg1
  باید دور ساختمان بچرخد و هیچ نقطه‌ای داخل محوطه‌ها نباشد (اندازه‌گیری CI: ۳۷.۴ متر در برابر ۲۶ متر خط مستقیم).
  به‌علاوه محافظِ «خطای خاموشِ API»: تعداد چک‌های اجراشده باید برابر ۶۶ باشد وگرنه تست FAIL می‌دهد، چون Godot حتی با
  SCRIPT ERROR هم exit code صفر می‌دهد و CI سبز می‌ماند.
- **`.github/workflows/ci.yml` (مرحله‌ی ۳):** گاردِ ثابتِ خطا — خروجی هر تست روی الگوی `SCRIPT ERROR|ERROR:|WARNING:` بررسی می‌شود و
  حتی اگر خودِ تست exit code صفر بدهد، مرحله fail می‌شود (۳ سناریوی واقعی همین PR با exit code صفر سبز مانده بودند).
- **سایر:** `load_steps` صحنه از ۱۰۱ به ۹۷ و حذف چهار `BoxShape3D` بی‌استفاده؛ README/CHANGELOG از
  «در انتظار اجرای واقعی در Godot» به «تأیید‌شده: CI روی Godot 4.7.2 (تست دستی کاربر هنوز انجام نشده)» به‌روز شد؛ نسخه به ۰.۶.۲ رسید.

## [0.6.1] - 2026-09-11

فیکس فاز ۵: خطای runtime در حالت گشت دشمن — `Vector3` در Godot متد `horizontal_length()` ندارد.

### Fixed

- **`entities/enemy/enemy.gd`:** متد کمکی جدید `horizontal_distance_to(world_point)` که فاصله‌ی افقی
  (صفحه‌ی XZ، بدون مولفه‌ی y) تا یک نقطه‌ی جهانی را برمی‌گرداند — در کنار helperهای قبلی
  (`move_along_agent`، `stop_moving`، `face_toward`).
- **`entities/enemy/states/patrol_state.gd`:** هر دو فراخوانی نامعتبر `.horizontal_length()`
  (انتخاب نزدیک‌ترین نقطه‌ی گشت در `enter` و چک رسیدن به نقطه در `physics_update`)
  با `enemy.horizontal_distance_to(...)` جایگزین شدند.

## [0.6.0] - 2026-09-11

فاز ۵ (Threat System): سیستم تهدید نمونه با الگوی موجود StateMachine.

### Added

- **`NavigationRegion3D` + موانع ناوبری در `levels/test_level.tscn`:**
  پلیگون مسطح کل فضای عبور + ۶ `NavigationObstacle3D` (پایه‌ی ساختمان‌ها) تا مسیرها دور ساختمان‌ها بروند.
- **دشمن نمونه (`entities/enemy/`):**
  - `enemy.tscn`/`enemy.gd`: `CharacterBody3D` + `NavigationAgent3D`، دقیقاً با الگوی `core/state_machine/`.
  - `states/patrol_state.gd`: گشت بین ۴ نقطه‌ی از پیش‌تعیین‌شده روی صحنه.
  - `states/chase_state.gd`: تعقیب موقعیت لحظه‌ای بازیکن روی مسیر ناوبری.
  - `states/attack_state.gd`: توقف، روکردن به بازیکن، ضربه با کول‌داون.
  - تشخیص بازیکن **فقط** با `body_entered/body_exited` دو `Area3D` (شعاع دید ۷m / محدوده‌ی حمله ۱.۴m).
- **`core/damage/damage_component.gd`:** کامپوننت آسیب قابل‌استفاده‌ی مجدد (آسیب ۸، کول‌داون ۱.۲s)
  که `PlayerStats.take_damage` را صدا می‌زند — برای هر هدفی که `stats` از نوع PlayerStats داشته باشد.
- یک دشمن نمونه در بازوی شمالی تقاطع (مسیر: `res://entities/enemy/enemy.tscn`).

### Not included (طبق توافق، خارج از محدوده‌ی فاز ۵)

سیستم موج، spawn تصادفی، صداگذاری، انیمیشن پیچیده.

### Known / در انتظار

- **حل شد (۰.۶.۲):** اجرای واقعی headless با Godot 4.7.2 حالا در CI (GitHub Actions) انجام می‌شود و همان‌جا هیچ خطای
  ERROR/WARNING ثبت نمی‌شود (گاردِ ثابت CI هم هر خط `SCRIPT ERROR`/`ERROR:`/`WARNING:` را حتی با exit code صفر fail می‌کند)؛ تست دستی کاربر هنوز انجام نشده. `gdparse 4.5.0` هم روی همه‌ی فایل‌ها PASS است.

## [0.5.0] - 2026-09-11

تکمیل فاز ۳ (Survival Loop): اتصال واقعی SaveManager به گیم‌پلی.

### Added

- **سیستم save/load کامل (`core/save/save_controller.gd`):**
  - سیو دستی با `F5` (اکشن جدید `save_game`): SaveData شامل موقعیت، yaw بازیکن، pitch دوربین،
    همه‌ی آمار PlayerStats (+ maxها) و Dictionary رزرو‌شده‌ی inventory_items.
  - لود دستی با `F8` (اکشن جدید `load_game`).
  - **لود خودکار هنگام شروع:** اگر سیو موجود باشد، بازی از همان‌جا ادامه می‌یابد؛
    در نبود سیو (یا سیو خراب) شروع پیش‌فرض بدون کرش.
  - **auto-save** هر ۶۰ ثانیه با Timer (`autosave_interval` قابل تنظیم در صحنه برای تست).
- **سیستم toast مشترک HUD:** سیگنال جدید `EventBus.toast_requested` + `_show_toast()` در `hud.gd`
  (toast قبلی آیتم‌ها هم به همین تابع بازسازی شد). سیو/لود پیام «ذخیره شد» / «بازی از سیو بارگذاری شد» نشان می‌دهد.
- **تست کارکردی headless (`tests/save_load_test.gd`):** ۷ گروه بررسی (شروع بدون سیو، سیو/لود دستی،
  بازیابی پوزیشن/yaw/pitch/آمار، شبیه‌سازی restart با auto-load، auto-save) —
  اجرا: `godot --headless --path . -s res://tests/save_load_test.gd`.

### Changed

- `SaveData`: فیلد جدید `player_pitch` و `save_version` به ۲ ارتقا (سیوهای v1 همچنان لود می‌شوند).
- `project.godot`: اکشن‌های ورودی جدید `save_game` (F5) و `load_game` (F8).
- README: فاز ۳ ✅ انجام شد؛ فاز بعدی = ۵ (Threat/Enemy AI).

### Known / در انتظار

- اجرای تست headless در سنبوکس Arena ممکن نبود (CDN باینری Godot مسدود است)؛
  تست آماده است و باید یک‌بار در سیستم کاربر (یا هر جایی که Godot 4.7 دارد) اجرا شود.

## [0.4.1] - 2026-09-10

فیکس‌های توافق‌شده‌ی فاز ۳.۰ + اصلاح فازبندی.

### Fixed

- **بازگیری موس با کلیک:** بعد از رها‌شدن نشانگر با ESC، اولین کلیک روی بازی دوباره موس را قفل می‌کند (`entities/player/player.gd`).
- یادآوری: بازیابی استامینا در Walk/Idle از baseline (۰.۳.۰) وجود داشت و در ۰.۴.۱ تأیید شد — تغییر جدیدی نیاز نبود.

### Changed

- اصلاح جدول فازبندی README: فاز ۳ = **Survival Loop** (در حال تکمیل — مانده: Save واقعی)، فاز ۴ = **World Identity** (انجام‌شده در ۰.۴.۰)، فاز ۵ = Threat/Enemy AI، فاز ۶ = Inventory/Crafting عمیق.
- اضافه شدن چک‌لیست **Definition of Done** فاز ۳ به README.

## [0.4.0] - 2026-09-10

بازطراحی بصری کامل سطح تست: از «چند جعبه روی زمین خالی» به یک بلوک شهری پس از فروپاشی شبکه.

### Added

- **محیط شهری (`levels/test_level.tscn`):**
  - شش ساختمان بتنی با ارتفاع‌های متفاوت، پشت‌بام، ایروینیت، آنتن با چراغ هشدار قرمز.
  - پنجره‌های روشن و تیره (emission) در نماها برای حس شهر نیمه‌روشنِ گرگ‌ومیش.
  - خیابان تقاطع‌شده + پیاده‌رو، دیوار فرو ریخته و تخته‌های بتن ریخته.
  - دو ستون برق (یکی با چراغ اضطراری روشن، دیگری خراب با سیم آویزان).
  - خودروی سوخته‌ی زنگ‌زده با در باز، سطل‌زباله با درب نیمه‌باز، بشکه‌ها، تکیه‌گاه آهن‌زنی.
  - آوار و خرابی‌های پراکنده: سنگ، تخته‌چوب، میله‌های نرده.
- **تکسچرهای بازی (`assets/textures/`):** آسفالت ترک‌خورده، بتن کهنه، فلز زنگ‌زده، تخته‌چوب (tileable) روی همه‌ی متریال‌ها (uv tiling + triplanar mapping).
- **اتمسفر گرگ‌ومیش:** آسمان دوشگاهی، خورشید پایینِ گرم + نور پُرکننده‌ی سرد، مه (fog) با aerial perspective، ACES tone mapping، SSAO، bloom و وینیت.
- **بازیکن با جزئیات بیشتر (`entities/player/player.tscn`):** بدنه‌ی تیره، سر با کلاه، کوله‌پشتی، پا و دست — به‌جای کپسول سفید.
- **چراغ‌قوه (کلید F):** SpotLight متصل به دوربین با سایه، روشن/خاموش با کلید `flashlight`.

### Changed

- چیدمان آیتم‌های تعاملی در جای واقعی: جعبه‌های چوبی تدارکات روی خیابان، قفسه‌ی کمک‌های اولیه، قراضه کنار خودروی سوخته.
- ژنراتور اضطراری با بدنه، مخزن سوخت، اگزوز و چراغ هشدار — کلید همان کلید قبلی (target_light).
- `project.godot`: اکشن ورودی جدید `flashlight` (F).

## [0.3.0] - 2026-09-08

تکمیل فاز ۳: دنیای بازی و سیستم تعامل (World & Interaction) + HUD بقا.

### Added

- **سیستم تعامل (Interaction System):**
  - کلاس پایه‌ی `Interactable` در `core/interaction/interactable.gd`.
  - کلاس و اسکریپت `ItemPickup` در `entities/interactables/item_pickup.gd` با قابلیت مصرف درجا یا انتقال به اینونتوری.
  - کلاس و اسکریپت `PowerSwitch` در `entities/interactables/power_switch.gd` برای کنترل چراغ‌ها و تجهیزات محیطی.
- **اشیاء و آیتم‌های تعاملی تستی در `entities/interactables/`:**
  - `water_bottle.tscn`: بطری آب معدنی (+30 تشنگی).
  - `canned_food.tscn`: کنسرو لوبیا (+35 گرسنگی).
  - `medkit.tscn`: جعبه کمک‌های اولیه (+40 سلامت).
  - `scrap_metal.tscn`: قطعه آهن‌قراضه (متریال ساخت).
  - `power_switch.tscn`: کلید فعال‌سازی ژنراتور اضطراری به همراه نشانگر نوری.
- **رابط کاربری و HUD بقا (`ui/hud/hud.tscn`, `ui/hud/hud.gd`):**
  - نشانه‌گیر مرکزی (Crosshair).
  - ویجت پویا با برچسب کلید `[E]` و نام تعامل هنگام نگاه کردن به اشیاء.
  - نوارهای زنده وضعیت بقا (جان ❤️، استامینا ⚡، غذا 🍖، آب 💧) متصل به `EventBus`.
  - اعلان پیام دریافت آیتم (Toast notifications) در گوشه بالای صفحه.
  - صفحه Game Over در صورت افت کامل جان.
- **کنترلر و فیزیک بازیکن:**
  - اضافه شدن پرتو `RayCast3D` به مرکز دوربین برای تشخیص اشیاء روبه‌رو.
  - افت تدریجی تشنگی و گرسنگی در طول زمان (گیم‌پلی بقا).
  - بازیابی خودکار استامینا در حالت‌های `Idle` و `Walk`.
- **محیط تست (`levels/test_level.tscn`):**
  - نورپردازی اتمسفریک گرگ‌ومیش، میزهای تدارکات، آیتم‌های بقا و ژنراتور با نور اسپات‌لایت تعاملی.

## [0.2.0] - 2026-09-08

بازنشانی روی baseline قطعی فازهای ۰ تا ۲ (سه‌بعدی). نسخه‌ی دوبعدی موقت فاز ۰ حذف شد.

### Added

- فاز ۱ (Core Systems): `EventBus`، `GameState`، `SceneManager` و `SaveManager` مبتنی بر Resource
  (`user://saves/save_slot_1.tres`) به‌همراه `SaveData` و `PlayerStats`.
- فاز ۱: ماشین حالت Node-based در `core/state_machine/` (کلاس‌های `State` و `StateMachine`).
- فاز ۲ (Player): کنترلر `CharacterBody3D` در `entities/player/player.gd` با حالت‌های
  `IdleState`، `WalkState` و `RunState` (مصرف استامینا + برگشت خودکار به Walk).
- فاز ۲: صحنه‌ی `entities/player/player.tscn` طبق راهنمای README
  (کپسول موقت، CameraPivot در Y=1.6، اتصال Initial State و Player).
- صحنه‌ی تست `levels/test_level.tscn` (زمین، نور، سه جعبه‌ی نشانه برای فهمیدن حرکت، نمونه‌ی Player) به‌عنوان Main Scene.
- Input Map کامل در `project.godot`: `move_forward`/`move_back`/`move_left`/`move_right`
  (WASD)، `run` (Shift)، `jump` (Space) و `interact` (E).

## [0.1.0] - 2026-09-08

### Added

- نام کاری پروژه: **Aftergrid** (قفل‌نشده) و نام ریپو `aftergrid-survival`.
- ساختار اولیه‌ی پوشه‌ها: `autoloads/`, `core/`, `entities/`, `resources/`, `ui/`, `levels/`.
- پروژه‌ی Godot 4.5 (`project.godot`) با صحنه‌ی ورودی `core/main.tscn`.
