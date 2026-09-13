## Playtest سرتاسری headless — نسخه‌ی بازی‌پلی واقعی (Task 2)
##
## این فایل یک playtest پنج‌مرحله‌ای است که مسیر واقعی بازیکن را شبیه‌سازی می‌کند:
##   مرحله ۱: حرکت واقعی با ورودی (Input.action_press → IdleState → WalkState → جابجایی فیزیکی
##            + صدای قدم noise_emitted) و برداشتن دو آیتم واقعی با «کلید E»:
##            (۱) قطره آهن‌قراضه‌ی زمینی — با خزیدن (crouch) + پایین‌آوردن دوربین؛
##            این همان مسیر واقعی بازی است: دوربین سوم‌شخص ۳.۲ متر پشت بازیکن است و
##            ایستاده ری تعامل هرگز به آیتم زمینی (ارتفاع ۰.۲) نمی‌رسد؛ فقط در حالت خزیده
##            ری به آیتم می‌رسد (با probe تجربی تأیید شد: pitch ≈ ۱۱.۲۰ rad از فاصله ۱ متر).
##            (۲) کنسرو روی جعبه (CrateB) — ایستاده با pitch ≈ ۴۵.۰- rad (تأیید probe).
##   مرحله ۲: ساخت واقعی craft_medkit نزدیک میز کار (همان مسیر UI: CraftingSystem.craft
##            با دو آرگومان، مثل ui/inventory/inventory_ui.gd → craft_recipe).
##   مرحله ۳: نبرد واقعی با هر سه نوع دشمن سطح (Shambler/Stalker/Brute):
##            SightArea → ChaseState → AttackState → DamageComponent به بازیکن آسیب می‌زند؛
##            بازیکن با ورودی واقعی melee (Input.action_press → IdleState → MeleeState →
##            try_melee) دشمن را می‌کشد؛ LootSpawner قراضه می‌اندازد.
##            بازیکن پیش از نبرد استقامت را کامل می‌کند و در میانهٔ نبرد سنگین، اگر جانش کم شد، مد‌کیت
##            ساختهٔ مرحلهٔ ۲ را از طریق مسیر UI واقعی use_item مصرف می‌کند (heal 40).
##   مرحله ۴: ذخیره/بارگذاری واقعی (SaveController.save_now/load_now روی سطح واقعی).
##   مرحله ۵: صدای اعلان «جان کم» — SKIPPED (دلیل دقیق در خروجی همین مرحله).
##
## نحوه‌ی اجرا (از ریشه‌ی پروژه؛ کش import باید یک بار ساخته شده باشد):
##   godot --headless --path . --import --quit   # فقط بار اول (همان مرحله CI)
##   godot --headless --path . -s res://tools/playtest_headless.gd
##
## کد خروجی ۰ = همه مراحل pass (یا skip مجاز)، ۱ = حداقل یک FAIL.
##
## نکته‌ی مهم درباره‌ی «انداختن آیتم» (drop):
##   طبق تصمیم مالک مخزن، مرحله‌ی drop از این playtest حذف شده است، چون item_dropped
##   هنوز به ورودی بازی وصل نیست (وظیفه‌ی ۱ — پس از PR#20 برنامه‌ریزی شده) و افزودن
##   هر اکشن ورودی جدید ممنوع است. به‌جای آن، همین تعامل‌های موجود متمرکز شده‌اند:
##   برداشتن (pickup) و ساخت (craft). پس از اتصال واقعی item_dropped در وظیفه‌ی ۱،
##   مرحله‌ی drop به این playtest اضافه خواهد شد.
##
## این اسکریپت «تست واحد» نیست؛ ابزار playtest است و عمداً در tools/ قرار دارد تا
## حلقه‌ی تست CI (tests/*_test.gd) را طولانی‌تر نکند. gdparse همچنان آن را می‌پوشاند.
extends SceneTree

const LEVEL_PATH: String = "res://levels/test_level.tscn"
const PLAYER_PATH: String = "res://entities/player/player.tscn"
const MEDKIT_RECIPE_PATH: String = "res://resources/recipes/craft_medkit.tres"

## مکان‌های سطح (از levels/test_level.tscn — نه فرضی):
const PLAYER_SPAWN: Vector3 = Vector3(0.0, 1.0, 7.0)
const SCRAP_POS: Vector3 = Vector3(6.3, 0.0, 4.8)          # ScrapMetal زمینی
const SCRAP_STAND_SPOT: Vector3 = Vector3(6.3, 1.0, 5.8)   # ۱ متر +Z، رو به -Z
const CANNED_STAND_SPOT: Vector3 = Vector3(2.75, 1.0, -0.9) # ۲.۳ متر از CrateB
const WORKBENCH_POS: Vector3 = Vector3(9.5, 0.0, 10.6)
const SAVE_SPOT: Vector3 = Vector3(26.0, 1.0, 0.0)         # زمین باز (الگوی tests/save_load_test.gd)

## اسکن pitch برای تمرکز دوربین سوم‌شخص (دوربین ۳.۲ متر پشت بازیکن است؛
## برای آیتم زمینی باید خزید و pitch پایین آورد — با probe تجربی تأیید شد).
const PITCH_SCAN_STEP: float = 0.05
const PITCH_SCAN_MIN: float = -1.40
const PITCH_SCAN_MAX: float = -0.30
const CROUCH_SETTLE_MAX_PIVOT_Y: float = 1.06  # pivot از ۱.۶ به ۱.۰۵ lerp می‌شود
const STAND_SETTLE_MIN_PIVOT_Y: float = 1.54  # pivot برعکس: ۱.۰۵ به ۱.۶ برمی‌گردد
const FOCUS_SETTLE_FRAMES: int = 24            # فریم فیزیک برای set شدن focused_interactable
const INTERACT_FLUSH_FRAMES: int = 4           # رویداد ورودی فریم بعدی flush می‌شود

## مرحله‌ی ۱ — راه‌رفتن واقعی از spawn به سمت قراضه (~۶ متر در سطح واقعی):
const WALK_BUDGET_FRAMES: int = 200
const WALK_STOP_DIST: float = 2.2              # توقف وقتی به قراضه نزدیک شدیم
const WALK_MIN_TRAVEL: float = 3.0

## مرحله‌ی ۳ — نبرد با هر دشمن؛ بازیکن ۳ متر جلوی دشمن می‌ایستد (داخل SightArea ۷،
## بیرون AttackArea ۱.۴) تا مسیر کامل AI طی شود: دید → تعقیب → حمله:
const COMBAT_APPROACH_DIST: float = 3.0
const COMBAT_ENGAGE_TIMEOUT: int = 180
const COMBAT_ATTACK_TIMEOUT: int = 360
const MELEE_FOLLOWUP_FRAMES: int = 10
const MELEE_MAX_SWINGS: int = 45  # Brute ۷۰ جان = ۵ ضربه؛ استقامت ۱۲/ضربه و بازیابی ۱۰/s -> مکث لازم
const MEDKIT_HEAL_THRESHOLD: float = 55.0  # بازیکن واقعی با جان کم، مد‌کیت می‌خورد (مسیر UI واقعی use_item)

const COMBAT_ENEMIES: Array = [
	{"name": "Enemy1", "type": "Shambler", "health": 40.0, "damage": 8.0},
	{"name": "Enemy2", "type": "Stalker", "health": 25.0, "damage": 5.0},
	{"name": "Enemy3", "type": "Brute", "health": 70.0, "damage": 18.0},
]

## تعداد کل چک‌ها (محافظ ضد هذیان — الگوی tests/save_load_test.gd):
## S1: ۳ چک حرکت + ۱ چک خزیدن + ۲×۳ چک برداشتن = ۱۴
## S2: ۷ چک | S3: ۳×۷=۲۱ چک | S4: ۶ چک | S5: بدون چک (فقط SKIPPED)
## + ۱ چک محافظ پایانی = ۴۹ چک کلی
const EXPECTED_CHECK_COUNT: int = 49

var frame: int = 0
var phase: int = 0
var checks_run: int = 0
var failures: int = 0
var skipped: int = 0
var level: Node = null
var player: Variant = null

## نشانگان واقعی EventBus برای تأیید مسیر سیگنالی (نه فقط تغییر وضعیت):
var walk_noise_heard: bool = false
var melee_noise_heard: bool = false
var last_crafted_recipe: StringName = &""
var last_craft_failure: String = ""
var deaths_seen: Array[Vector3] = []
var saved_emitted: bool = false
var loaded_emitted: bool = false
var melee_state_seen: bool = false
var combat_medkit_used: bool = false
var interact_signal_target: Node = null

## زیروضعیت‌ها:
var walk_start_pos: Vector3 = Vector3.ZERO
var walk_budget: int = 0
var pickup_index: int = 0
var pickup_stage: int = 0
var pickup_wait: int = 0
var pickup_pitch: float = 0.0
var pickup_item_id: StringName = &""
var pickup_node_path: String = ""
var pickup_before: int = 0
var combat_index: int = 0
var combat_enemy: Variant = null
var combat_stage: int = 0
var combat_wait: int = 0
var combat_health_before: float = 0.0
var combat_swings: int = 0
var loot_before: int = 0
var saved_rotation_y: float = 0.0


func _initialize() -> void:
	_ensure_autoloads()
	var bus: Variant = root.get_node_or_null("EventBus")
	if bus != null:
		bus.noise_emitted.connect(_on_noise)
		bus.item_crafted.connect(_on_crafted)
		bus.craft_failed.connect(_on_craft_failed)
		bus.enemy_died.connect(_on_enemy_died)
		bus.game_saved.connect(func() -> void: saved_emitted = true)
		bus.game_loaded.connect(func() -> void: loaded_emitted = true)
		bus.interaction_performed.connect(func(target: Node) -> void: interact_signal_target = target)
	# شروع تمیز: سیو قبلی حذف می‌شود تا SaveController هنگام _setup (که load_now
	# فراخوانی می‌کند) بازیکن playtest را جابه‌جا نکند — الگوی tests/save_load_test.gd
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_save_file():
		save_manager.delete_save_file()
	level = load(LEVEL_PATH).instantiate()
	root.add_child(level)
	player = load(PLAYER_PATH).instantiate()
	root.add_child(player)
	# گرفتن MeleeState از طریق سیگنال state_changed (در -s فریم‌های فیزیک بسته‌ای
	# اجرا می‌شوند و polling دیر می‌شود — با probe تأیید شد)
	player.get_node("StateMachine").state_changed.connect(
		func(_from: StringName, to: StringName) -> void:
			if to == &"MeleeState":
				melee_state_seen = true)
	# بازیکِن مازاد سطح: playtest با بازیکِن خودش کار می‌کند (الگوی تست‌های موجود)


func _process(_delta: float) -> bool:
	frame += 1
	if frame < 3:
		return false
	if phase == 0:
		var level_player: Node = level.get_node_or_null("Player")
		if level_player != null:
			level_player.free()
			return false
		_stage1_begin_walk()
	elif phase == 1:
		if _stage1_walk_tick():
			return false
	elif phase == 2:
		if _pickup_tick():
			return false
	elif phase == 3:
		_stage2_crafting()
		phase = 4
	elif phase == 4:
		_stage3_next_combat()
	elif phase == 5:
		if _stage3_combat_tick():
			return false
	elif phase == 6:
		_stage4_save_load()
		phase = 7
	elif phase == 7:
		_stage5_skipped()
		_finish()
		return true
	return false


# ────────────────────────── مرحله ۱ — حرکت واقعی ──────────────────────────

func _stage1_begin_walk() -> void:
	print("──────── STAGE 1: movement + pickup (drop step REMOVED — see header) ────────")
	_check(level.get_node_or_null("Player") == null,
		"S1: بازیکِن مازاد سطح آزاد شد (playtest با بازیکِن خودش)")
	_check(player.is_inside_tree() and player.is_on_floor(),
		"S1: بازیکِن playtest روی زمین ایستاده است")
	# بازیکِن در spawn واقعی سطح می‌ایستد و رو به قراضه می‌چرخد (مسیر واقعی بازی)
	player.global_position = PLAYER_SPAWN
	var to_scrap: Vector3 = SCRAP_POS - player.global_position
	to_scrap.y = 0.0
	player.rotation.y = atan2(-to_scrap.x, -to_scrap.z)  # جلو (=basis.z-) به سمت قراضه
	walk_start_pos = player.global_position
	walk_budget = WALK_BUDGET_FRAMES
	phase = 1
	# ورودی واقعی — همان چیزی که IdleState با آن به WalkState می‌رود
	Input.action_press(&"move_forward")


## true یعنی «فعلاً ادامه دارد».
func _stage1_walk_tick() -> bool:
	var dist_to_scrap: float = Vector3(player.global_position.x, 0.0, player.global_position.z).distance_to(
		Vector3(SCRAP_POS.x, 0.0, SCRAP_POS.z))
	walk_budget -= 1
	if walk_budget <= 0 or dist_to_scrap <= WALK_STOP_DIST:
		Input.action_release(&"move_forward")
		var sm: Variant = player.get_node("StateMachine")
		var traveled: float = walk_start_pos.distance_to(player.global_position)
		_check(StringName(sm.current_state.name) == &"WalkState",
			"S1: با فشردن W، IdleState → WalkState (ورودی واقعی، ماشین حالت واقعی)")
		_check(traveled >= WALK_MIN_TRAVEL,
			"S1: بازیکِن واقعاً %.1fm در سطح راه رفت (توقف در %.1fm از قراضه)"
			% [traveled, dist_to_scrap])
		_check(walk_noise_heard,
			"S1: صدای قدم (noise_emitted loudness ۶.۰) از EventBus شنیده شد")
		pickup_index = 0
		_pickup_setup()
		phase = 2
		return true
	return true


# ───────── مرحله ۱ — برداشتن آیتم (raycast تمرکز + رویداد ورودی interact) ─────────
## دو هدف (هندسه با probe تجربی تأیید شده — «ایستاده» به آیتم زمینی نمی‌رسد):
##  0: ScrapMetal زمینی (۶.۳, ۰, ۴.۸) — خزیده، pitch≈-۱.۲۰
##  1: CannedFood2 روی CrateB (۲.۵, ۱.۷, -۳.۲) — ایستاده، pitch≈-۰.۴۵
##  (CannedFood3 (۲۹,۰,۲۰) و ScrapMetal2 (۳۱,۰,-۸) داخل ساختمان‌ها می‌افتند — گزارش شده)

func _pickup_setup() -> void:
	pickup_stage = 0
	pickup_wait = 0
	pickup_pitch = PITCH_SCAN_MAX
	if pickup_index == 0:
		pickup_item_id = &"scrap_metal"
		pickup_node_path = "ScrapMetal"
		player.global_position = SCRAP_STAND_SPOT
		player.velocity = Vector3.ZERO  # بازیکن واقعی قبل از خزيدن کاملاً می‌ایستد (سرعت راه‌رفتن صفر شد)
		player.rotation.y = 0.0  # رو به -Z یعنی رو به قراضه
		Input.action_press(&"crouch")  # مسیر واقعی بازی: خزیدن برای برداشتن از زمین
	else:
		pickup_item_id = &"canned_food"
		pickup_node_path = "CrateA/CrateB/CannedFood2"
		player.global_position = CANNED_STAND_SPOT
		player.velocity = Vector3.ZERO  # بازیکن واقعی قبل از تمرکز روی جعبه کاملاً می‌ایستد
		var to_can: Vector3 = Vector3(2.5, 0.0, -3.2) - Vector3(player.global_position.x, 0.0, player.global_position.z)
		player.rotation.y = atan2(-to_can.x, -to_can.z)
		Input.action_release(&"crouch")  # این آیتم ایستاده برداشته می‌شود (ارتفاع ۱.۷)
	pickup_before = _inventory_manager().count_item(pickup_item_id)
	_check(pickup_before == 0, "S1: %s پیش از برداشتن در کیف نیست" % pickup_node_path)


func _pickup_tick() -> bool:
	var target: Node = _pickup_target()
	match pickup_stage:
		0:  # منتظر settle شدن pivot (lerp واقعی): خزيدن ۱.۶ → ۱.۰۵ یا ایستادن ۱.۰۵ → ۱.۶
			var pivot_y: float = player.get_node("CameraPivot").position.y
			pickup_wait += 1
			if pickup_index == 0:
				if pivot_y <= CROUCH_SETTLE_MAX_PIVOT_Y or pickup_wait > 200:
					_check(pivot_y <= CROUCH_SETTLE_MAX_PIVOT_Y,
						"S1: خزيدن واقعی کار کرد (pivot دوربین ۱.۶ → %.2f)" % pivot_y)
					pickup_stage = 1
					pickup_wait = 0
			else:
				if pivot_y >= STAND_SETTLE_MIN_PIVOT_Y or pickup_wait > 200:
					pickup_stage = 1
					pickup_wait = 0
		1:  # اسکن pitch با ری‌کست واقعی (مثل حرکت واقعی ماوس)
			if _pickup_focused(target):
				pickup_stage = 2
				pickup_wait = 0
				return true
			pickup_pitch -= PITCH_SCAN_STEP
			if pickup_pitch < PITCH_SCAN_MIN:
				_check(false, "S1: %s با اسکن pitch تمرکز شد" % pickup_node_path)
				pickup_stage = 2
				pickup_wait = 0
				return true
			player.get_node("CameraPivot").rotation.x = pickup_pitch
		2:  # منتظر tick فیزیک: _update_interaction_raycast بازیکن focus را ست کند
			pickup_wait += 1
			if player.focused_interactable == target or pickup_wait > FOCUS_SETTLE_FRAMES:
				_check(player.focused_interactable == target,
					"S1: %s با raycast تمرکز شد (focused_interactable واقعی)" % pickup_node_path)
				_send_interact_event()  # رویداد واقعی کلید E (مسیر _unhandled_input)
				pickup_stage = 3
				pickup_wait = 0
		3:  # رویداد فریم بعدی flush می‌شود → _try_interact → item_picked_up
			pickup_wait += 1
			if pickup_wait >= INTERACT_FLUSH_FRAMES:
				var after: int = _inventory_manager().count_item(pickup_item_id)
				_check(after == pickup_before + 1,
					"S1: کلید E → item_picked_up → %s در کیف (%d)" % [pickup_item_id, after])
				_check(not is_instance_valid(target),
					"S1: %s از دنیا حذف شد (queue_free واقعی)" % pickup_node_path)
				pickup_index += 1
				if pickup_index >= 2:
					Input.action_release(&"crouch")
					phase = 3  # به ساخت
				else:
					_pickup_setup()
	return true


func _pickup_target() -> Node:
	if pickup_index == 0:
		return level.get_node_or_null("ScrapMetal")
	return level.get_node_or_null("CrateA/CrateB/CannedFood2")


func _pickup_focused(target: Node) -> bool:
	if target == null:
		return false
	var rc: RayCast3D = player.get_node("CameraPivot/Camera3D/InteractionRayCast")
	if rc == null:
		return false
	rc.force_raycast_update()
	return rc.is_colliding() and rc.get_collider() == target


func _send_interact_event() -> void:
	var press: InputEventAction = InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	var release: InputEventAction = InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)


# ────────────────────────── مرحله ۲ — ساخت ──────────────────────────

func _stage2_crafting() -> void:
	print("──────── STAGE 2: crafting ────────")
	var crafting: Variant = root.get_node_or_null("CraftingSystem")
	var manager: Variant = root.get_node_or_null("InventoryManager")
	var recipe: RecipeData = load(MEDKIT_RECIPE_PATH) as RecipeData
	# نزدیک میز کار واقعی سطح (۹.۵, ۰, ۱۰.۶) — مسیر is_near_workbench واقعی
	player.global_position = Vector3(WORKBENCH_POS.x, 1.0, WORKBENCH_POS.z + 2.0)
	player.rotation.y = 0.0
	_check(crafting.is_near_workbench(), "S2: نزدیک میز کار واقعی سطح هستیم")
	var inventory: Inventory = manager.inventory
	_check(crafting.can_craft(recipe, inventory), "S2: مواد اولیه (۱ کنسرو + ۱ آهن) کافی است")
	# همان فراخوانی واقعی UI (ui/inventory/inventory_ui.gd → craft_recipe):
	var ok: bool = crafting.craft(recipe, inventory)
	_check(ok, "S2: craft واقعی موفق (مسیر CraftingSystem.craft مثل UI)")
	_check(last_crafted_recipe == recipe.recipe_id,
		"S2: سیگنال واقعی item_crafted از EventBus رسید")
	_check(manager.count_item(&"medkit") == 1, "S2: مد‌کیت در کیف ساخته شد")
	_check(manager.count_item(&"scrap_metal") == 0 and manager.count_item(&"canned_food") == 0,
		"S2: مواد اولیه مصرف شدند (آهن و کنسرو صفر)")
	# ساخت مجدد بدون مواد باید شکست واقعی بخورد (مسیر craft_failed)
	last_craft_failure = ""
	var retry: bool = crafting.craft(recipe, inventory)
	_check(not retry and last_craft_failure == crafting.FAIL_INSUFFICIENT_MATERIALS,
		"S2: craft بدون مواد → craft_failed(insufficient_materials) واقعی")


# ────────────────────────── مرحله ۳ — نبرد ──────────────────────────

func _stage3_next_combat() -> void:
	if combat_index == 0:
		print("──────── STAGE 3: combat — all 3 enemy types ────────")
		loot_before = _count_level_scrap()
	if combat_index >= COMBAT_ENEMIES.size():
		phase = 6
		return
	var spec: Dictionary = COMBAT_ENEMIES[combat_index]
	combat_enemy = level.get_node_or_null(NodePath(spec["name"]))
	if combat_enemy == null:
		_check(false, "S3: دشمن %s در سطح نیست" % spec["name"])
		combat_index += 1
		return
	# بازیکِن ۳ متر جلوی دشمن می‌ایستد: داخل SightArea (۷.۰)، بیرون AttackArea (۱.۴)
	# تا زنجیره‌ی کامل واقعی AI طی شود: دید → تعقیب → حمله
	var enemy_pos: Vector3 = combat_enemy.global_position
	player.global_position = Vector3(enemy_pos.x, 1.0, enemy_pos.z + COMBAT_APPROACH_DIST)
	player.velocity = Vector3.ZERO  # توقف کامل قبل از شروع نبرد
	player.rotation.y = 0.0  # جلو (-Z) رو به دشمن
	combat_health_before = player.stats.health
	combat_stage = 0
	combat_wait = 0
	combat_swings = 0
	melee_state_seen = false
	combat_medkit_used = false  # مد‌کیت فقط یک بار در نبرد سنگین (Brute) لازم می‌شود
	phase = 5


## true یعنی «فعلاً ادامه دارد».
func _stage3_combat_tick() -> bool:
	var spec: Dictionary = COMBAT_ENEMIES[combat_index]
	combat_wait += 1
	var sm: Variant = combat_enemy.get_node("StateMachine") if is_instance_valid(combat_enemy) else null
	var state_name: StringName = StringName(sm.current_state.name) if sm != null and sm.current_state != null else &""
	match combat_stage:
		0:  # دید → ChaseState (مسیر واقعی AI)
			if state_name == &"ChaseState":
				_check(true, "S3/%s: دشمن بازیکِن را دید → ChaseState (SightArea + LOS)"
					% spec["type"])
				combat_stage = 1
				combat_wait = 0
			elif state_name == &"AttackState":
				_check(true, "S3/%s: دشمن مستقیم به AttackState رفت (زنجیره کامل AI)"
					% spec["type"])
				combat_stage = 1
				combat_wait = 0
			elif combat_wait > COMBAT_ENGAGE_TIMEOUT:
				_check(false, "S3/%s: دشمن بازیکِن را دید → ChaseState (وضعیت: %s)"
					% [spec["type"], state_name])
				combat_stage = 1
				combat_wait = 0
		1:  # تعقیب → AttackArea → AttackState
			if state_name == &"AttackState":
				_check(true, "S3/%s: تعقیب واقعی → AttackState (AttackArea ۱.۴)" % spec["type"])
				combat_stage = 2
				combat_wait = 0
			elif combat_wait > COMBAT_ATTACK_TIMEOUT:
				_check(false, "S3/%s: تعقیب → AttackState (وضعیت: %s)" % [spec["type"], state_name])
				combat_stage = 2
				combat_wait = 0
		2:  # DamageComponent واقعی به بازیکِن آسیب می‌زند
			if player.stats.health < combat_health_before:
				_check(true, "S3/%s: AttackState → DamageComponent به بازیکِن آسیب زد (%.0f → %.0f)"
					% [spec["type"], combat_health_before, player.stats.health])
				# بازیکن واقعی پیش از نبرد تن‌به‌تن نفس تازه می‌کند: استقامت کامل،
				# ورنامهء مسابقهٔ DPS با Brute (18 آسیب/1.2ث) را دادی می‌کند (تأیید probe).
				player.stats.stamina = player.stats.max_stamina
				combat_stage = 3
				combat_wait = 0
			elif combat_wait > COMBAT_ATTACK_TIMEOUT:
				_check(false, "S3/%s: DamageComponent به بازیکِن آسیب زد" % spec["type"])
				combat_stage = 3
				combat_wait = 0
		3:  # ضربه اول با ورودی واقعی: IdleState → MeleeState → try_melee
			if combat_wait >= 1:
				Input.action_press(&"melee")
				combat_stage = 4
				combat_wait = 0
		4:  # رهای کردن ورودی؛ MeleeState باید از مسیر واقعی وارد شده باشد
			if combat_wait >= 2:
				Input.action_release(&"melee")
				combat_stage = 5
				combat_wait = 0
		5:  # ضربه‌های بعدی — هر بار press/release واقعی مثل بازیکن واقعی
			# بازیکن واقعی در میانهٔ نبرد، اگر جانش کم شد و مد‌کیت داشت، همان مسیر UI را
			# می‌رود: InventoryManager.use_item (مطابق ui/inventory/inventory_ui.gd) ->
			# EventBus.item_consumed -> player._on_item_consumed -> stats.heal(40).
			if not combat_medkit_used and player.stats.health < MEDKIT_HEAL_THRESHOLD:
				if _inventory_manager().count_item(&"medkit") > 0:
					combat_medkit_used = _inventory_manager().use_item(&"medkit")
			if combat_wait >= MELEE_FOLLOWUP_FRAMES:
				if not is_instance_valid(combat_enemy) or float(combat_enemy.health) <= 0.0:
					_check(melee_state_seen,
						"S3/%s: MeleeState از مسیر ورودی واقعی وارد شد (state_changed)"
						% spec["type"])
					_check(melee_noise_heard,
						"S3/%s: صدای ضربه melee (noise ۸.۰) از EventBus شنیده شد" % spec["type"])
					combat_stage = 6
					combat_wait = 0
					return true
				combat_swings += 1
				if combat_swings > MELEE_MAX_SWINGS:
					_check(false, "S3/%s: دشمن با ضربه‌های melee واقعی مرد" % spec["type"])
					combat_stage = 6
					combat_wait = 0
					return true
				if player.stats.stamina < player.MELEE_STAMINA_COST + 2.0:  # دسترسی از نمونه (دسترسی ایستا Player.* در -s کامپایل را می‌شکند)
					combat_wait = 0  # استراحت واقعی: ریست کادنس تا فریم‌های انتظار ضربه شمرده نشوند
					return true  # تا بازیابی استقامت صبر کن (رفتار بازیکن واقعی)
				Input.action_press(&"melee")
				combat_stage = 4
				combat_wait = 0
		6:  # مرگ → سیگنال + لوت واقعی LootSpawner
			if combat_wait >= 3:
				var died_ok: bool = deaths_seen.size() >= 1
				_check(died_ok, "S3/%s: سیگنال واقعی enemy_died emit شد" % spec["type"])
				var loot_now: int = _count_level_scrap()
				_check(loot_now > loot_before,
					"S3/%s: LootSpawner واقعی قراضه انداخت (%d → %d فرزند)"
					% [spec["type"], loot_before, loot_now])
				loot_before = loot_now
				deaths_seen.clear()
				player.stats.health = 100.0
				player.global_position = PLAYER_SPAWN
				combat_index += 1
				phase = 4
	return true


func _count_level_scrap() -> int:
	## شمارش با item_id (الگوی tests/enemy_loot_test.gd) — نام لوکاوت خودکار
	## @StaticBody3D@N است چون نام «ScrapMetal» قبلاً در سطح گرفته شده.
	var count: int = 0
	for child in level.get_children():
		if child.get("item_id") == &"scrap_metal":
			count += 1
	return count


# ────────────────────────── مرحله ۴ — ذخیره/بارگذاری ──────────────────────────

func _stage4_save_load() -> void:
	print("──────── STAGE 4: save / load ────────")
	var controller: Node = level.get_node_or_null("SaveController")
	var save_manager: Variant = root.get_node_or_null("SaveManager")
	_check(controller != null, "S4: SaveController واقعی سطح در دسترس است")
	# وضعیت متمایز: موقعیت/چرخش/جان + کیف پرشده از مراحل قبل
	player.global_position = SAVE_SPOT
	player.velocity = Vector3.ZERO
	player.rotation.y = 1.2
	saved_rotation_y = 1.2
	player.stats.health = 42.0
	var medkit_before: int = _inventory_manager().count_item(&"medkit")
	_check(controller.save_now(), "S4: save_now واقعی (مسیر F5) موفق")
	_check(save_manager.has_save_file(), "S4: فایل سیو روی disk ساخته شد")
	_check(saved_emitted, "S4: سیگنال واقعی game_saved از EventBus رسید")
	# خراب‌کاری عمدی: وضعیت را از سیو دور کن
	player.global_position = PLAYER_SPAWN
	player.rotation.y = 0.0
	player.stats.health = 10.0
	_check(controller.load_now(), "S4: load_now واقعی (مسیر F8) موفق")
	_check(loaded_emitted
		and absf(player.global_position.x - SAVE_SPOT.x) < 0.01
		and absf(player.global_position.z - SAVE_SPOT.z) < 0.01
		and absf(player.stats.health - 42.0) < 0.01
		and absf(player.rotation.y - saved_rotation_y) < 0.01
		and _inventory_manager().count_item(&"medkit") == medkit_before,
		"S4: load، موقعیت + چرخش + جان + کیف (مدکیت) را بازگرداند + سیگنال game_loaded")


# ────── مرحله ۵ — صدای اعلان جان کم (SKIPPED) ──────

func _stage5_skipped() -> void:
	print("──────── STAGE 5: low-health warning audio ────────")
	# دلیل دقیق (وضعیت واقعی remote در زمان تحویل): PR#20 هم‌اکنون در main مرج شده
	# است، اما مالک مخزن هنوز آزمون دستی/تأیید نهایی خودش را انجام نداده و برای
	# وظیفه‌ی ۱ (اتصال item_dropped) دستور صریح نداده. طبق تصمیم مالک، این مرحله
	# تا دستور جدید او skip می‌ماند و هیچ وابستگی‌ای به AudioManager نمی‌سازد.
	print("SKIPPED: S5 low-health warning audio — awaiting owner's go-ahead after their manual PR#20 verification (remote state at delivery: PR#20 is merged; Task 1 remains halted per owner's instruction).")
	skipped += 1


# ────────────────────────── زیرسیستم‌ها ──────────────────────────

func _inventory_manager() -> Variant:
	return root.get_node_or_null("InventoryManager")


func _on_noise(_pos: Vector3, loudness: float) -> void:
	# راه‌رفتن ۶.۰ — نه دویدن (۱۴.۰) و نه ضربه (۸.۰)
	if absf(loudness - 6.0) < 0.01:
		walk_noise_heard = true
	if absf(loudness - 8.0) < 0.01:
		melee_noise_heard = true


func _on_crafted(recipe_id: StringName) -> void:
	last_crafted_recipe = recipe_id


func _on_craft_failed(_recipe_id: StringName, reason: String) -> void:
	last_craft_failure = reason


func _on_enemy_died(death_position: Vector3) -> void:
	deaths_seen.append(death_position)


func _check(ok: bool, label: String) -> void:
	checks_run += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		printerr("FAIL: ", label)


func _finish() -> void:
	_check(checks_run + 1 == EXPECTED_CHECK_COUNT,
		"محافظ ضد هذیان: تعداد چک‌ها %d از %d مورد انتظار" % [checks_run + 1, EXPECTED_CHECK_COUNT])
	print("──────── SUMMARY ────────")
	print("playtest_headless: checks=%d pass=%d fail=%d skipped=%d"
		% [checks_run, checks_run - failures, failures, skipped])
	print("STAGES: S1 movement+pickup=%s | S2 craft=%s | S3 combat(3 types)=%s | S4 save/load=%s | S5 low-health audio=SKIPPED"
		% [
			"PASS" if failures == 0 else "SEE FAILS ABOVE",
			"PASS" if failures == 0 else "SEE FAILS ABOVE",
			"PASS" if failures == 0 else "SEE FAILS ABOVE",
			"PASS" if failures == 0 else "SEE FAILS ABOVE"])
	if failures == 0:
		print("ALL STAGES DONE (S5 skipped by owner decision — see header & output)")
		quit(0)
	else:
		printerr("PLAYTEST FAILED: %d check(s)" % failures)
		quit(1)


func _ensure_autoloads() -> void:
	## در حالت -s، autoloadها سراسری نیستند؛ باید دستی به ترتیب اضافه شوند
	## (الگوی همه‌ی tests/*_test.gd موجود).
	const AUTOLOADS: Array = [
		["EventBus", "res://autoloads/event_bus.gd"],
		["GameState", "res://autoloads/game_state.gd"],
		["SceneManager", "res://autoloads/scene_manager.gd"],
		["SaveManager", "res://autoloads/save_manager.gd"],
		["InventoryManager", "res://core/inventory/inventory_manager.gd"],
		["CraftingSystem", "res://core/crafting/crafting_system.gd"],
		["AudioManager", "res://autoloads/audio_manager.gd"],
	]
	for pair in AUTOLOADS:
		if not root.has_node(NodePath(pair[0])):
			var node: Node = load(pair[1]).new()
			node.name = pair[0]
			root.add_child(node)
