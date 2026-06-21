extends Node3D
## Gameplay scene root — systems only; HUD is GameHud.tscn. Spec: wiki/features/F008-game-shell.md

const WorldScale = preload("res://scripts/world_scale.gd")
const GAME_HUD := preload("res://scenes/ui/GameHud.tscn")

@onready var ship: Node3D = $ShipBody
@onready var cargo: Node = $CargoHold
@onready var tractor: Node3D = $ShipBody/TractorBeam
@onready var navigation: Node = $NavigationSystem
@onready var progression: Node = $Progression
@onready var home_depot: Node = $HomeDepot
@onready var collect_feedback: Node = $CollectFeedback
@onready var run_state: Node = $RunState
@onready var run_objectives: Node = $RunObjectives

var _hud: CanvasLayer


func _ready() -> void:
	add_to_group("gameplay_root")
	ship.add_to_group("player_ship")
	if Settings:
		ship.auto_level_enabled = Settings.auto_level_default
	_apply_settings_to_ship()
	if Settings:
		Settings.settings_changed.connect(_apply_settings_to_ship)
	_hud = GAME_HUD.instantiate()
	add_child(_hud)
	if _hud.has_method("bind_navigation"):
		_hud.bind_navigation(navigation)
	if collect_feedback.has_method("set_cargo_bar"):
		collect_feedback.set_cargo_bar(_hud.cargo_bar_ref())
	if tractor.has_signal("collected"):
		tractor.collected.connect(_on_tractor_collected)
	call_deferred("_point_at_nearest_debris")


func configure_run(seed: int) -> void:
	if run_state.has_method("set_run_seed"):
		run_state.set_run_seed(seed)
	if run_objectives.has_method("reset"):
		run_objectives.reset()


func _apply_settings_to_ship() -> void:
	if not Settings:
		return
	ship.mouse_sensitivity = Settings.mouse_sensitivity
	ship.invert_y = Settings.invert_y
	var cam: Camera3D = $ChaseCamera
	if cam:
		cam.fov_rest = Settings.fov_rest
		cam.fov_max = Settings.fov_max


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
	var target: Vector3 = ship.global_position + nearest.pos
	var flat_target := Vector3(target.x, ship.global_position.y, target.z)
	if ship.global_position.distance_squared_to(flat_target) < 0.01:
		return
	ship.look_at(flat_target, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.transition(GameState.State.PAUSED)
		return
	if event.is_action_pressed("ship_auto_level_toggle"):
		ship.toggle_auto_level()


func open_upgrade_dock() -> void:
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("show_upgrade_dock"):
		shell.show_upgrade_dock(progression)


func _on_tractor_collected(_mass: float, _material_id: String, world_pos: Vector3) -> void:
	if collect_feedback.has_method("play_at"):
		collect_feedback.play_at(world_pos, _mass)
