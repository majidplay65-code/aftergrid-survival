# تغییرات

قالب این فایل از [Keep a Changelog](https://keepachangelog.com/fa-IR/1.1.0/) و
شماره‌گذاری از [Semantic Versioning](https://semver.org/lang/fa/) پیروی می‌کند.

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
