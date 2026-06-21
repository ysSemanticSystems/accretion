extends Node
## Tracks POIs, sector grid, and nearest-target bearings (presentation only).
## Spec: wiki/features/F003-navigation-radar.md

const WorldScale = preload("res://scripts/world_scale.gd")

signal nav_updated(nearest_name: String, nearest_dist: float, nearest_bearing_deg: float)

@export var ship_path: NodePath = ^"../ShipBody"

var ship: Node3D


func _ready() -> void:
	ship = get_node_or_null(ship_path) as Node3D


func _process(_delta: float) -> void:
	if ship == null:
		return
	var nearest := _nearest_harvestable()
	if nearest.is_empty():
		nav_updated.emit("none", INF, 0.0)
		return
	var offset: Vector3 = nearest.pos - ship.global_position
	var bearing: float = rad_to_deg(atan2(offset.x, -offset.z))
	if bearing < 0.0:
		bearing += 360.0
	nav_updated.emit(nearest.name, offset.length(), bearing)


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
	var out: Array[Dictionary] = []
	if ship == null:
		return out
	var origin: Vector3 = ship.global_position
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var offset: Vector3 = node.global_position - origin
		var dist: float = offset.length()
		if dist > WorldScale.RADAR_RANGE_UNITS:
			continue
		out.append({
			"pos": offset,
			"dist": dist,
			"kind": node.material_id,
		})
	return out


func _nearest_harvestable() -> Dictionary:
	if ship == null:
		return {}
	var best_dist: float = INF
	var best: Dictionary = {}
	var origin: Vector3 = ship.global_position
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var dist: float = origin.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			var kind: String = node.material_id
			best = {"name": kind, "pos": node.global_position, "node": node}
	return best
