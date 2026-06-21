extends Control
## Three-slot toast queue. Spec: wiki/features/F010-hud-component.md

const MAX_SLOTS := 3
const FADE_SEC := 3.5

@onready var slot_container: VBoxContainer = $VBox

var _entries: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -120.0


func _exit_tree() -> void:
	_clear_all()


func push(text: String) -> void:
	if not is_node_ready() or slot_container == null:
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82, 0.95))
	label.add_theme_font_size_override("font_size", 14)
	slot_container.add_child(label)
	var tween := create_tween()
	tween.tween_interval(FADE_SEC)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_dismiss.bind(label))
	_entries.append({"label": label, "tween": tween})
	while _entries.size() > MAX_SLOTS:
		_evict_front()


func _evict_front() -> void:
	if _entries.is_empty():
		return
	var entry: Dictionary = _entries.pop_front()
	_release_entry(entry)


func _dismiss(label: Label) -> void:
	for i in _entries.size():
		var entry_label: Label = _entries[i].get("label")
		if entry_label == label:
			_entries.remove_at(i)
			break
	if label != null and is_instance_valid(label):
		label.queue_free()


func _release_entry(entry: Dictionary) -> void:
	var tween: Tween = entry.get("tween")
	var label: Label = entry.get("label")
	if tween != null and tween.is_valid():
		tween.kill()
	if label != null and is_instance_valid(label):
		label.queue_free()


func _clear_all() -> void:
	for entry in _entries:
		_release_entry(entry)
	_entries.clear()
