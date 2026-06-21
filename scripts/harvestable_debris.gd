extends Node3D
## Loose debris harvestable by tractor. Spec: wiki/features/F002-tractor-cargo.md

const WorldScale = preload("res://scripts/world_scale.gd")

signal collected(mass: float, material_id: String)

@export var material_id := "volatiles"
@export var mass: float = 25.0
@export var drift_speed := 2.5

var velocity: Vector3 = Vector3.ZERO
var _active := true

var _visual_root: Node3D
var _beacon: MeshInstance3D
var _ship: Node3D


func _ready() -> void:
	add_to_group("harvestable")
	add_to_group("nav_poi")
	_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	velocity = Vector3(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4), randf_range(-1.0, 1.0))
	if velocity.length_squared() > 0.01:
		velocity = velocity.normalized() * drift_speed
	_visual_root = get_node_or_null("DebrisVisual") as Node3D
	_beacon = get_node_or_null("NavBeacon") as MeshInstance3D


func _process(delta: float) -> void:
	if not _active:
		return
	global_position += velocity * delta
	_update_visibility()


func is_harvestable() -> bool:
	return _active


func apply_tractor_pull(
	target_pos: Vector3,
	pull_accel: float,
	intake_radius: float,
	delta: float,
) -> void:
	if not _active:
		return
	var to_target: Vector3 = target_pos - global_position
	var dist: float = to_target.length()
	if dist < 0.05:
		velocity = Vector3.ZERO
		return
	var dir: Vector3 = to_target / dist
	var close: float = clampf(1.0 - dist / max(intake_radius, 1.0), 0.0, 1.0)
	var snap: float = close * close
	global_position = global_position.lerp(target_pos, snap * min(14.0 * delta, 1.0))
	var pull: float = pull_accel * (1.0 + 3.0 * close)
	velocity = velocity.lerp(dir * minf(dist * 3.0, pull), (4.0 + 8.0 * close) * delta)
	if close > 0.85:
		velocity *= max(0.0, 1.0 - 18.0 * delta)


func try_collect(cargo: Node, ship_pos: Vector3, collect_radius: float) -> bool:
	if not _active or cargo == null:
		return false
	var offset: Vector3 = global_position - ship_pos
	var horizontal: float = Vector2(offset.x, offset.z).length()
	var vertical: float = absf(offset.y)
	var intake_metric: float = maxf(horizontal, vertical * 0.45)
	if intake_metric > collect_radius:
		return false
	var taken: float = cargo.try_add(mass)
	if taken <= 0.0:
		return false
	_active = false
	collected.emit(taken, material_id)
	queue_free()
	return true


func _update_visibility() -> void:
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	if _ship == null:
		return
	var dist: float = _ship.global_position.distance_to(global_position)
	if _visual_root:
		_visual_root.visible = dist <= WorldScale.VISUAL_MESH_RADIUS_UNITS
	if _beacon:
		_beacon.visible = (
			dist > WorldScale.VISUAL_MESH_RADIUS_UNITS
			and dist <= WorldScale.MARKER_BEACON_RADIUS_UNITS
		)
