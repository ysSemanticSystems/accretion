extends Node3D
## Seeded per-sector debris generation (lite). Spec: wiki/features/F005-seeded-sector-debris.md

const WorldScale = preload("res://scripts/world_scale.gd")
const DEBRIS_SCENE := preload("res://scenes/harvestable_debris.tscn")

@export var ship_path: NodePath = ^"../ShipBody"
@export var run_state_path: NodePath = ^"../RunState"
@export var debris_per_sector_min := 8
@export var debris_per_sector_max := 14
@export var debris_mass_min := 15.0
@export var debris_mass_max := 55.0
@export var sector_margin := 80.0
@export var mass_dist_multiplier := 0.15

var _ship: Node3D
var _run_state: Node
var _active_sector := Vector3i(999999, 999999, 999999)
var _spawned_sectors: Dictionary = {}


func _ready() -> void:
	_ship = get_node_or_null(ship_path) as Node3D
	_run_state = get_node_or_null(run_state_path)


func _process(_delta: float) -> void:
	if _ship == null or _run_state == null:
		return
	var sector: Vector3i = WorldScale.sector_coords(_ship.global_position)
	if sector == _active_sector:
		return
	_active_sector = sector
	_ensure_sector(sector)


func _on_debris_collected(_mass: float, _material: String, debris: Node3D) -> void:
	var sector: Vector3i = WorldScale.sector_coords(debris.global_position)
	call_deferred("_check_depletion", sector)


func _check_depletion(sector: Vector3i) -> void:
	if not _sector_has_harvestables(sector):
		_run_state.mark_depleted(sector)


func _ensure_sector(sector: Vector3i) -> void:
	var key := _sector_key(sector)
	if _spawned_sectors.has(key):
		return
	_spawned_sectors[key] = true
	if _run_state.is_depleted(sector):
		return
	_spawn_sector(sector)


func _spawn_sector(sector: Vector3i) -> void:
	var rng: RandomNumberGenerator = _run_state.sector_rng(sector)
	var count: int = rng.randi_range(debris_per_sector_min, debris_per_sector_max)
	var dist: int = _chebyshev(sector)
	var mass_scale: float = 1.0 + mass_dist_multiplier * float(dist)
	if dist == 0:
		count = maxi(count, 12)
		mass_scale *= 1.35
	var half: float = WorldScale.SECTOR_EDGE_UNITS * 0.5 - sector_margin
	var origin := Vector3(sector) * WorldScale.SECTOR_EDGE_UNITS
	for i in count:
		var debris = DEBRIS_SCENE.instantiate()
		add_child(debris)
		var pos := origin + Vector3(
			rng.randf_range(-half, half),
			rng.randf_range(-half * 0.4, half * 0.4),
			rng.randf_range(-half, half),
		)
		debris.global_position = pos
		debris.mass = rng.randf_range(debris_mass_min, debris_mass_max) * mass_scale
		if debris.has_signal("collected"):
			debris.collected.connect(_on_debris_collected.bind(debris))


func _sector_has_harvestables(sector: Vector3i) -> bool:
	var origin := Vector3(sector) * WorldScale.SECTOR_EDGE_UNITS
	var half: float = WorldScale.SECTOR_EDGE_UNITS * 0.5
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var local: Vector3 = node.global_position - origin
		if absf(local.x) <= half and absf(local.y) <= half and absf(local.z) <= half:
			return true
	return false


func _chebyshev(sector: Vector3i) -> int:
	return maxi(absi(sector.x), maxi(absi(sector.y), absi(sector.z)))


func _sector_key(sector: Vector3i) -> String:
	return "%d,%d,%d" % [sector.x, sector.y, sector.z]
