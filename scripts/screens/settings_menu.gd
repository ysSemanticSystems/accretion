extends Control
## Settings panel — persists via Settings autoload; live preview while open.

const ControlHints = preload("res://scripts/control_hints.gd")

@onready var sensitivity: HSlider = $Panel/Margin/Scroll/VBox/SensitivityRow/Slider
@onready var invert_y: CheckBox = $Panel/Margin/Scroll/VBox/InvertY
@onready var auto_level: CheckBox = $Panel/Margin/Scroll/VBox/AutoLevel
@onready var fov_rest: HSlider = $Panel/Margin/Scroll/VBox/FovRestRow/Slider
@onready var fov_max: HSlider = $Panel/Margin/Scroll/VBox/FovMaxRow/Slider
@onready var master: HSlider = $Panel/Margin/Scroll/VBox/MasterRow/Slider
@onready var sfx: HSlider = $Panel/Margin/Scroll/VBox/SfxRow/Slider
@onready var music: HSlider = $Panel/Margin/Scroll/VBox/MusicRow/Slider
@onready var hud_scale: HSlider = $Panel/Margin/Scroll/VBox/HudScaleRow/Slider
@onready var vsync: CheckBox = $Panel/Margin/Scroll/VBox/Vsync
@onready var controls_label: Label = $Panel/Margin/Scroll/VBox/ControlsLabel


var _opened_snapshot: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_snapshot = _snapshot_settings()
	_load_from_settings()
	_populate_controls_reference()
	for slider in [sensitivity, fov_rest, fov_max, master, sfx, music, hud_scale]:
		slider.value_changed.connect(_on_live_preview)
	for box in [invert_y, auto_level, vsync]:
		box.toggled.connect(_on_live_preview.bind(0.0))


func _populate_controls_reference() -> void:
	var lines: PackedStringArray = ControlHints.controls_reference_lines()
	controls_label.text = "\n".join(lines)


func _load_from_settings() -> void:
	sensitivity.value = Settings.mouse_sensitivity * 1000.0
	invert_y.button_pressed = Settings.invert_y
	auto_level.button_pressed = Settings.auto_level_default
	fov_rest.value = Settings.fov_rest
	fov_max.value = Settings.fov_max
	master.value = Settings.master_volume * 100.0
	sfx.value = Settings.sfx_volume * 100.0
	music.value = Settings.music_volume * 100.0
	hud_scale.value = Settings.hud_scale * 100.0
	vsync.button_pressed = Settings.vsync


func _apply(persist: bool) -> void:
	Settings.set_setting("mouse_sensitivity", sensitivity.value / 1000.0)
	Settings.set_setting("invert_y", invert_y.button_pressed)
	Settings.set_setting("auto_level_default", auto_level.button_pressed)
	Settings.set_setting("fov_rest", fov_rest.value)
	Settings.set_setting("fov_max", fov_max.value)
	Settings.set_setting("master_volume", master.value / 100.0)
	Settings.set_setting("sfx_volume", sfx.value / 100.0)
	Settings.set_setting("music_volume", music.value / 100.0)
	Settings.set_setting("hud_scale", hud_scale.value / 100.0)
	Settings.set_setting("vsync", vsync.button_pressed)
	if persist:
		Settings.save_settings()
	else:
		Settings.apply_runtime()


func _on_live_preview(_value: float = 0.0) -> void:
	_apply(false)


func _on_apply_pressed() -> void:
	AudioManager.play_ui_click()
	_apply(true)
	_opened_snapshot = _snapshot_settings()


func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	_restore_snapshot()
	GameShell.close_settings()


func _on_reset_pressed() -> void:
	AudioManager.play_ui_click()
	Settings.reset_to_defaults()
	_load_from_settings()
	_opened_snapshot = _snapshot_settings()


func _snapshot_settings() -> Dictionary:
	var snapshot: Dictionary = {}
	for key in Settings.DEFAULTS.keys():
		snapshot[key] = Settings.get_setting(key)
	return snapshot


func _restore_snapshot() -> void:
	for key in _opened_snapshot.keys():
		Settings.set_setting(key, _opened_snapshot[key])
	Settings.apply_runtime()
