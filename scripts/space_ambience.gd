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
	var bh_pos: Vector3 = WorldScale.BH_WORLD_POSITION
	var inward: Vector3 = (bh_pos - _ship.global_position).normalized()
	if disk_light:
		disk_light.global_position = _ship.global_position - inward * 200.0
		disk_light.look_at(_ship.global_position, Vector3.UP)
	if fill_light:
		fill_light.global_position = _ship.global_position + inward * 120.0
		fill_light.look_at(_ship.global_position, Vector3.UP)
	if dust:
		dust.global_position = _ship.global_position
		_update_bh_audio(_ship.global_position.distance_to(bh_pos))


func _update_bh_audio(dist_to_bh: float) -> void:
	if not AudioManager.has_method("set_explore_proximity"):
		return
	var inner: float = WorldScale.BH_INNER_ZONE_UNITS
	var outer: float = WorldScale.BH_OUTER_ZONE_UNITS
	var t: float = clampf(inverse_lerp(outer, inner, dist_to_bh), 0.0, 1.0)
	AudioManager.set_explore_proximity(t)
