extends Node3D
## Game controller: accretion survival loop, scoring, and presentation.
##
## Presentation only (rule 10). Physics comes from the BlackHole gdext node
## (accretion-core in Rust). Gameplay tuning constants live here (rule 02 §6).

enum RunPhase { PLAYING, ENDED }

const PRESET_CYGX1 := {"name": "Cyg X-1", "mass": 21.0, "mdot": 8.0e17, "spin": 0.0}
const PRESET_SGRA := {"name": "Sgr A*", "mass": 4.0e6, "mdot": 2.0e23, "spin": 0.0}
const PRESET_M87 := {"name": "M87*", "mass": 6.5e9, "mdot": 2.0e26, "spin": 0.85}

const MILESTONES := [
	{"mass": 21.0, "name": "Cyg X-1 — stellar-mass"},
	{"mass": 1.0e3, "name": "Intermediate-mass (IMBH)"},
	{"mass": 1.0e5, "name": "Seed supermassive"},
	{"mass": 4.0e6, "name": "Sgr A* — galactic centre"},
	{"mass": 1.0e8, "name": "Supermassive"},
	{"mass": 6.5e9, "name": "M87* — giant elliptical"},
]
const VICTORY_MASS := 6.5e9
const MAX_DISRUPTIONS := 3
const START_PRESET := PRESET_CYGX1

const SECONDS_PER_EFOLD := 22.0
const DRAIN_SCALE := 0.55
const RECOVER_SCALE := 0.16
const DISRUPT_RESET := 0.35

const IDLE_BEFORE_AUTORBIT := 4.0
const AUTORBIT_SPEED := 0.07
const CAM_SMOOTH := 7.0
const INTRO_DOLLY_FROM := 30.0
const DISK_BASE_SCALE := 4.0
const OUTER_RG := 26.0
const GRADIENT_OUTER_RISCO := 14.0

@onready var black_hole: Node = $BlackHole
@onready var camera: Camera3D = $Camera3D
@onready var disk_mesh: Node3D = $DiskMesh
@onready var mass_slider: HSlider = $UI/Panel/Controls/MassSlider
@onready var feed_slider: HSlider = $UI/Panel/Controls/FeedSlider
@onready var spin_slider: HSlider = $UI/Panel/Controls/SpinSlider
@onready var title_label: Label = $UI/Panel/Controls/TitleLabel
@onready var class_label: Label = $UI/Panel/Controls/ClassLabel
@onready var score_label: Label = $UI/Panel/Controls/ScoreLabel
@onready var milestone_label: Label = $UI/Panel/Controls/MilestoneLabel
@onready var milestone_bar: ProgressBar = $UI/Panel/Controls/MilestoneBar
@onready var integrity_bar: ProgressBar = $UI/Panel/Controls/IntegrityBar
@onready var stats_label: RichTextLabel = $UI/Panel/Controls/StatsLabel
@onready var warning_label: Label = $UI/Panel/Controls/WarningLabel
@onready var swatch: ColorRect = $UI/Panel/Controls/Swatch
@onready var help_label: Label = $UI/Panel/Controls/HelpLabel
@onready var banner: Label = $UI/Banner
@onready var run_overlay: PanelContainer = $UI/RunOverlay
@onready var run_title: Label = $UI/RunOverlay/Margin/VBox/RunTitle
@onready var run_body: RichTextLabel = $UI/RunOverlay/Margin/VBox/RunBody

var _phase := RunPhase.PLAYING
var _mass := 10.0
var _integrity := 1.0
var _sim_seconds := 0.0
var _preset_name := "custom"
var _class_name := ""
var _was_super_eddington := false
var _setting_slider := false
var _banner_time := 0.0
var _disruptions := 0
var _milestones_hit := 0
var _milestone_idx := 0
var _run_score := 0
var _best_score := 0
var _victory := false

var _cam_dist := 9.0
var _cam_yaw := 0.4
var _cam_pitch := 0.16
var _target_dist := 9.0
var _target_yaw := 0.4
var _target_pitch := 0.16
var _dragging := false
var _idle_time := 0.0


func _ready() -> void:
	mass_slider.value_changed.connect(_on_mass_changed)
	feed_slider.value_changed.connect(_on_feed_changed)
	spin_slider.value_changed.connect(_on_spin_changed)
	integrity_bar.min_value = 0.0
	integrity_bar.max_value = 1.0
	milestone_bar.min_value = 0.0
	milestone_bar.max_value = 1.0
	banner.visible = false
	run_overlay.visible = false
	_best_score = RunScore.load_best()
	_start_run(START_PRESET)
	_cam_dist = INTRO_DOLLY_FROM
	_update_camera_transform()
	print("[accretion] Grow to M87* without losing the disk three times. R = new run · 1/2/3 = challenge presets")


func _input(event: InputEvent) -> void:
	if _phase == RunPhase.ENDED:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_dist = max(_target_dist - 0.7, 4.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_dist = min(_target_dist + 0.7, 20.0)
		_idle_time = 0.0
	if event is InputEventMouseMotion and _dragging:
		_target_yaw -= event.relative.x * 0.005
		_target_pitch = clamp(_target_pitch - event.relative.y * 0.004, -0.35, 0.6)
		_idle_time = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_R or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_start_run(_current_preset_dict())
		return
	if _phase == RunPhase.ENDED:
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
			_start_run(PRESET_CYGX1)
		KEY_2:
			_start_run(PRESET_SGRA)
		KEY_3:
			_start_run(PRESET_M87)


func _current_preset_dict() -> Dictionary:
	match _preset_name:
		PRESET_CYGX1.name:
			return PRESET_CYGX1
		PRESET_SGRA.name:
			return PRESET_SGRA
		PRESET_M87.name:
			return PRESET_M87
		_:
			return {
				"name": "custom",
				"mass": _mass,
				"mdot": black_hole.get("mdot_gs"),
				"spin": black_hole.get("spin"),
			}


func _start_run(p: Dictionary) -> void:
	_phase = RunPhase.PLAYING
	run_overlay.visible = false
	_preset_name = p.name
	_mass = p.mass
	_integrity = 1.0
	_sim_seconds = 0.0
	_disruptions = 0
	_milestones_hit = 0
	_milestone_idx = 0
	_class_name = ""
	_victory = false
	_was_super_eddington = false
	_set_slider_silent(mass_slider, log(_mass) / log(10.0))
	_set_slider_silent(feed_slider, log(p.mdot) / log(10.0))
	_set_slider_silent(spin_slider, p.get("spin", 0.0))
	_apply_inputs()
	_update_class()
	_show_banner("RUN START — feed the disk, ride λ ≤ 1, reach M87*", 2.5)
	print("[accretion] new run → %s" % p.name)


func _on_mass_changed(v: float) -> void:
	if _setting_slider or _phase != RunPhase.PLAYING:
		return
	_preset_name = "custom"
	_mass = pow(10.0, v)
	_apply_inputs()


func _on_feed_changed(_v: float) -> void:
	if _setting_slider or _phase != RunPhase.PLAYING:
		return
	_preset_name = "custom"
	_apply_inputs()


func _on_spin_changed(_v: float) -> void:
	if _setting_slider or _phase != RunPhase.PLAYING:
		return
	_apply_inputs()


func _apply_inputs() -> void:
	black_hole.set("mass_solar", _mass)
	black_hole.set("mdot_gs", pow(10.0, feed_slider.value))
	black_hole.set("spin", spin_slider.value)
	black_hole.set("efficiency", black_hole.call("efficiency_from_spin"))


func _process(delta: float) -> void:
	if _phase == RunPhase.PLAYING:
		_step_simulation(delta)
	_update_camera(delta)
	_refresh_hud()
	_drive_graphics()
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time <= 0.0:
			banner.visible = false


func _step_simulation(delta: float) -> void:
	black_hole.set("efficiency", black_hole.call("efficiency_from_spin"))
	var t_salpeter: float = black_hole.call("salpeter_time_s")
	var dt_sim := delta * t_salpeter / SECONDS_PER_EFOLD
	_sim_seconds += dt_sim

	_mass = black_hole.call("advance_mass", dt_sim)
	black_hole.set("mass_solar", _mass)
	_set_slider_silent(mass_slider, clamp(log(_mass) / log(10.0), mass_slider.min_value, mass_slider.max_value))

	var spin: float = black_hole.call("advance_spin", dt_sim)
	black_hole.set("spin", spin)
	_set_slider_silent(spin_slider, spin)

	var rate: float = black_hole.call("integrity_rate")
	if rate < 0.0:
		_integrity += rate * DRAIN_SCALE * delta
	else:
		_integrity += min(rate, 1.0) * RECOVER_SCALE * delta
	_integrity = clamp(_integrity, 0.0, 1.0)
	if _integrity <= 0.0:
		_on_disruption()

	_check_milestones()
	_update_class()

	if _mass >= VICTORY_MASS:
		_end_run(true)


func _check_milestones() -> void:
	while _milestone_idx < MILESTONES.size() and _mass >= MILESTONES[_milestone_idx].mass:
		_milestones_hit += 1
		_show_banner("MILESTONE — %s" % MILESTONES[_milestone_idx].name, 2.5)
		_milestone_idx += 1


func _on_disruption() -> void:
	_disruptions += 1
	_integrity = DISRUPT_RESET
	_set_slider_silent(feed_slider, feed_slider.min_value)
	black_hole.set("mdot_gs", pow(10.0, feed_slider.min_value))
	push_warning("[accretion] disk disrupted (%d/%d)" % [_disruptions, MAX_DISRUPTIONS])
	if _disruptions >= MAX_DISRUPTIONS:
		_show_banner("DISK LOST — three super-Eddington blowouts", 2.0)
		_end_run(false)
	else:
		_show_banner(
			"DISK DISRUPTED (%d/%d)\nFeed reset — rebuild integrity before pushing λ past 1 again."
			% [_disruptions, MAX_DISRUPTIONS],
			3.5
		)


func _end_run(victory: bool) -> void:
	_phase = RunPhase.ENDED
	_victory = victory
	_run_score = RunScore.compute(_mass, _milestones_hit, _disruptions, _sim_seconds / 31557600.0)
	var new_best := RunScore.save_best(_run_score)
	if new_best:
		_best_score = _run_score
	run_overlay.visible = true
	run_title.text = "VICTORY — M87* reached" if victory else "RUN OVER — disk destroyed"
	run_body.text = (
		"[b]Score[/b]  [color=yellow]%d[/color]   best [color=cyan]%d[/color]\n"
		% [_run_score, _best_score]
		+ "  mass [color=cyan]%s[/color]\n" % HudFormat.mass_msun(_mass)
		+ "  milestones %d · disruptions %d\n" % [_milestones_hit, _disruptions]
		+ "  sim time %s\n\n" % HudFormat.years(_sim_seconds)
		+ "[color=gray]R or Enter — new run · 1/2/3 — challenge preset[/color]"
	)


func _update_class() -> void:
	var cls := "Stellar-mass black hole"
	if _mass >= 1.0e8:
		cls = "Supermassive black hole"
	elif _mass >= 1.0e5:
		cls = "Seed supermassive black hole"
	elif _mass >= 1.0e2:
		cls = "Intermediate-mass black hole"
	if cls != _class_name:
		if _class_name != "" and _phase == RunPhase.PLAYING:
			_show_banner("RECLASSIFIED — %s" % cls, 2.0)
		_class_name = cls


func _next_milestone() -> Dictionary:
	for m in MILESTONES:
		if m.mass > _mass:
			return m
	return {"mass": MILESTONES[-1].mass, "name": "%s (reached)" % MILESTONES[-1].name}


func _live_score() -> int:
	return RunScore.compute(_mass, _milestones_hit, _disruptions, _sim_seconds / 31557600.0)


func _update_camera(delta: float) -> void:
	_idle_time += delta
	if _idle_time > IDLE_BEFORE_AUTORBIT and not _dragging:
		_target_yaw += AUTORBIT_SPEED * delta
	var k := 1.0 - exp(-delta * CAM_SMOOTH)
	_cam_yaw = lerp(_cam_yaw, _target_yaw, k)
	_cam_pitch = lerp(_cam_pitch, _target_pitch, k)
	_cam_dist = lerp(_cam_dist, _target_dist, k)
	_update_camera_transform()


func _update_camera_transform() -> void:
	var offset := Vector3(
		_cam_dist * cos(_cam_pitch) * sin(_cam_yaw),
		_cam_dist * sin(_cam_pitch) + 2.0,
		_cam_dist * cos(_cam_pitch) * cos(_cam_yaw)
	)
	camera.position = offset
	camera.look_at(Vector3.ZERO, Vector3.UP)


func _drive_graphics() -> void:
	var mat: ShaderMaterial = black_hole.get("disk_material")
	if mat == null:
		return
	var spin: float = black_hole.get("spin")
	var isco_rg: float = black_hole.call("isco_in_rg")
	var horizon_rg := 1.0 + sqrt(max(1.0 - spin * spin, 0.0))
	var f_qpo: float = black_hole.call("isco_orbital_frequency_hz")

	mat.set_shader_parameter("inner_color", black_hole.call("disk_color_at", 1.0))
	mat.set_shader_parameter("disc_color", black_hole.call("disk_color_at", GRADIENT_OUTER_RISCO))
	mat.set_shader_parameter("disc_inner_radius", clamp(isco_rg / OUTER_RG, 0.05, 0.6))
	mat.set_shader_parameter("ss_radius", clamp(horizon_rg / OUTER_RG, 0.02, 0.3))

	var t_in: float = black_hole.call("disk_inner_temp_k")
	var log_t: float = clamp(log(max(t_in, 1.0)) / log(10.0), 4.0, 7.5)
	mat.set_shader_parameter("emission_strength", remap(log_t, 4.0, 7.5, 0.6, 3.2))
	mat.set_shader_parameter("disc_speed", clamp(log(max(f_qpo, 1.0e-12)) / log(10.0) + 2.5, 0.8, 4.0))
	mat.set_shader_parameter("qpo_phase_rate", clamp(f_qpo * 0.02, 0.4, 6.0))

	disk_mesh.scale = Vector3.ONE * DISK_BASE_SCALE * (1.0 + 0.12 * _class_index())


func _class_index() -> int:
	if _mass >= 1.0e8:
		return 3
	if _mass >= 1.0e5:
		return 2
	if _mass >= 1.0e2:
		return 1
	return 0


func _refresh_hud() -> void:
	var m: float = black_hole.get("mass_solar")
	var mdot: float = black_hole.get("mdot_gs")
	var spin: float = black_hole.get("spin")
	var eta: float = black_hole.get("efficiency")
	var l_edd: float = black_hole.call("l_eddington")
	var l_bol: float = black_hole.call("luminosity_erg_s")
	var lam: float = black_hole.call("eddington_ratio")
	var isco_rg: float = black_hole.call("isco_in_rg")
	var r_s: float = black_hole.call("schwarzschild_radius_cm")
	var t_in: float = black_hole.call("disk_inner_temp_k")
	var f_qpo: float = black_hole.call("isco_orbital_frequency_hz")
	var t_salpeter: float = black_hole.call("salpeter_time_s")
	var mdot_edd: float = black_hole.call("mdot_at_eddington")
	var c: Color = black_hole.call("disk_inner_color")

	swatch.color = c
	title_label.text = "Accretion — %s" % _preset_name
	class_label.text = _class_name
	score_label.text = "Score %d  ·  best %d  ·  disruptions %d/%d" % [
		_live_score(), _best_score, _disruptions, MAX_DISRUPTIONS
	]

	var next: Dictionary = _next_milestone()
	milestone_label.text = "Next: %s  (%s)" % [next.name, HudFormat.mass_msun(next.mass)]
	milestone_bar.value = clamp(log(_mass) / log(next.mass), 0.0, 1.0)

	integrity_bar.value = _integrity
	integrity_bar.modulate = Color(1.0, 0.4, 0.25) if _integrity < 0.35 else Color(0.4, 0.9, 1.0)

	var super_edd := lam > 1.0
	if super_edd and not _was_super_eddington and _phase == RunPhase.PLAYING:
		push_warning("[accretion] super-Eddington: λ=%.2f" % lam)
	_was_super_eddington = super_edd

	warning_label.visible = super_edd and _phase == RunPhase.PLAYING
	warning_label.text = "SUPER-EDDINGTON — λ = %s\nIntegrity draining." % HudFormat.lambda_edd(lam)

	stats_label.text = (
		"[b]Black hole[/b]   [color=gray]sim t = %s[/color]\n" % HudFormat.years(_sim_seconds)
		+ "  mass M = [color=cyan]%s[/color]\n" % HudFormat.mass_msun(m)
		+ "  spin a/M = %.3f → η = [color=violet]%.1f%%[/color]\n" % [spin, eta * 100.0]
		+ "  ISCO = %.2f R_g   r_s = %s\n" % [isco_rg, HudFormat.cm(r_s)]
		+ "  e-fold @ λ=1 = %s\n\n" % HudFormat.years(t_salpeter)
		+ "[b]Accretion[/b]\n"
		+ "  feed Ṁ = [color=yellow]%s[/color]\n" % HudFormat.grams_per_s(mdot)
		+ "  λ-safe Ṁ = [color=lightgreen]%s[/color]  (λ = 1 ceiling)\n" % HudFormat.grams_per_s(mdot_edd)
		+ "  L = %s   L_Edd = %s\n" % [HudFormat.erg_per_s(l_bol), HudFormat.erg_per_s(l_edd)]
		+ "  λ = [color=%s]%s[/color]\n\n" % ["red" if super_edd else "lightgreen", HudFormat.lambda_edd(lam)]
		+ "[b]Inner edge[/b]\n"
		+ "  T = [color=orange]%s[/color]   QPO f = %s\n" % [HudFormat.kelvin(t_in), HudFormat.hertz(f_qpo)]
	)

	if _phase == RunPhase.ENDED:
		help_label.text = "R or Enter — new run · 1/2/3 — challenge preset"
	else:
		help_label.text = "Q/E mass · Z/X feed · A/D spin · 1/2/3 presets · R restart · drag · scroll"


func _set_slider_silent(slider: HSlider, value: float) -> void:
	_setting_slider = true
	slider.value = value
	_setting_slider = false


func _show_banner(text: String, seconds: float) -> void:
	banner.text = text
	banner.visible = true
	_banner_time = seconds
