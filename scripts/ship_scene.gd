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
var _run_seed: int = 1


func _ready() -> void:
	add_to_group("gameplay_root")
	ship.add_to_group("player_ship")
	if Settings:
		ship.auto_level_enabled = Settings.auto_level_default
	_apply_settings_to_ship()
	if Settings:
		Settings.settings_changed.connect(_apply_settings_to_ship)
	if ship.has_signal("speed_band_changed"):
		ship.speed_band_changed.connect(_on_speed_band_changed)
		_on_speed_band_changed(ship.speed_band)
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
	_run_seed = seed
	if run_state.has_method("set_run_seed"):
		run_state.set_run_seed(seed)
	if run_objectives.has_method("reset"):
		run_objectives.reset()


func restore_run(snapshot: Dictionary) -> void:
	_run_seed = int(snapshot.get("seed", 1))
	if run_state.has_method("set_run_seed"):
		run_state.set_run_seed(_run_seed)
	if progression.has_method("restore_state"):
		progression.restore_state(snapshot.get("progression", {}))
	if run_objectives.has_method("restore_state"):
		run_objectives.restore_state(snapshot.get("objectives", {}))
	if cargo.has_method("set_max_mass") and progression.has_method("cargo_capacity"):
		cargo.set_max_mass(progression.cargo_capacity())
	var held: float = float(snapshot.get("cargo_current", 0.0))
	if cargo.has_method("try_add"):
		cargo.clear_all()
		cargo.try_add(held)
	var pos := Vector3(
		float(snapshot.get("ship_x", 0.0)),
		float(snapshot.get("ship_y", 0.0)),
		float(snapshot.get("ship_z", 0.0)),
	)
	ship.global_position = pos
	RunTracker.begin_run(_run_seed)
	RunTracker.elapsed_sec = float(snapshot.get("elapsed_sec", 0.0))
	var obj: Dictionary = snapshot.get("objectives", {})
	RunTracker.max_chebyshev = int(obj.get("max_sector_ring", obj.get("max_ring", 0)))
	RunTracker.note_approach_zone(int(obj.get("max_approach_zone", 0)))
	var closest: float = float(snapshot.get("closest_bh_km", -1.0))
	if closest > 0.0:
		RunTracker.note_bh_distance(closest)


func export_snapshot() -> Dictionary:
	var snap := {
		"seed": _run_seed,
		"ship_x": ship.global_position.x,
		"ship_y": ship.global_position.y,
		"ship_z": ship.global_position.z,
		"cargo_current": cargo.current_mass if cargo != null else 0.0,
		"elapsed_sec": RunTracker.elapsed_sec,
	}
	if progression.has_method("export_state"):
		snap["progression"] = progression.export_state()
	if run_objectives.has_method("export_state"):
		snap["objectives"] = run_objectives.export_state()
	snap["closest_bh_km"] = RunTracker.closest_bh_km
	return snap


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


func _on_speed_band_changed(band) -> void:
	var label := "CRUISE" if int(band) == 1 else "IMPULSE"
	GameEvents.speed_band_changed.emit(label)


func persist_run() -> void:
	if not GameState.is_playing():
		return
	SessionSave.save_active_run(export_snapshot())
