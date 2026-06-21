extends Node3D
## Distant host star — distinct from M87* accretion disk. Spec: F011, F013.

const WorldScale = preload("res://scripts/world_scale.gd")

## Keep a roughly constant apparent angular radius on the billboard.
const ANGULAR_RADIUS := 0.024

@onready var billboard: MeshInstance3D = $Billboard


func _ready() -> void:
	global_position = WorldScale.PRIMARY_STAR_POSITION


func _process(_delta: float) -> void:
	if billboard == null:
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	billboard.look_at(cam.global_position, Vector3.UP)
	var dist: float = max(cam.global_position.distance_to(global_position), 1.0)
	billboard.scale = Vector3.ONE * (dist * ANGULAR_RADIUS)
