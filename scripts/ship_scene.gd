extends Node3D
## Scene root — flight, tractor, depot loop with human-centric HUD.

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var ship: Node3D = $ShipBody
@onready var cargo: Node = $CargoHold
@onready var tractor: Node3D = $ShipBody/TractorBeam
@onready var navigation: Node = $NavigationSystem
@onready var progression: Node = $Progression
@onready var home_depot: Node = $HomeDepot
@onready var collect_feedback: Node = $CollectFeedback

@onready var mission_label: Label = $UI/HudPanel/Margin/VBox/MissionLabel
@onready var compass_label: Label = $UI/HudPanel/Margin/VBox/CompassLabel
@onready var cargo_bar: ProgressBar = $UI/HudPanel/Margin/VBox/CargoRow/CargoBar
@onready var cargo_text: Label = $UI/HudPanel/Margin/VBox/CargoRow/CargoText
@onready var bank_label: Label = $UI/HudPanel/Margin/VBox/BankLabel
@onready var upgrade_label: Label = $UI/HudPanel/Margin/VBox/UpgradeLabel
@onready var hint_label: Label = $UI/HudPanel/Margin/VBox/HintLabel

var _hint_visible_until: float = 0.0


func _ready() -> void:
	ship.add_to_group("player_ship")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_ui_mouse_ignore($UI)
	_hint_visible_until = Time.get_ticks_msec() / 1000.0 + 45.0
	if cargo.has_signal("cargo_changed"):
		cargo.cargo_changed.connect(_on_cargo_changed)
	if tractor.has_signal("collected"):
		tractor.collected.connect(_on_collected)
	if navigation.has_signal("nav_updated"):
		navigation.nav_updated.connect(_on_nav_updated)
	if progression.has_signal("progression_changed"):
		progression.progression_changed.connect(_on_progression_changed)
	if home_depot.has_signal("deposited"):
		home_depot.deposited.connect(_on_deposited)
	_refresh_hud()
	call_deferred("_point_at_nearest_debris")


func _point_at_nearest_debris() -> void:
	await get_tree().process_frame
	if not navigation.has_method("radar_pois"):
		return
	var pois: Array = navigation.radar_pois()
	if pois.is_empty():
		return
	var nearest: Dictionary = pois[0]
	var best_dist: float = nearest.get("dist", INF)
	for poi in pois:
		if poi.dist < best_dist:
			best_dist = poi.dist
			nearest = poi
	if best_dist >= INF:
		return
	var offset: Vector3 = nearest.pos
	var flat := Vector2(offset.x, offset.z)
	if flat.length_squared() < 1.0:
		return
	var yaw: float = atan2(flat.x, flat.y)
	ship.rotation = Vector3(ship.rotation.x, yaw, ship.rotation.z)


func _set_ui_mouse_ignore(node: Node) -> void:
	if node is Control:
		var c := node as Control
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_set_ui_mouse_ignore(child)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	if event.is_action_pressed("ship_auto_level_toggle"):
		ship.toggle_auto_level()
	if event.is_action_pressed("ship_upgrade_cycle"):
		progression.cycle_upgrade_selection()
	if event.is_action_pressed("ship_upgrade_buy"):
		progression.try_purchase()


func _process(_delta: float) -> void:
	if not is_instance_valid(ship):
		return
	_refresh_hud()


func _on_nav_updated(name: String, dist: float, _bearing: float) -> void:
	if name == "none":
		compass_label.text = "Nothing on scope — explore outward"
		return
	if name == "depot":
		compass_label.text = "Home beacon · %s away" % WorldScale.format_distance(dist)
		return
	compass_label.text = "Nearest debris · %s away" % WorldScale.format_distance(dist)


func _on_deposited(_mass: float) -> void:
	_refresh_hud()


func _on_progression_changed() -> void:
	_refresh_hud()


func _on_cargo_changed(_current: float, _maximum: float) -> void:
	_refresh_hud()


func _on_collected(_mass: float, _material_id: String, world_pos: Vector3) -> void:
	if collect_feedback.has_method("play_at"):
		collect_feedback.play_at(world_pos, _mass, cargo_bar)
	_refresh_hud()


func _refresh_hud() -> void:
	var fill: float = cargo.fill_ratio() if cargo.has_method("fill_ratio") else 0.0
	cargo_bar.value = fill * 100.0
	cargo_text.text = "%.0f / %.0f in hold" % [cargo.current_mass, cargo.max_cargo_mass]
	bank_label.text = "Stored at home · %.0f u" % progression.banked_mass

	var loaded: bool = cargo.current_mass > 0.01
	var near_home: bool = ship.global_position.length() < 120.0

	if loaded:
		mission_label.text = "Head home — fly to the cyan beacon and unload"
	elif progression.banked_mass >= progression.selection_cost() and near_home:
		mission_label.text = "At home — press Y to upgrade, U to pick what"
	elif cargo.is_full():
		mission_label.text = "Hold is full — return to the cyan beacon"
	else:
		mission_label.text = "Hold F near orange debris — it pulls into your hold"

	var lvl: int = progression.selection_level()
	var cost: float = progression.selection_cost()
	if progression.banked_mass > 0.0 and near_home and lvl < progression.MAX_LEVEL and cost != INF:
		upgrade_label.text = "%s · %.0f u · Y to buy · U to change" % [
			progression.selection_label(),
			cost,
		]
		upgrade_label.visible = true
	elif lvl >= progression.MAX_LEVEL:
		upgrade_label.text = "Upgrades maxed for this run"
		upgrade_label.visible = progression.banked_mass > 0.0
	else:
		upgrade_label.visible = false

	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _hint_visible_until:
		hint_label.visible = true
		hint_label.text = "WASD fly · Shift boost · F collect · Esc frees cursor"
	else:
		hint_label.visible = false
