extends Node
## Origin home depot — auto-deposit in range; opens upgrade dock when banked. Spec: wiki/features/F004-home-depot-progression.md

const WorldScale = preload("res://scripts/world_scale.gd")

signal deposited(mass: float)

@export var deposit_radius := WorldScale.DEPOT_RADIUS_UNITS
@export var depot_position := Vector3.ZERO
@export var ship_path: NodePath = ^"../ShipBody"
@export var cargo_path: NodePath = ^"../CargoHold"
@export var progression_path: NodePath = ^"../Progression"

var _ship: Node3D
var _cargo: Node
var _progression: Node
var _was_at_depot := false
var _upgrade_shown_this_dock := false


func _ready() -> void:
	deposit_radius = WorldScale.DEPOT_RADIUS_UNITS
	_ship = get_node_or_null(ship_path) as Node3D
	_cargo = get_node_or_null(cargo_path)
	_progression = get_node_or_null(progression_path)


func is_at_depot() -> bool:
	if _ship == null:
		return false
	return _ship.global_position.distance_to(depot_position) <= deposit_radius


func _process(_delta: float) -> void:
	if _ship == null or _cargo == null or _progression == null:
		return
	var at := is_at_depot()
	if at != _was_at_depot:
		GameEvents.depot_docked.emit(at)
		if at:
			_upgrade_shown_this_dock = false
		else:
			_upgrade_shown_this_dock = false
	_was_at_depot = at
	if not at:
		return
	var held: float = _cargo.current_mass
	if held > 0.01:
		_try_deposit(held)
		return
	if not _upgrade_shown_this_dock and _progression.banked_mass > 0.0:
		_upgrade_shown_this_dock = true
		var root := get_parent()
		if root != null and root.has_method("open_upgrade_dock"):
			root.open_upgrade_dock()


func _try_deposit(mass: float) -> void:
	_cargo.clear_all()
	_progression.add_banked(mass)
	deposited.emit(mass)
	GameEvents.mass_banked.emit(_progression.banked_mass, mass)
	GameEvents.toast.emit("Deposited %.0f u" % mass)
	if AudioManager:
		AudioManager.play_sfx(_deposit_chunk())
	RunTracker.note_banked(_progression.banked_mass, mass)
	var root := get_parent()
	if root != null and root.has_method("persist_run"):
		root.persist_run()
	if not _upgrade_shown_this_dock and _progression.banked_mass > 0.0:
		_upgrade_shown_this_dock = true
		if root != null and root.has_method("open_upgrade_dock"):
			root.call_deferred("open_upgrade_dock")


func _deposit_chunk() -> AudioStream:
	return AudioManager.make_tone(196.0, 0.12, 0.14)
