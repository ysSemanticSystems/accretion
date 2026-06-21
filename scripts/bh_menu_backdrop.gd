extends Node3D
## Slow-orbit black hole backdrop for main menu. Presentation only.

const AUTORBIT_SPEED := 0.035

@onready var camera: Camera3D = $Camera3D

var _yaw := 0.4
var _pitch := 0.18
var _dist := 9.0


func _process(delta: float) -> void:
	_yaw += AUTORBIT_SPEED * delta
	if camera:
		var offset := Vector3(
			sin(_yaw) * cos(_pitch),
			sin(_pitch),
			cos(_yaw) * cos(_pitch),
		) * _dist
		camera.global_position = offset + Vector3(0, 0.5, 0)
		camera.look_at(Vector3.ZERO, Vector3.UP)
