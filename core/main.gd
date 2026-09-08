extends Node2D

## صحنه‌ی ورودی پروژه.
##
## اینجا عمداً خالی است: فاز ۰ فقط قرار است ثابت کند ریپو درست چیده شده،
## autoload ها کار می‌کنند و پروژه با F5 بالا می‌آید.
## فاز ۱ (لوپ بقا) از همین صحنه شروع می‌شود.

const PROJECT_TITLE := "Aftergrid"
const CURRENT_PHASE := "Phase 0 — repository structure"

@onready var _title_label: Label = $TitleLabel
@onready var _hint_label: Label = $HintLabel


func _ready() -> void:
	GameEvents.game_booted.connect(_on_game_booted)
	GameEvents.game_booted.emit(PROJECT_TITLE, CURRENT_PHASE)
	_hint_label.text = "No gameplay yet. See README.md for the phase plan."


func _on_game_booted(title: String, phase: String) -> void:
	_title_label.text = "%s" % title
	print("[%s] %s" % [title, phase])
