extends Node3D
## Distant skyline black hole for explore runs. Visual landmark only — locked-decisions.md

const WorldScale = preload("res://scripts/world_scale.gd")
const BhDiskDriver = preload("res://scripts/bh_disk_driver.gd")

const DISK_MESH_SCALE := 2800.0

@onready var black_hole: Node = $BlackHole
@onready var disk_mesh: MeshInstance3D = $DiskMesh


func _ready() -> void:
	global_position = WorldScale.BH_WORLD_POSITION
	if disk_mesh:
		disk_mesh.scale = Vector3.ONE * DISK_MESH_SCALE


func _process(_delta: float) -> void:
	if black_hole == null:
		return
	var mat: ShaderMaterial = black_hole.get("disk_material")
	BhDiskDriver.update_disk_material(black_hole, mat)
