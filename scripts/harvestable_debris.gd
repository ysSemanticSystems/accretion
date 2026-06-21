extends Node3D
## Loose debris harvestable by tractor. Spec: wiki/features/F002-tractor-cargo.md

const WorldScale = preload("res://scripts/world_scale.gd")

signal collected(mass: float, material_id: String)

@export var material_id := "volatiles"
@export var mass: float = 25.0
@export var drift_speed := 2.5

var velocity: Vector3 = Vector3.ZERO
var _active := true

var _mesh: MeshInstance3D
var _beacon: MeshInstance3D


func _ready() -> void:
	add_to_group("harvestable")
	add_to_group("nav_poi")
	velocity = Vector3(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4), randf_range(-1.0, 1.0))
	if velocity.length_squared() > 0.01:
		velocity = velocity.normalized() * drift_speed
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	_beacon = get_node_or_null("NavBeacon") as MeshInstance3D


func _process(delta: float) -> void:
	if not _active:
		return
	global_position += velocity * delta
	_update_visibility()


func is_harvestable() -> bool:
	return _active


func apply_tractor_pull(target_pos: Vector3, pull_accel: float, delta: float) -> void:
	if not _active:
		return
	var to_target: Vector3 = target_pos - global_position
	var dist: float = to_target.length()
	if dist < 0.05:
		return
	var dir: Vector3 = to_target / dist
	velocity = velocity.lerp(dir * minf(dist * 2.0, pull_accel), 4.0 * delta)


func try_collect(cargo: Node, ship_pos: Vector3, collect_radius: float) -> bool:
	if not _active or cargo == null:
		return false
	if global_position.distance_to(ship_pos) > collect_radius:
		return false
	var taken: float = cargo.try_add(mass)
	if taken <= 0.0:
		return false
	_active = false
	collected.emit(taken, material_id)
	queue_free()
	return true


func _update_visibility() -> void:
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if ship == null:
		return
	var dist: float = ship.global_position.distance_to(global_position)
	if _mesh:
		_mesh.visible = dist <= WorldScale.VISUAL_MESH_RADIUS_UNITS
	if _beacon:
		_beacon.visible = (
			dist > WorldScale.VISUAL_MESH_RADIUS_UNITS
			and dist <= WorldScale.MARKER_BEACON_RADIUS_UNITS
		)
