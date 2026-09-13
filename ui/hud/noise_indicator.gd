## NoiseIndicator
## جهت‌نمای صدای محیط (پولیش UI): با هر سیگنال واقعیِ `EventBus.noise_emitted`
## یک نشانگر کوچک در محل تصویری (unproject) سرچشمه‌ی صدا روی صفحه ظاهر می‌شود
## و به‌آرامی محو می‌گردد. کاملاً event-driven است — هیچ polling در _process نداریم.
## وابستگی فقط به EventBus و دوربینِ viewport (هیچ autoload دیگری مستقیم استفاده نمی‌شود).
class_name NoiseIndicator
extends Control

## حداکثر نشانگرهای همزمان (هر رویداد صدا یکی می‌سازد؛ قدیمی‌ها محو می‌شوند).
const MAX_MARKERS: int = 8

## کمینه‌ی شفافیت نشانگر (بلندی صدا این را بالا می‌برد).
const MIN_OPACITY: float = 0.35

## بلندترین صدای معمول بازی (دویدن = ۱۴) برای نرمال‌سازی شفافیت.
const REFERENCE_LOUDNESS: float = 14.0

## مدت محو شدن نشانگر (ثانیه).
const FADE_SECONDS: float = 0.9

## اندازه‌ی نشانگر (پیکسل).
const MARKER_SIZE: float = 10.0

## رنگ نشانگر (کهربایی — هشدار صدا).
const MARKER_COLOR: Color = Color(0.95, 0.75, 0.15, 1.0)

## ظرف نگه‌داشتن نشانگرها؛ همان این نود است (full-rect و غیرفعال برای موس).
var marker_parent: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_parent = self
	EventBus.noise_emitted.connect(_on_noise_emitted)


## واکنش به سیگنال واقعی نویز: ساخت نشانگر در موقعیت صفحه‌ایِ سرچشمه‌ی صدا.
## اگر صدا پشت دوربین باشد یا دوربینی در viewport نباشد، هیچ کاری نمی‌کنیم.
func _on_noise_emitted(noise_position: Vector3, loudness: float) -> void:
	if not is_inside_tree():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	if camera.is_position_behind(noise_position):
		return
	var screen_pos: Vector2 = camera.unproject_position(noise_position)
	_spawn_marker(screen_pos, loudness)


## ساخت یک نشانگر در موقعیت داده‌شده با شفافیتی متناسب با بلندی صدا.
func _spawn_marker(screen_pos: Vector2, loudness: float) -> void:
	if marker_parent == null:
		return
	# اگر از سقف نشانگر عبور کردیم، قدیمی‌ترین را فوراً آزاد می‌کنیم.
	var markers: Array[Node] = marker_parent.get_children()
	while markers.size() >= MAX_MARKERS:
		var oldest: Node = markers.pop_front()
		if is_instance_valid(oldest):
			oldest.free()

	var marker: ColorRect = ColorRect.new()
	marker.name = "NoiseMarker"
	marker.color = MARKER_COLOR
	marker.size = Vector2(MARKER_SIZE, MARKER_SIZE)
	marker.position = screen_pos - Vector2(MARKER_SIZE * 0.5, MARKER_SIZE * 0.5)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.modulate.a = clampf(loudness / REFERENCE_LOUDNESS, MIN_OPACITY, 1.0)
	marker_parent.add_child(marker)

	# محو شدن خودکار با tween (بدون polling)؛ در headless هم بی‌خطا است.
	var tween: Tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(marker, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(marker.queue_free)


## تعداد نشانگرهای فعلی (برای تست headless — وضعیت همگام و قابل‌اتکا).
func get_marker_count() -> int:
	if marker_parent == null:
		return 0
	return marker_parent.get_child_count()
