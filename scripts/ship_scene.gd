extends Node3D
## F001–F003 scene root: flight, tractor, cargo, navigation HUD.

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var ship: Node3D = $ShipBody
@onready var cargo: Node = $CargoHold
@onready var tractor: Node3D = $ShipBody/TractorBeam
@onready var navigation: Node = $NavigationSystem
@onready var speed_label: Label = $UI/Panel/Margin/VBox/SpeedLabel
@onready var mode_label: Label = $UI/Panel/Margin/VBox/ModeLabel
@onready var cargo_label: Label = $UI/Panel/Margin/VBox/CargoLabel
@onready var tractor_label: Label = $UI/Panel/Margin/VBox/TractorLabel
@onready var nav_label: Label = $UI/Panel/Margin/VBox/NavLabel
@onready var compass_label: Label = $UI/Panel/Margin/VBox/CompassLabel
@onready var help_label: Label = $UI/Panel/Margin/VBox/HelpLabel


func _ready() -> void:
	ship.add_to_group("player_ship")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_ui_mouse_ignore($UI)
	if ship.has_signal("speed_band_changed"):
		ship.speed_band_changed.connect(_on_speed_band_changed)
	if ship.has_signal("auto_level_changed"):
		ship.auto_level_changed.connect(_on_auto_level_changed)
	if cargo.has_signal("cargo_changed"):
		cargo.cargo_changed.connect(_on_cargo_changed)
	if tractor.has_signal("target_changed"):
		tractor.target_changed.connect(_on_tractor_target_changed)
	if tractor.has_signal("collected"):
		tractor.collected.connect(_on_collected)
	if navigation.has_signal("nav_updated"):
		navigation.nav_updated.connect(_on_nav_updated)
	_refresh_hud()
	print(
		"[Ship] WASD/Arrows thrust · Mouse steer · Shift cruise · "
		+ "Radar bottom-right · Hold F tractor · Esc releases mouse"
	)


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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if not is_instance_valid(ship):
		return
	var spd: float = ship.velocity.length()
	var cap: float = ship.max_speed()
	speed_label.text = "Speed %s / %s" % [
		WorldScale.format_distance(spd),
		WorldScale.format_distance(cap),
	]
	if navigation.has_method("sector_label"):
		nav_label.text = "%s · %s" % [navigation.sector_label(), navigation.position_label()]
	_update_tractor_label()


func _on_nav_updated(name: String, dist: float, bearing: float) -> void:
	if name == "none":
		compass_label.text = "Compass: no debris tracked"
		return
	compass_label.text = "Nearest %s · %s · bearing %03d°" % [
		name,
		WorldScale.format_distance(dist),
		int(round(bearing)),
	]


func _on_speed_band_changed(_band: int) -> void:
	_refresh_hud()


func _on_auto_level_changed(_enabled: bool) -> void:
	_refresh_hud()


func _on_cargo_changed(current: float, maximum: float) -> void:
	cargo_label.text = "Cargo %.0f / %.0f u" % [current, maximum]
	_refresh_hud()


func _on_tractor_target_changed(_debris: Node3D) -> void:
	_update_tractor_label()


func _on_collected(mass: float, material_id: String) -> void:
	tractor_label.text = "Collected +%.0f %s" % [mass, material_id]
	_update_tractor_label()


func _update_tractor_label() -> void:
	if cargo.is_full():
		tractor_label.text = "Tractor: cargo full"
		return
	if tractor.active_target != null:
		var d: float = ship.global_position.distance_to(tractor.active_target.global_position)
		tractor_label.text = "Tractor: %s · %s" % [
			tractor.active_target.material_id,
			WorldScale.format_distance(d),
		]
	elif Input.is_action_pressed("ship_tractor") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		tractor_label.text = "Tractor: no target in cone"
	else:
		tractor_label.text = "Tractor: hold F"


func _refresh_hud() -> void:
	var band_text := "CRUISE" if ship.speed_band == ship.SpeedBand.CRUISE else "IMPULSE"
	mode_label.text = "Band: %s · Auto-level: %s" % [band_text, "ON" if ship.auto_level_enabled else "OFF"]
	cargo_label.text = "Cargo %.0f / %.0f u" % [cargo.current_mass, cargo.max_cargo_mass]
	help_label.text = (
		"WASD/Arrows move · Space/C vertical · Q/E roll · Mouse aim · RMB look\n"
		+ "Shift cruise · F tractor · L auto-level · Esc mouse · Radar = true layout"
	)
