extends Node3D
## Seeded per-sector debris — dense clusters. Spec: wiki/features/F005-seeded-sector-debris.md

const WorldScale = preload("res://scripts/world_scale.gd")
const DEBRIS_SCENE := preload("res://scenes/harvestable_debris.tscn")

@export var ship_path: NodePath = ^"../ShipBody"
@export var run_state_path: NodePath = ^"../RunState"
@export var clusters_per_sector_min := 4
@export var clusters_per_sector_max := 7
@export var rocks_per_cluster_min := 8
@export var rocks_per_cluster_max := 16
@export var cluster_radius := 150.0
@export var debris_mass_min := 15.0
@export var debris_mass_max := 55.0
@export var sector_margin := 80.0
@export var mass_dist_multiplier := 0.15
@export var size_near_bh_multiplier := 1.35

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
	var dist: int = WorldScale.chebyshev_from_origin(sector)
	var mass_scale: float = 1.0 + mass_dist_multiplier * float(dist)
	var size_scale: float = lerpf(1.0, 1.45, clampf(float(dist) / 6.0, 0.0, 1.0))
	var toward_bh: float = clampf(inverse_lerp(0.0, -3.0, float(sector.z)), 0.0, 1.0)
	size_scale *= lerpf(1.0, size_near_bh_multiplier, toward_bh)
	if dist == 0:
		mass_scale *= 1.35
	var half: float = WorldScale.SECTOR_EDGE_UNITS * 0.5 - sector_margin
	var origin := Vector3(sector) * WorldScale.SECTOR_EDGE_UNITS
	var cluster_count: int = rng.randi_range(clusters_per_sector_min, clusters_per_sector_max)
	for _c in cluster_count:
		var center := origin + Vector3(
			rng.randf_range(-half, half),
			rng.randf_range(-half * 0.35, half * 0.35),
			rng.randf_range(-half, half),
		)
		var rocks: int = rng.randi_range(rocks_per_cluster_min, rocks_per_cluster_max)
		for _i in rocks:
			var offset := Vector3(
				rng.randf_range(-cluster_radius, cluster_radius),
				rng.randf_range(-cluster_radius * 0.35, cluster_radius * 0.35),
				rng.randf_range(-cluster_radius, cluster_radius),
			)
			var debris = DEBRIS_SCENE.instantiate()
			add_child(debris)
			debris.global_position = center + offset
			debris.mass = rng.randf_range(debris_mass_min, debris_mass_max) * mass_scale
			var visual: Node = debris.get_node_or_null("DebrisVisual")
			if visual != null:
				visual.set("target_size", 12.0 * size_scale * rng.randf_range(0.75, 1.25))
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


func _sector_key(sector: Vector3i) -> String:
	return "%d,%d,%d" % [sector.x, sector.y, sector.z]
