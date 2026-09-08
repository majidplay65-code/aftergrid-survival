# تغییرات

قالب این فایل از [Keep a Changelog](https://keepachangelog.com/fa-IR/1.1.0/) و
شماره‌گذاری از [Semantic Versioning](https://semver.org/lang/fa/) پیروی می‌کند.

قاعده‌ی این ریپو: **هر فازی که تمام شد، یک ورودی اینجا اضافه کن.** یک خط هم کافی است.

فازبندی واقعی پروژه: فاز ۰ = Setup، فاز ۱ = Core Systems، فاز ۲ = Player (هر سه انجام‌شده)،
فاز ۳ = World & Interaction (بعدی).

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

### Changed

- `project.godot`: ارتقا از Godot 4.5 به **Godot 4.7**، نسخه‌ی پروژه به `0.2.0`،
  Main Scene به `res://levels/test_level.tscn` و autoload ها به ترتیب
  `EventBus` → `GameState` → `SceneManager` → `SaveManager`.
- `README.md`: فازبندی واقعی (۰=Setup، ۱=Core Systems، ۲=Player انجام‌شده، ۳=World & Interaction بعدی)،
  ساختار جدید ریپو، قرارداد `EventBus` و راهنمای کامل Setup (autoload، اکشن‌ها، درخت Player.tscn، چک‌لیست صحت).

### Removed

- `autoloads/game_events.gd` (جایگزین: `autoloads/event_bus.gd`).
- نسخه‌ی JSON قدیمی `autoloads/save_manager.gd` (جایگزین: نسخه‌ی Resource-based).
- نسخه‌ی دوبعدی موقت `core/main.gd` و `core/main.tscn`.
- فایل `godot_project_phase0-2.zip` بعد از extract موفق (محتوایش همان baseline بالاست).
- `.gitkeep` های `entities/`، `resources/` و `levels/` (اولین فایل‌های واقعی نشستند).

## [0.1.0] - 2026-09-08

### Added

- نام کاری پروژه: **Aftergrid** (قفل‌نشده) و نام ریپو `aftergrid-survival`.
- ساختار اولیه‌ی پوشه‌ها: `autoloads/`, `core/`, `entities/`, `resources/`, `ui/`, `levels/`.
- پروژه‌ی Godot 4.5 (`project.godot`) با صحنه‌ی ورودی `core/main.tscn`.
- دو autoload پایه: `GameEvents` (اتوبوس سیگنال) و `SaveManager` (ذخیره‌ی JSON در `user://`).
- `README.md` با برنامه‌ی فازها و `CHANGELOG.md`.
- `.gitignore` مخصوص Godot 4.
