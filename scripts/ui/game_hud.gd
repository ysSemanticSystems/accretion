extends CanvasLayer
## Event-driven HUD shell. Spec: wiki/features/F010-hud-component.md

@onready var mission_label: Label = $HudPanel/Margin/VBox/MissionLabel
@onready var compass_label: Label = $HudPanel/Margin/VBox/CompassLabel
@onready var cargo_bar: ProgressBar = $HudPanel/Margin/VBox/CargoRow/CargoBar
@onready var cargo_text: Label = $HudPanel/Margin/VBox/CargoRow/CargoText
@onready var bank_label: Label = $HudPanel/Margin/VBox/BankLabel
@onready var hint_label: Label = $HudPanel/Margin/VBox/HintLabel
@onready var chevron: Control = $WaypointChevron
@onready var reticle: Control = $TractorReticle
@onready var toasts: Control = $ToastQueue
@onready var radar: Control = $RadarPanel/Radar

var _hint_until: float = 0.0
var _cargo_current: float = 0.0
var _cargo_max: float = 500.0
var _banked: float = 0.0
var _compass_kind := ""
var _compass_dist: float = INF
var _compass_pos := Vector3.ZERO
var _at_depot := false
var _sector_goal: int = 1


func _ready() -> void:
	_hint_until = Time.get_ticks_msec() / 1000.0 + 45.0
	if Settings:
		_apply_hud_scale()
		Settings.settings_changed.connect(_on_settings_changed)
	GameEvents.cargo_changed.connect(_on_cargo_changed)
	GameEvents.mass_banked.connect(_on_mass_banked)
	GameEvents.compass_target.connect(_on_compass_target)
	GameEvents.toast.connect(_on_toast)
	GameEvents.tractor_state_changed.connect(_on_tractor_state)
	GameEvents.depot_docked.connect(_on_depot_docked)
	GameEvents.sector_goal_changed.connect(_on_sector_goal_changed)
	_on_cargo_changed(0.0, _cargo_max)
	_update_mission()


func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	hint_label.visible = now < _hint_until
	if chevron.has_method("set_target"):
		chevron.set_target(_compass_pos, _compass_kind)


func bind_navigation(nav: Node) -> void:
	if radar.has_method("set_nav"):
		radar.set_nav(nav)


func cargo_bar_ref() -> ProgressBar:
	return cargo_bar


func _on_settings_changed() -> void:
	_apply_hud_scale()


func _apply_hud_scale() -> void:
	var s: float = Settings.hud_scale if Settings else 1.0
	transform = Transform2D().scaled(Vector2(s, s))


func _on_cargo_changed(current: float, maximum: float) -> void:
	_cargo_current = current
	_cargo_max = maximum
	cargo_bar.value = (current / max(maximum, 1.0)) * 100.0
	cargo_text.text = "%.0f / %.0f in hold" % [current, maximum]
	_update_mission()


func _on_mass_banked(total: float, _delta: float) -> void:
	_banked = total
	bank_label.text = "Stored at home · %.0f u" % total
	_update_mission()


func _on_compass_target(world_pos: Vector3, dist: float, kind: String) -> void:
	_compass_pos = world_pos
	_compass_dist = dist
	_compass_kind = kind
	if kind == "none" or dist >= INF:
		compass_label.text = "Nothing on scope — explore outward"
	elif kind == "depot":
		compass_label.text = "Home beacon · %s away" % _fmt_dist(dist)
	else:
		compass_label.text = "Nearest debris · %s away" % _fmt_dist(dist)


func _on_toast(text: String) -> void:
	if toasts.has_method("push"):
		toasts.push(text)


func _on_tractor_state(state: String) -> void:
	if reticle.has_method("set_state"):
		reticle.set_state(state)


func _on_depot_docked(at: bool) -> void:
	_at_depot = at
	_update_mission()


func _on_sector_goal_changed(goal: int) -> void:
	_sector_goal = goal
	_update_mission()


func _update_mission() -> void:
	if _at_depot and _banked > 0.01 and _cargo_current <= 0.01:
		mission_label.text = "Docked at home — upgrade screen open, or fly out for more debris"
	elif _cargo_current > 0.01:
		mission_label.text = "Head home — fly to the cyan beacon and unload"
	elif _cargo_max > 0.0 and _cargo_current >= _cargo_max - 0.01:
		mission_label.text = "Hold is full — return to the cyan beacon"
	else:
		mission_label.text = (
			"Hold F near orange debris — explore to sector ring %d for richer fields"
			% _sector_goal
		)


func _fmt_dist(units: float) -> String:
	const WorldScale = preload("res://scripts/world_scale.gd")
	return WorldScale.format_distance(units)
