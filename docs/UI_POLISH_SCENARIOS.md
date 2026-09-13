# سناریوهای تست دستیِ آیتم‌های UI — DoD #۳

> هدف این سند: برای **هر یک از ۵ آیتم پولیش UI**، یک سناریوی دستی ارائه شود که نشان دهد
> **سیگنال واقعی از EventBus** باعث تغییر UI می‌شود — نه فراخوانی مستقیم متد UI.
> همه اتصال‌ها event-driven هستند؛ هیچ آیتمی polling در `_process` ندارد و
> هیچ وابستگی جدیدی به autoload جز EventBus اضافه نشده است.
>
> هر سناریو دو لایه دارد: (الف) سناریوی دستی داخل بازی با منبع واقعی سیگنال در گیم‌پلی،
> (ب) رد خودکار همان زنجیره در تست‌های headless (`tests/ui_polish_test.gd`).

## نقشه سیگنال ← UI (خلاصه)

| آیتم | سیگنال واقعی | منبع واقعی در گیم‌پلی | فایل UI |
|---|---|---|---|
| نوار پیشرفت ساخت | `item_crafted` / `craft_failed` | `core/crafting/crafting_system.gd:107` و `:140` | `ui/inventory/inventory_ui.gd` |
| تولتیپ آیتم | `inventory_changed` (+ built-in `mouse_entered`/`mouse_exited`) | `core/inventory/inventory_manager.gd:53` | `ui/inventory/inventory_ui.gd` |
| Toast با fade | `toast_requested` (و `item_picked_up`) | `entities/interactables/rest_spot.gd:24`، `core/save/save_controller.gd:51`، `entities/interactables/item_pickup.gd:47` | `ui/hud/hud.gd` |
| جهت‌نمای صدا | `noise_emitted` | `entities/interactables/door.gd:23`، `entities/player/player.gd:144/204/230`، `core/crafting/crafting_system.gd:111` | `ui/hud/noise_indicator.gd` |
| افکت رهاکردن آیتم | `item_dropped` | امروز فقط تست‌ها emit می‌کنند (توضیح در سناریوی ۵) | `ui/hud/hud.gd` |

---

## سناریوی ۱ — نوار پیشرفت ساخت (Craft Progress Bar)

**پیاده‌سازی**: دکمه‌ی دستور ساخت، یک tween سمتِ UI روی مدت‌زمان واقعی `RecipeData.craft_time` می‌سازد
(`inventory_ui.gd:214-238`، `tween_method` + `tween_callback` — بدون `_process`).
در پایان tween، ساخت واقعی به autoload موجود سپرده می‌شود (`craft_recipe`) و پایان نوار
**تنها** با سیگنال واقعی `item_crafted` (موفقیت، از `crafting_system.gd:107`) یا
`craft_failed` (شکست، از `crafting_system.gd:140`) اعلام می‌شود.

**سناریوی دستی (منبع واقعی سیگنال در گیم‌پلی):**

1. بازی را اجرا کن؛ با جمع‌کردن دو `scrap_metal` وارد میز کار شو (Tab نزدیک Workbench).
2. دکمه «فیلتر آب» را بزن — همان لحظه ردیف «در حال ساخت…» با نوار پیشرفت ظاهر می‌شود
   و دکمه‌های دیگر قفل می‌شوند (ضد ساخت هم‌زمان).
3. نوار در مدت `craft_time = 1.0` ثانیه (مقدار واقعی دستور در کاتالوگ) پر می‌شود.
4. در لحظه‌ی پایان، `CraftingSystem.craft_recipe` اجرا می‌شود و چون مواد واقعاً موجودند
   **سیگنال واقعی `item_crafted`** از `crafting_system.gd:107` منتشر می‌شود ←
   نوار کامل و پنهان می‌شود، لیست refresh می‌شود و Toast «ساخته شد: …» ظاهر می‌شود.
5. سناریوی شکست: کیف پولی (inventory) را پر کن (۱۲ آیتم) و دستور مدیکیت (۳ ثانیه) را بزن.
   در پایان، ساخت واقعی به‌خاطر جا نبودن جا fail می‌شود و
   **سیگنال واقعی `craft_failed`** از `crafting_system.gd:140` منتشر می‌شود ←
   نوار بی‌درنگ پنهان می‌شود، مواد rollback می‌شوند و Toast «ساخت ناموفق: …» دیده می‌شود.

**رد خودکار**: `tests/ui_polish_test.gd` فازهای ۴–۷ — دکمه‌ی واقعی `pressed` emit می‌شود،
نوار با `craft_time` واقعی پیش می‌رود و پایان آن با سیگنال واقعی
`item_crafted` (۷+۶ چک) و `craft_failed` (۷+۶ چک) از CraftingSystem واقعی اعلام می‌شود.

---

## سناریوی ۲ — تولتیپ آیتم در صفحه‌ی کیف (Item Tooltip)

**پیاده‌سازی**: هر ردیف آیتم به سیگنال‌های built-in واقعی `mouse_entered`/`mouse_exited`
متصل است (`inventory_ui.gd:189-190`) و متن تولتیپ از داده‌ی واقعی کاتالوگ
(نام + توضیح + تعداد لحظه‌ای) ساخته می‌شود (`_tooltip_text`).
همگام‌سازی تعداد **تنها** با سیگنال واقعی `EventBus.inventory_changed`
(منتشرشده از `inventory_manager.gd:53` پس از هر تغییر واقعی) انجام می‌شود
(`_on_inventory_changed` → `_sync_tooltip_with_inventory`).

**سناریوی دستی (منبع واقعی سیگنال در گیم‌پلی):**

1. یک `scrap_metal` بردار — `item_picked_up` واقعی منتشر و کیف (inventory) به‌روز می‌شود
   (`inventory_changed` واقعی از `inventory_manager.gd:53`).
2. Tab را باز کن و ماوس را روی ردیف «قطعه آهن‌قراضه» نگه‌دار —
   با سیگنال built-in `mouse_entered` تولتیپ ظاهر می‌شود:
   «قطعه آهن‌قراضه — ... (تعداد: ۱)».
3. ماوس را خارج کن — با `mouse_exited` تولتیپ فوراً پنهان می‌شود.
4. با ماوس روی همان ردیف بمان و هم‌زمان یک آیتم دیگر بردار —
   `inventory_changed` واقعی دوباره منتشر می‌شود و تعداد داخل تولتیپ **زنده** به‌روز می‌شود؛
   اگر آیتمِ زیر ماوس کاملاً تمام شود، همان سیگنال تولتیپ را پنهان می‌کند
   (`_sync_tooltip_with_inventory` — بدون polling).

**رد خودکار**: `tests/ui_polish_test.gd` فاز ۳ — `mouse_entered` واقعی emit می‌شود ←
تولتیپ visible با متن «قطعه آهن‌قراضه … تعداد: ۳»؛ `mouse_exited` ← پنهان؛
دوباره hover ← visible؛ سپس `item_dropped.emit(&"scrap_metal", 3)` واقعی ←
`inventory_changed` واقعی → تولتیپ پنهان (۷ چک).

---

## سناریوی ۳ — Toast با fade نرم (Fade Toast)

**پیاده‌سازی**: `hud.gd` به سیگنال‌های واقعی `toast_requested`، `item_picked_up` و بقیه متصل است
(`hud.gd:45-53`). هر toast با tween سه‌مرحله‌ای fade-in (۰.۲s) → مکث (۱.۸s) → fade-out (۰.۵s)
ساخته و سپس آزاد می‌شود — کاملاً رخدادمحور، بدون `_process`
(`hud.gd:_show_toast`). در حالت headless همین مسیر با SceneTreeTimer و بدون tween کار می‌کند
تا تست‌ها پایدار باشند.

**سناریوی دستی (منبع واقعی سیگنال در گیم‌پلی):**

1. نزدیک یک `RestSpot` بایست و کلید تعامل را بزن —
   **سیگنال واقعی `toast_requested`** از `rest_spot.gd:24` («استراحت کردی») منتشر می‌شود ←
   toast آبی‌فام با fade-in نرم در گوشه‌ی HUD ظاهر می‌شود، ۱.۸ ثانیه می‌ماند و به‌آرامی محو می‌شود.
2. بازی را ذخیره کن — `save_controller.gd:51` همان سیگنال واقعی را با متن «ذخیره شد» منتشر می‌کند ←
   همان رفتار fade.
3. یک آیتم بردار — `item_pickup.gd:47` سیگنال واقعی `item_picked_up` منتشر می‌کند ←
   toast سبز «+1 …» با همان انیمیشن.

**رد خودکار**: `tests/ui_polish_test.gd` فاز ۲ — `toast_requested.emit("تست toast")` واقعی ←
`get_toast_count() == 1` و متن واقعی Label بررسی می‌شود؛ فاز ۴/۵ ساخت، Toast «ساخته شد» واقعی
از همان زنجیره‌ی سناریوی ۱ شمرده می‌شود.

---

## سناریوی ۴ — جهت‌نمای صدا (Noise Direction Indicator)

**پیاده‌سازی**: `ui/hud/noise_indicator.gd` تنها به **سیگنال واقعی `EventBus.noise_emitted`**
گوش می‌دهد (`noise_indicator.gd:35`) و برای هر رخداد، موقعیت صفحه‌ایِ سرچشمه‌ی صدا را با
`Camera3D.unproject_position` می‌سازد و یک نشانگر کهربایی با شفافیت متناسب بلندی صدا
(clamp بین 0.35 و 1.0) در همان نقطه می‌گذارد که با tween محو می‌شود
(حداکثر ۸ نشانگر هم‌زمان؛ پشت دوربین نادیده گرفته می‌شود). هیچ `_process` وجود ندارد؛
تنها وابستگی، EventBus و دوربینِ viewport خودِ Control است.

**سناریوی دستی (منبع واقعی سیگنال در گیم‌پلی):**

1. بازی را اجرا کن و جلوی خودت را به یک در بگیر.
2. در را باز کن — **سیگنال واقعی `noise_emitted`** از `door.gd:23`
   (بلندی `OPEN_NOISE` واقعی در همان فایل) منتشر می‌شود ←
   روی صفحه، دقیقاً روی محل پروجکته‌شده‌ی در، یک نشانگر کهربایی ظاهر و ظرف ~۱.۳ ثانیه محو می‌شود.
3. چند قدم دور شو و بپر یا ضربه بزن — `player.gd:204` / `player.gd:230` همان سیگنال واقعی را
   با بلندی متفاوت منتشر می‌کنند ← شفافیت نشانگر متناسب بلندی تغییر می‌کند.
4. پشت سرت صدا رخ دهد (دوربین به سمت مقابل باشد) — نشانگری ساخته نمی‌شود
   (`is_position_behind` → نادیده؛ رفتار عمدی و امن).
5. نزدیک میز کار چیزی بساز — `crafting_system.gd:111` با بلندی ۱۰.0 همان سیگنال واقعی را
   منتشر می‌کند ← نشانگر روی میز کار.

**رد خودکار**: `tests/ui_polish_test.gd` فاز ۱ — دوربین واقعی صحنه با `noise_emitted.emit(pos, loudness)` واقعی
جلو/پشت دوربین، شمارش نشانگرها (۱ → ۸ → محدود به ۸ با حذف قدیمی‌ترین)، نام نشانگر `NoiseMarker`
و شفافیت `0.35` برای بلندی ۲.۵ بررسی می‌شود (۷ چک).

---

## سناریوی ۵ — افکت UI رهاکردن آیتم (Item Drop UI Effect)

**پیاده‌سازی**: `hud.gd:49` به **سیگنال واقعی `EventBus.item_dropped`** متصل است؛
handler آن (`hud.gd:170-174`) یک toast قرمز‌فام «-N نام آیتم» با همان انیمیشن fade
سناریوی ۳ نشان می‌دهد — کاملاً رخدادمحور، بدون هیچ polling.

**یادداشت صداقت‌آمیز درباره‌ی منبع در گیم‌پلی**: در کد فعلی گیم‌پلی، هیچ مسیر بازیکن
(نه UI و نه entities) هنوز `item_dropped` را منتشر نمی‌کند — این سیگنال از قبل در
EventBus تعریف شده و تنها فرستنده‌های فعلی آن تست‌های موجود ریپو هستند
(`tests/inventory_logic_test.gd:134`). بنابراین سناریوی دستی زیر سیگنال را از مسیر واقعیِ
پخش EventBus می‌گیرد (دقیقاً همان مسیری که در آینده گیم‌پلی drop هم استفاده خواهد کرد) و
**هیچ متد مستقیمی از HUD فراخوانی نمی‌شود**.

**سناریوی دستی (سیگنال واقعی روی باس واقعی):**

1. بازی را در ادیتور اجرا کن (`F5`) تا HUD و EventBus زنده باشند.
2. در دیباگر Godot (Remote → نود EventBus) یا با یک خط موقت در کنسول،
   سیگنال واقعی را منتشر کن: `EventBus.item_dropped.emit(&"scrap_metal", 1)`.
3. همان لحظه toast قرمز «-1 scrap metal» با fade ظاهر می‌شود — تنها به‌واسطه‌ی اتصالِ
   واقعیِ `hud.gd:49`؛ هیچ فراخوانی مستقیمی از `_show_toast` انجام نشده است.
4. برای مشاهده‌ی مسیر کامل واقعی: تست موجود `tests/inventory_logic_test.gd` همین سیگنال را
   emit می‌کند و Inventory واقعی را تغییر می‌دهد؛ در سشن زنده‌ی بازی همین emit
   هم toast (این سناریو) و هم همگام‌سازی تولتیپ (سناریوی ۲) را در همان لحظه فعال می‌کند.

**رد خودکار**: `tests/ui_polish_test.gd` فاز ۲ — `event_bus.item_dropped.emit(&"scrap_metal", 1)`
واقعی ← `get_toast_count()` از ۱ به ۲ افزایش و متن toast دوم «-1 scrap metal» شمرده می‌شود؛
فاز ۳ همین سیگنال با تعداد ۳ تولتیپ hover را از طریق `inventory_changed` واقعی پنهان می‌کند.

---

## جمع‌بندی تست‌های خودکار مرتبط

| تست | چک‌ها | پوشش |
|---|---:|---|
| `tests/ui_polish_test.gd` | ۵۴ | هر ۵ آیتم با سیگنال‌های واقعی EventBus (بدون فراخوانی مستقیم UI) |
| `tests/narrative_notes_test.gd` | ۷۸ | نوت‌ها و pickup-sceneهای سناریوی Task ۲ (تعامل واقعی `item_picked_up`) |

هر دو تست طبق الگوی استاندارد ریپو (`extends SceneTree`، شمارنده چک، گارد `EXPECTED_CHECK_COUNT`)
نوشته شده‌اند و CI آن‌ها را به‌صورت خودکار کشف و اجرا می‌کند.
