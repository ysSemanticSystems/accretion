extends Node
## BH approach milestones + sector exploration feedback. Spec: F012.

const WorldScale = preload("res://scripts/world_scale.gd")

@export var run_state_path: NodePath = ^"../RunState"
@export var ship_path: NodePath = ^"../ShipBody"

var max_approach_zone: int = 0
var max_sector_ring: int = 0

var _run_state: Node
var _ship: Node3D


func _ready() -> void:
	_run_state = get_node_or_null(run_state_path)
	_ship = get_node_or_null(ship_path) as Node3D
	if _run_state != null and _run_state.has_signal("sector_depleted"):
		_run_state.sector_depleted.connect(_on_sector_depleted)


func reset() -> void:
	max_approach_zone = 0
	max_sector_ring = 0
	_emit_milestone()


func restore_state(data: Dictionary) -> void:
	max_approach_zone = int(data.get("max_approach_zone", 0))
	max_sector_ring = int(data.get("max_sector_ring", 0))
	_emit_milestone()
	RunTracker.note_approach_zone(max_approach_zone)


func export_state() -> Dictionary:
	return {
		"max_approach_zone": max_approach_zone,
		"max_sector_ring": max_sector_ring,
	}


func _process(_delta: float) -> void:
	if _ship == null:
		return
	_update_bh_approach(_ship.global_position)
	_update_sector_ring(_ship.global_position)


func _update_bh_approach(pos: Vector3) -> void:
	var dist_km: float = WorldScale.distance_to_bh_km(pos)
	RunTracker.note_bh_distance(dist_km)
	var zone: int = WorldScale.approach_zone_for_distance(dist_km)
	if zone <= max_approach_zone:
		return
	max_approach_zone = zone
	RunTracker.note_approach_zone(max_approach_zone)
	_emit_milestone()
	var label: String = WorldScale.approach_zone_label(zone)
	GameEvents.toast.emit(
		"M87* · %s (%s)"
		% [label, WorldScale.format_distance(dist_km * WorldScale.UNITS_PER_KM)]
	)


func _update_sector_ring(pos: Vector3) -> void:
	var sector: Vector3i = WorldScale.sector_coords(pos)
	var ring: int = WorldScale.chebyshev_from_origin(sector)
	if ring <= max_sector_ring:
		return
	max_sector_ring = ring
	GameEvents.toast.emit("Sector ring %d — debris fields extend further out here" % ring)


func _on_sector_depleted(sector: Vector3i) -> void:
	GameEvents.sector_depleted.emit(sector)
	GameEvents.toast.emit(
		"Sector (%d, %d, %d) cleared — keep exploring"
		% [sector.x, sector.y, sector.z]
	)


func _emit_milestone() -> void:
	var next_zone: int = WorldScale.next_approach_zone(max_approach_zone)
	GameEvents.milestone_updated.emit(
		max_approach_zone,
		next_zone,
		WorldScale.APPROACH_ZONE_COUNT,
	)
