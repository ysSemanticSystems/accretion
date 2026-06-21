extends Control
## Settings panel — persists via Settings autoload.

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_from_settings()


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


func _apply() -> void:
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
	Settings.save_settings()


func _on_apply_pressed() -> void:
	AudioManager.play_ui_click()
	_apply()


func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("close_settings"):
		shell.close_settings()
	elif GameState.state == GameState.State.MENU:
		GameState.transition(GameState.State.MENU)


func _on_reset_pressed() -> void:
	AudioManager.play_ui_click()
	Settings.reset_to_defaults()
	_load_from_settings()
