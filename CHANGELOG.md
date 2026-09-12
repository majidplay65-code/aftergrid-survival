# تغییرات

قالب این فایل از [Keep a Changelog](https://keepachangelog.com/fa-IR/1.1.0/) و
شماره‌گذاری از [Semantic Versioning](https://semver.org/lang/fa/) پیروی می‌کند.

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
