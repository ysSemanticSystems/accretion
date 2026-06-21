extends Node
## Tracks POIs, sector grid, and navigation objective bearings (presentation only).
## Spec: wiki/features/F003-navigation-radar.md, F004-home-depot-progression.md

const WorldScale = preload("res://scripts/world_scale.gd")

signal nav_updated(objective_name: String, objective_dist: float, objective_bearing_deg: float)

@export var ship_path: NodePath = ^"../ShipBody"
@export var cargo_path: NodePath = ^"../CargoHold"
@export var depot_position := Vector3.ZERO

var ship: Node3D
var _cargo: Node
var _cached_pois: Array[Dictionary] = []
var _cached_nearest: Dictionary = {}


func _ready() -> void:
	ship = get_node_or_null(ship_path) as Node3D
	_cargo = get_node_or_null(cargo_path)


func _process(_delta: float) -> void:
	if ship == null:
		return
	_rescan_harvestables()
	var objective := navigation_objective()
	if objective.is_empty():
		nav_updated.emit("none", INF, 0.0)
		return
	var offset: Vector3 = objective.pos - ship.global_position
	var bearing: float = rad_to_deg(atan2(offset.x, -offset.z))
	if bearing < 0.0:
		bearing += 360.0
	nav_updated.emit(objective.name, offset.length(), bearing)


func navigation_objective() -> Dictionary:
	if ship == null:
		return {}
	if _cargo != null and _cargo.current_mass > 0.01:
		return {"name": "depot", "pos": depot_position}
	return _cached_nearest


func ship_heading_deg() -> float:
	if ship == null:
		return 0.0
	var forward := -ship.global_transform.basis.z
	return rad_to_deg(atan2(forward.x, -forward.z))


func sector_label() -> String:
	if ship == null:
		return "sector ?"
	var s: Vector3i = WorldScale.sector_coords(ship.global_position)
	return "Sector (%d, %d, %d)" % [s.x, s.y, s.z]


func position_label() -> String:
	if ship == null:
		return ""
	return WorldScale.format_position(ship.global_position)


func radar_pois() -> Array[Dictionary]:
	return _cached_pois


func _rescan_harvestables() -> void:
	_cached_pois.clear()
	_cached_nearest.clear()
	if ship == null:
		return
	var best_dist: float = INF
	var origin: Vector3 = ship.global_position
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var offset: Vector3 = node.global_position - origin
		var dist: float = offset.length()
		if dist <= WorldScale.RADAR_RANGE_UNITS:
			_cached_pois.append({
				"pos": offset,
				"dist": dist,
				"kind": node.material_id,
			})
			if dist < best_dist:
				best_dist = dist
				_cached_nearest = {
					"name": node.material_id,
					"pos": node.global_position,
					"node": node,
				}
