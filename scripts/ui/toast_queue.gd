extends Control
## Three-slot toast queue. Spec: wiki/features/F010-hud-component.md

const MAX_SLOTS := 3
const FADE_SEC := 3.5

@onready var slot_container: VBoxContainer = $VBox

var _slots: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -120.0


func push(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82, 0.95))
	label.add_theme_font_size_override("font_size", 14)
	slot_container.add_child(label)
	_slots.append(label)
	while _slots.size() > MAX_SLOTS:
		var old: Label = _slots.pop_front()
		old.queue_free()
	var tween := create_tween()
	tween.tween_interval(FADE_SEC)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func():
		_slots.erase(label)
		label.queue_free()
	)
