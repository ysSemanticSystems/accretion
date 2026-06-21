extends Node3D
## Presentation glue: playable controls + telemetry HUD. All numbers from Rust.

const PRESET_CYGX1 := {"name": "Cyg X-1", "mass": 21.0, "mdot": 1.0e18}
const PRESET_SGRA := {"name": "Sgr A*", "mass": 4.0e6, "mdot": 1.0e15}
const PRESET_M87 := {"name": "M87*", "mass": 6.5e9, "mdot": 1.0e19}

@onready var black_hole: Node = $BlackHole
@onready var camera: Camera3D = $Camera3D
@onready var mass_slider: HSlider = $UI/Panel/Controls/MassSlider
@onready var feed_slider: HSlider = $UI/Panel/Controls/FeedSlider
@onready var spin_slider: HSlider = $UI/Panel/Controls/SpinSlider
@onready var title_label: Label = $UI/Panel/Controls/TitleLabel
@onready var stats_label: RichTextLabel = $UI/Panel/Controls/StatsLabel
@onready var warning_label: Label = $UI/Panel/Controls/WarningLabel
@onready var swatch: ColorRect = $UI/Panel/Controls/Swatch
@onready var help_label: Label = $UI/Panel/Controls/HelpLabel

var _cam_dist := 9.0
var _cam_yaw := 0.0
var _cam_pitch := 0.12
var _dragging := false
var _preset_name := "custom"


func _ready() -> void:
	camera.look_at(Vector3.ZERO, Vector3.UP)
	mass_slider.value_changed.connect(_on_control_changed)
	feed_slider.value_changed.connect(_on_control_changed)
	spin_slider.value_changed.connect(_on_control_changed)
	_apply_sliders()
	_update_camera()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
	if event is InputEventMouseMotion and _dragging:
		_cam_yaw -= event.relative.x * 0.005
		_cam_pitch = clamp(_cam_pitch - event.relative.y * 0.004, -0.35, 0.55)
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_dist = max(_cam_dist - 0.6, 4.0)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_dist = min(_cam_dist + 0.6, 18.0)
			_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_Q, KEY_COMMA:
			mass_slider.value = max(mass_slider.min_value, mass_slider.value - 0.05)
		KEY_E, KEY_PERIOD:
			mass_slider.value = min(mass_slider.max_value, mass_slider.value + 0.05)
		KEY_Z:
			feed_slider.value = max(feed_slider.min_value, feed_slider.value - 0.05)
		KEY_X:
			feed_slider.value = min(feed_slider.max_value, feed_slider.value + 0.05)
		KEY_A:
			spin_slider.value = max(spin_slider.min_value, spin_slider.value - 0.02)
		KEY_D:
			spin_slider.value = min(spin_slider.max_value, spin_slider.value + 0.02)
		KEY_1:
			_apply_preset(PRESET_CYGX1)
		KEY_2:
			_apply_preset(PRESET_SGRA)
		KEY_3:
			_apply_preset(PRESET_M87)


func _on_control_changed(_v: float) -> void:
	_preset_name = "custom"
	_apply_sliders()


func _apply_preset(p: Dictionary) -> void:
	_preset_name = p.name
	mass_slider.value = log(p.mass) / log(10.0)
	feed_slider.value = log(p.mdot) / log(10.0)
	_apply_sliders()


func _apply_sliders() -> void:
	black_hole.set("mass_solar", pow(10.0, mass_slider.value))
	black_hole.set("mdot_gs", pow(10.0, feed_slider.value))
	black_hole.set("spin", spin_slider.value)
	_refresh_hud()


func _process(_delta: float) -> void:
	_refresh_hud()


func _update_camera() -> void:
	var offset := Vector3(
		_cam_dist * cos(_cam_pitch) * sin(_cam_yaw),
		_cam_dist * sin(_cam_pitch) + 2.0,
		_cam_dist * cos(_cam_pitch) * cos(_cam_yaw)
	)
	camera.position = offset
	camera.look_at(Vector3.ZERO, Vector3.UP)


func _refresh_hud() -> void:
	var m: float = black_hole.get("mass_solar")
	var mdot: float = black_hole.get("mdot_gs")
	var spin: float = black_hole.get("spin")
	var l_edd: float = black_hole.call("l_eddington")
	var l_bol: float = black_hole.call("luminosity_erg_s")
	var lam: float = black_hole.call("eddington_ratio")
	var r_in: float = black_hole.call("inner_radius_cm")
	var r_s: float = black_hole.call("schwarzschild_radius_cm")
	var isco_rg: float = black_hole.call("isco_in_rg")
	var t_in: float = black_hole.call("disk_inner_temp", r_in)
	var c: Color = black_hole.call("disk_inner_color")

	swatch.color = c
	title_label.text = "Accretion — %s" % _preset_name

	var super_edd := lam > 1.0
	warning_label.visible = super_edd
	warning_label.text = "⚠ SUPER-EDDINGTON (λ = %.1f×): radiation pressure would blow the disk apart" % lam
	warning_label.modulate = Color(1.0, 0.35, 0.2) if super_edd else Color.WHITE

	stats_label.text = (
		"[b]Black hole[/b]\n"
		+ "  M = [color=cyan]%s[/color]\n" % HudFormat.mass_msun(m)
		+ "  spin a/M = %.2f  →  ISCO = %.2f R_g\n" % [spin, isco_rg]
		+ "  r_s = %s\n" % HudFormat.cm(r_s)
		+ "  r_ISCO = %s\n\n" % HudFormat.cm(r_in)
		+ "[b]Accretion[/b]\n"
		+ "  Ṁ = [color=yellow]%s[/color]\n" % HudFormat.grams_per_s(mdot)
		+ "  L_bol = %s\n" % HudFormat.erg_per_s(l_bol)
		+ "  L_Edd = %s\n" % HudFormat.erg_per_s(l_edd)
		+ "  λ_Edd = [color=%s]%s[/color]\n\n" % [
			"red" if super_edd else "lightgreen", HudFormat.lambda_edd(lam)
		]
		+ "[b]Inner disk (Rust)[/b]\n"
		+ "  T_peak = [color=orange]%s[/color]\n" % HudFormat.kelvin(t_in)
		+ "  blackbody RGB = (%.2f, %.2f, %.2f)" % [c.r, c.g, c.b]
	)

	help_label.text = (
		"Q/E mass · Z/X feed · A/D spin · 1/2/3 presets · drag orbit · scroll zoom"
	)
