extends Node
## Outward sector ring goals and depletion feedback. Spec: wiki/game-design/resource-loop.md

const WorldScale = preload("res://scripts/world_scale.gd")

@export var run_state_path: NodePath = ^"../RunState"
@export var ship_path: NodePath = ^"../ShipBody"

var sector_goal: int = 1

var _run_state: Node
var _ship: Node3D
var _max_ring: int = 0


func _ready() -> void:
	_run_state = get_node_or_null(run_state_path)
	_ship = get_node_or_null(ship_path) as Node3D
	if _run_state != null and _run_state.has_signal("sector_depleted"):
		_run_state.sector_depleted.connect(_on_sector_depleted)


func reset() -> void:
	sector_goal = 1
	_max_ring = 0
	GameEvents.sector_goal_changed.emit(sector_goal)


func _process(_delta: float) -> void:
	if _ship == null:
		return
	var sector: Vector3i = WorldScale.sector_coords(_ship.global_position)
	var ring: int = _chebyshev(sector)
	if ring <= _max_ring:
		return
	_max_ring = ring
	if _max_ring >= sector_goal:
		var reached: int = sector_goal
		sector_goal = _max_ring + 1
		GameEvents.sector_ring_reached.emit(reached, sector_goal)
		GameEvents.sector_goal_changed.emit(sector_goal)
		GameEvents.toast.emit("Ring %d reached — aim for ring %d" % [reached, sector_goal])


func _on_sector_depleted(sector: Vector3i) -> void:
	GameEvents.sector_depleted.emit(sector)
	GameEvents.toast.emit(
		"Sector (%d, %d, %d) cleared — push outward" % [sector.x, sector.y, sector.z]
	)


func _chebyshev(sector: Vector3i) -> int:
	return WorldScale.chebyshev_from_origin(sector)
