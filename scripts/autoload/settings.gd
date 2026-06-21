extends Node
## Persistent player preferences. Spec: wiki/features/F009-settings-audio.md

signal settings_changed

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"mouse_sensitivity": 0.0028,
	"invert_y": false,
	"auto_level_default": true,
	"fov_rest": 70.0,
	"fov_max": 86.0,
	"master_volume": 0.5,
	"sfx_volume": 0.5,
	"music_volume": 0.5,
	"hud_scale": 1.0,
	"vsync": true,
}

var mouse_sensitivity: float = DEFAULTS.mouse_sensitivity
var invert_y: bool = DEFAULTS.invert_y
var auto_level_default: bool = DEFAULTS.auto_level_default
var fov_rest: float = DEFAULTS.fov_rest
var fov_max: float = DEFAULTS.fov_max
var master_volume: float = DEFAULTS.master_volume
var sfx_volume: float = DEFAULTS.sfx_volume
var music_volume: float = DEFAULTS.music_volume
var hud_scale: float = DEFAULTS.hud_scale
var vsync: bool = DEFAULTS.vsync


func _ready() -> void:
	load_settings()
	_apply_all()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key in DEFAULTS.keys():
		if cfg.has_section_key("settings", key):
			set_setting(key, cfg.get_value("settings", key))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in DEFAULTS.keys():
		cfg.set_value("settings", key, get_setting(key))
	cfg.save(PATH)
	settings_changed.emit()
	_apply_all()


func apply_runtime() -> void:
	settings_changed.emit()
	_apply_all()


func set_setting(key: StringName, value: Variant) -> void:
	match key:
		"mouse_sensitivity":
			mouse_sensitivity = float(value)
		"invert_y":
			invert_y = bool(value)
		"auto_level_default":
			auto_level_default = bool(value)
		"fov_rest":
			fov_rest = float(value)
		"fov_max":
			fov_max = float(value)
		"master_volume":
			master_volume = clampf(float(value), 0.0, 1.0)
		"sfx_volume":
			sfx_volume = clampf(float(value), 0.0, 1.0)
		"music_volume":
			music_volume = clampf(float(value), 0.0, 1.0)
		"hud_scale":
			hud_scale = clampf(float(value), 0.75, 1.5)
		"vsync":
			vsync = bool(value)


func get_setting(key: StringName) -> Variant:
	match key:
		"mouse_sensitivity":
			return mouse_sensitivity
		"invert_y":
			return invert_y
		"auto_level_default":
			return auto_level_default
		"fov_rest":
			return fov_rest
		"fov_max":
			return fov_max
		"master_volume":
			return master_volume
		"sfx_volume":
			return sfx_volume
		"music_volume":
			return music_volume
		"hud_scale":
			return hud_scale
		"vsync":
			return vsync
	return null


func reset_to_defaults() -> void:
	for key in DEFAULTS.keys():
		set_setting(key, DEFAULTS[key])
	save_settings()


func _apply_all() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	call_deferred("_apply_audio")


func _apply_audio() -> void:
	if AudioManager:
		AudioManager.apply_volumes(master_volume, sfx_volume, music_volume)
