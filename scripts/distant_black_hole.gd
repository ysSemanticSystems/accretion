extends Node3D
## Distant skyline black hole for explore runs. Visual landmark only — locked-decisions.md

const WorldScale = preload("res://scripts/world_scale.gd")
const BhDiskDriver = preload("res://scripts/bh_disk_driver.gd")

const MESH_FADE_START_UNITS := 14000.0
const MESH_FADE_END_UNITS := 3500.0

@onready var black_hole: Node = $BlackHole
@onready var disk_mesh: MeshInstance3D = $DiskMesh

var _ship: Node3D
var _was_inside := false


func _ready() -> void:
	global_position = WorldScale.BH_WORLD_POSITION
	if disk_mesh:
		disk_mesh.scale = Vector3.ONE * WorldScale.BH_DISK_MESH_SCALE
		disk_mesh.rotation_degrees = Vector3(62.0, 18.0, 0.0)


func _process(_delta: float) -> void:
	if black_hole == null:
		return
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	var ship_pos: Vector3 = _ship.global_position if _ship != null else Vector3.ZERO
	var dist: float = ship_pos.distance_to(global_position) if _ship != null else INF
	var proximity: float = clampf(
		inverse_lerp(MESH_FADE_START_UNITS, MESH_FADE_END_UNITS, dist),
		0.0,
		1.0,
	)
	var interior: float = WorldScale.bh_interior_blend(ship_pos) if _ship != null else 0.0
	var inside: bool = interior > 0.02
	if inside != _was_inside:
		_was_inside = inside
		GameEvents.bh_interior_changed.emit(inside)
	var mat: ShaderMaterial = black_hole.get("disk_material")
	BhDiskDriver.update_disk_material(black_hole, mat, proximity, interior)
