extends CanvasLayer
## Event-driven HUD shell. Spec: wiki/features/F010-hud-component.md

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var mission_label: Label = $HudPanel/Margin/VBox/MissionLabel
@onready var milestone_label: Label = $HudPanel/Margin/VBox/MilestoneLabel
@onready var sector_label: Label = $HudPanel/Margin/VBox/SectorLabel
@onready var compass_label: Label = $HudPanel/Margin/VBox/CompassLabel
@onready var speed_label: Label = $HudPanel/Margin/VBox/SpeedLabel
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
var _max_zone: int = 0
var _next_zone: int = 1
var _zone_count: int = 4
var _nav: Node
var _inside_bh := false


func _ready() -> void:
	_hint_until = Time.get_ticks_msec() / 1000.0 + 45.0
	_zone_count = WorldScale.APPROACH_ZONE_COUNT
	if Settings:
		_apply_hud_scale()
		Settings.settings_changed.connect(_on_settings_changed)
	GameEvents.cargo_changed.connect(_on_cargo_changed)
	GameEvents.mass_banked.connect(_on_mass_banked)
	GameEvents.compass_target.connect(_on_compass_target)
	GameEvents.toast.connect(_on_toast)
	GameEvents.tractor_state_changed.connect(_on_tractor_state)
	GameEvents.depot_docked.connect(_on_depot_docked)
	GameEvents.milestone_updated.connect(_on_milestone_updated)
	GameEvents.speed_band_changed.connect(_on_speed_band_changed)
	GameEvents.bh_interior_changed.connect(_on_bh_interior_changed)
	_on_cargo_changed(0.0, _cargo_max)
	_update_milestone_label()
	_update_mission()


func _exit_tree() -> void:
	if Settings and Settings.settings_changed.is_connected(_on_settings_changed):
		Settings.settings_changed.disconnect(_on_settings_changed)
	GameEvents.cargo_changed.disconnect(_on_cargo_changed)
	GameEvents.mass_banked.disconnect(_on_mass_banked)
	GameEvents.compass_target.disconnect(_on_compass_target)
	GameEvents.toast.disconnect(_on_toast)
	GameEvents.tractor_state_changed.disconnect(_on_tractor_state)
	GameEvents.depot_docked.disconnect(_on_depot_docked)
	GameEvents.milestone_updated.disconnect(_on_milestone_updated)
	GameEvents.speed_band_changed.disconnect(_on_speed_band_changed)
	GameEvents.bh_interior_changed.disconnect(_on_bh_interior_changed)


func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	hint_label.visible = now < _hint_until
	if chevron.has_method("set_target"):
		chevron.set_target(_compass_pos, _compass_kind, _compass_dist)
	if _nav != null and _nav.has_method("sector_label"):
		sector_label.text = _nav.sector_label()


func bind_navigation(nav: Node) -> void:
	_nav = nav
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
		compass_label.text = "Nothing on scope — fly inward toward the warm core"
	elif kind == "depot":
		compass_label.text = "Home beacon · %s away" % _fmt_dist(dist)
	elif kind == "black_hole":
		compass_label.text = "M87* accretion disk · %s away" % _fmt_dist(dist)
	else:
		compass_label.text = "Nearest debris · %s away" % _fmt_dist(dist)


func _on_milestone_updated(max_zone: int, next_zone: int, zone_count: int) -> void:
	_max_zone = max_zone
	_next_zone = next_zone
	_zone_count = zone_count
	_update_milestone_label()
	_update_mission()


func _on_speed_band_changed(band: String) -> void:
	speed_label.text = "Drive · %s" % band


func _on_toast(text: String) -> void:
	if not is_inside_tree() or toasts == null or not is_instance_valid(toasts):
		return
	if toasts.has_method("push"):
		toasts.push(text)


func _on_tractor_state(state: String) -> void:
	if reticle.has_method("set_state"):
		reticle.set_state(state)


func _on_depot_docked(at: bool) -> void:
	_at_depot = at
	_update_mission()


func _on_bh_interior_changed(inside: bool) -> void:
	_inside_bh = inside
	if inside:
		_on_toast("Crossed the capture sphere — infall view")
	_update_mission()


func _update_milestone_label() -> void:
	var parts: PackedStringArray = []
	for zone in range(1, _zone_count + 1):
		if zone <= _max_zone:
			parts.append("●")
		elif zone == _next_zone:
			parts.append("◐")
		else:
			parts.append("○")
	var next_label := WorldScale.approach_zone_label(_next_zone)
	milestone_label.text = "M87* approach %s · next: %s" % [" ".join(parts), next_label]


func _update_mission() -> void:
	if _inside_bh:
		mission_label.text = "Inside the capture volume — no stable horizon; keep recording what you see"
	elif _max_zone >= _zone_count:
		mission_label.text = "Inside the disk plane — keep exploring, mapping, and hauling"
	elif _at_depot and _banked > 0.01 and _cargo_current <= 0.01:
		mission_label.text = "Docked at home — upgrade, then fly inward toward M87*"
	elif _cargo_current > 0.01:
		mission_label.text = "Head home — unload, then fly inward toward the accretion disk"
	elif _cargo_max > 0.0 and _cargo_current >= _cargo_max - 0.01:
		mission_label.text = "Hold is full — return to the cyan beacon"
	else:
		mission_label.text = (
			"Collect debris, upgrade at home, then fly inward — target: %s"
			% WorldScale.approach_zone_label(_next_zone)
		)


func _fmt_dist(units: float) -> String:
	return WorldScale.format_distance(units)
