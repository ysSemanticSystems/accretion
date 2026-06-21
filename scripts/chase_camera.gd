extends Camera3D
## Third-person chase camera for F001/F006. Render-frame follow for display-synced motion.

@export var target_path: NodePath = ^"../ShipBody"
@export var follow_distance := 9.0
@export var follow_height := 2.6
@export var position_smooth := 14.0
@export var rotation_smooth := 16.0
@export var look_sensitivity := 0.0032
@export var min_pitch := -0.45
@export var max_pitch := 0.55
@export var fov_rest := 70.0
@export var fov_max := 86.0
@export var fov_cruise_bonus := 4.0
@export var fov_smooth := 10.0
@export var streak_path: NodePath = ^"SpeedStreaks"

var _target: Node3D
var _streaks: GPUParticles3D
var _orbit_yaw := 0.0
var _orbit_pitch := 0.18
var _look_mode := false
var _look_motion := Vector2.ZERO


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_streaks = get_node_or_null(streak_path) as GPUParticles3D
	fov = fov_rest
	if _target == null:
		push_error("ChaseCamera: missing target at %s" % target_path)
		return
	if _target.has_signal("look_mode_changed"):
		_target.look_mode_changed.connect(_on_ship_look_mode_changed)
	_snap_behind()


func _input(event: InputEvent) -> void:
	if not _look_mode or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_look_motion += event.relative


func _process(delta: float) -> void:
	if _target == null:
		return
	_handle_look_input()
	var desired := _orbit_transform() if _look_mode else _chase_transform()
	if not _look_mode:
		_orbit_yaw = _angle_from_basis(desired.basis, Vector3.UP)
		_orbit_pitch = asin(clamp(desired.basis.y.dot(-desired.basis.z), -1.0, 1.0))
	var pos_weight: float = 1.0 - exp(-position_smooth * delta)
	var origin: Vector3 = global_transform.origin.lerp(desired.origin, pos_weight)
	var rot_weight: float = 1.0 - exp(-rotation_smooth * delta)
	var basis: Basis = global_transform.basis.slerp(desired.basis, rot_weight)
	global_transform = Transform3D(basis, origin)
	_update_fov(delta)
	_update_streaks()


func _handle_look_input() -> void:
	var want_look := Input.is_action_pressed("ship_look")
	if want_look != _look_mode:
		_look_mode = want_look
		if _target.has_method("set_look_mode"):
			_target.set_look_mode(_look_mode)
	if _look_mode and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _look_motion.length_squared() > 0.0:
			_orbit_yaw -= _look_motion.x * look_sensitivity
			_orbit_pitch = clamp(
				_orbit_pitch - _look_motion.y * look_sensitivity,
				min_pitch,
				max_pitch,
			)
			_look_motion = Vector2.ZERO


func _update_fov(delta: float) -> void:
	var max_spd: float = 65.0
	if _target.has_method("max_speed"):
		max_spd = max(_target.max_speed(), 1.0)
	var speed_ratio: float = clampf(_target.velocity.length() / max_spd, 0.0, 1.0)
	var target_fov: float = lerpf(fov_rest, fov_max, speed_ratio)
	if _target.get("cruise_spool") != null:
		target_fov += fov_cruise_bonus * float(_target.cruise_spool)
	var weight: float = 1.0 - exp(-fov_smooth * delta)
	fov = lerpf(fov, target_fov, weight)


func _update_streaks() -> void:
	if _streaks == null or _target == null:
		return
	var max_spd: float = 65.0
	if _target.has_method("max_speed"):
		max_spd = max(_target.max_speed(), 1.0)
	var ratio: float = clampf(_target.velocity.length() / max_spd, 0.0, 1.0)
	_streaks.amount_ratio = ratio
	_streaks.emitting = ratio > 0.08


func _on_ship_look_mode_changed(active: bool) -> void:
	_look_mode = active


func _chase_transform() -> Transform3D:
	var ship_basis := _target.global_transform.basis.orthonormalized()
	var back := ship_basis.z
	var up := ship_basis.y
	var cam_pos := _target.global_position + back * follow_distance + up * follow_height
	var look_target := _target.global_position - back * 2.0
	return Transform3D(Basis.looking_at(look_target - cam_pos, up), cam_pos)


func _orbit_transform() -> Transform3D:
	var center := _target.global_position
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch),
	).normalized() * follow_distance
	offset += Vector3.UP * follow_height * 0.35
	var cam_pos := center + offset
	return Transform3D(Basis.looking_at(cam_pos - center, Vector3.UP), cam_pos)


func _snap_behind() -> void:
	if _target == null:
		return
	global_transform = _chase_transform()


func _angle_from_basis(b: Basis, axis: Vector3) -> float:
	var flat := b.z
	flat.y = 0.0
	if flat.length_squared() < 1.0e-6:
		return _orbit_yaw
	return atan2(flat.x, flat.z)
