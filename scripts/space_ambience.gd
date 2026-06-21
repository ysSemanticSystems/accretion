extends Node3D
## Mid-field parallax dust + explore lighting from the distant BH.

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var dust: GPUParticles3D = $ParallaxDust
@onready var disk_light: DirectionalLight3D = $DiskLight
@onready var fill_light: DirectionalLight3D = $FillLight

var _ship: Node3D


func _ready() -> void:
	if dust:
		dust.emitting = true


func _process(_delta: float) -> void:
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	if _ship == null:
		return
	var ship_pos: Vector3 = _ship.global_position
	var bh_pos: Vector3 = WorldScale.BH_WORLD_POSITION
	var inward: Vector3 = (bh_pos - ship_pos).normalized()
	# Warm key sits on the BH side and rakes outward, so the disk lights the
	# BH-facing hull and rocks. Light position is only used to orient the beam.
	if disk_light:
		disk_light.global_position = ship_pos + inward * 300.0
		disk_light.look_at(ship_pos, _safe_up(inward))
	# Cool rim from above/behind separates the dark side from the void.
	if fill_light:
		var rim_offset: Vector3 = (-inward * 120.0) + Vector3.UP * 260.0
		fill_light.global_position = ship_pos + rim_offset
		fill_light.look_at(ship_pos, Vector3.UP)
	if dust:
		dust.global_position = ship_pos
		_update_bh_audio(ship_pos.distance_to(bh_pos))


func _safe_up(forward: Vector3) -> Vector3:
	if absf(forward.dot(Vector3.UP)) > 0.98:
		return Vector3.FORWARD
	return Vector3.UP


func _update_bh_audio(dist_to_bh: float) -> void:
	if not AudioManager.has_method("set_explore_proximity"):
		return
	var inner: float = WorldScale.BH_INNER_ZONE_UNITS
	var outer: float = WorldScale.BH_OUTER_ZONE_UNITS
	var t: float = clampf(inverse_lerp(outer, inner, dist_to_bh), 0.0, 1.0)
	AudioManager.set_explore_proximity(t)
