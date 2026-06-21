extends Node3D
## Arcade 6DOF ship flight (presentation only). Tuning: wiki/features/F001-third-person-flight.md

enum SpeedBand { IMPULSE, CRUISE }

signal speed_band_changed(band: SpeedBand)
signal auto_level_changed(enabled: bool)
signal look_mode_changed(active: bool)

@export var impulse_max_speed := 65.0
@export var cruise_max_speed := 250.0
@export var acceleration := 50.0
@export var linear_drag := 1.15
@export var mouse_sensitivity := 0.0028
@export var auto_level_strength := 2.2
@export var roll_speed := 1.6

var velocity: Vector3 = Vector3.ZERO
var speed_band: SpeedBand = SpeedBand.IMPULSE
var auto_level_enabled: bool = true
var look_mode: bool = false

var _cargo: Node


func _ready() -> void:
	_cargo = get_node_or_null("../CargoHold")
	_update_speed_band()


func _input(event: InputEvent) -> void:
	if look_mode or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion and event.relative.length_squared() > 0.0:
		rotate_object_local(Vector3.UP, -event.relative.x * mouse_sensitivity)
		rotate_object_local(transform.basis.x, -event.relative.y * mouse_sensitivity)


func _process(delta: float) -> void:
	_update_speed_band()
	_apply_roll(delta)
	if auto_level_enabled and not look_mode:
		_apply_auto_level(delta)
	_apply_thrust(delta)
	_apply_drag(delta)
	_clamp_speed()
	global_position += velocity * delta


func _apply_roll(delta: float) -> void:
	var roll_input: float = _axis("ship_roll_right", KEY_E) - _axis("ship_roll_left", KEY_Q)
	if absf(roll_input) > 0.01:
		rotate_object_local(Vector3.FORWARD, -roll_input * roll_speed * delta)


func _apply_auto_level(delta: float) -> void:
	var up: Vector3 = global_transform.basis.y
	var target_up: Vector3 = up.lerp(Vector3.UP, auto_level_strength * delta).normalized()
	var forward: Vector3 = -global_transform.basis.z
	forward = (forward - forward.dot(target_up) * target_up).normalized()
	if forward.length_squared() < 1.0e-6:
		return
	global_transform.basis = Basis.looking_at(global_position + forward, target_up)


func _apply_thrust(delta: float) -> void:
	var input_dir := Vector3(
		_axis("ship_strafe_right", KEY_D) - _axis("ship_strafe_left", KEY_A),
		_axis("ship_thrust_up", KEY_SPACE) - _axis("ship_thrust_down", KEY_C),
		_axis("ship_thrust_back", KEY_S) - _axis("ship_thrust_forward", KEY_W),
	)
	if input_dir.length_squared() < 1.0e-6:
		return
	input_dir = input_dir.normalized()
	velocity += global_transform.basis * input_dir * acceleration * delta


func _apply_drag(delta: float) -> void:
	velocity = velocity.lerp(Vector3.ZERO, linear_drag * delta)


func _clamp_speed() -> void:
	var cap: float = max_speed()
	if velocity.length() > cap:
		velocity = velocity.normalized() * cap


func _update_speed_band() -> void:
	var want_cruise := Input.is_action_pressed("ship_boost") or Input.is_physical_key_pressed(KEY_SHIFT)
	var new_band := SpeedBand.CRUISE if want_cruise else SpeedBand.IMPULSE
	if new_band != speed_band:
		speed_band = new_band
		speed_band_changed.emit(speed_band)


func _axis(action: StringName, fallback_key: Key) -> float:
	var strength: float = Input.get_action_strength(action)
	if strength > 0.01:
		return strength
	return 1.0 if Input.is_physical_key_pressed(fallback_key) else 0.0


func set_look_mode(active: bool) -> void:
	if look_mode == active:
		return
	look_mode = active
	look_mode_changed.emit(active)


func toggle_auto_level() -> void:
	auto_level_enabled = not auto_level_enabled
	auto_level_changed.emit(auto_level_enabled)


func max_speed() -> float:
	var base: float = cruise_max_speed if speed_band == SpeedBand.CRUISE else impulse_max_speed
	if _cargo != null and _cargo.has_method("speed_multiplier"):
		base *= _cargo.speed_multiplier()
	return base
