extends Node3D
## Parallax dust + dual lighting: host star key, separate weak BH disk rim.

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var dust: GPUParticles3D = $ParallaxDust
@onready var star_light: DirectionalLight3D = $StarLight
@onready var fill_light: DirectionalLight3D = $FillLight
@onready var bh_rim_light: DirectionalLight3D = $BhRimLight

var _ship: Node3D
var _world_env: WorldEnvironment


func _ready() -> void:
	if dust:
		dust.emitting = true
	_world_env = get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	_sync_sky_directions(Vector3.ZERO)


func _process(_delta: float) -> void:
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	if _ship == null:
		return
	var ship_pos: Vector3 = _ship.global_position
	var bh_pos: Vector3 = WorldScale.BH_WORLD_POSITION
	var star_pos: Vector3 = WorldScale.PRIMARY_STAR_POSITION

	var star_dir: Vector3 = (star_pos - ship_pos).normalized()
	if star_light:
		star_light.global_position = ship_pos + star_dir * 500.0
		star_light.look_at(ship_pos, _safe_up(star_dir))

	# Cool fill from the nebula / opposite hemisphere — not the BH.
	if fill_light:
		var fill_dir: Vector3 = (-star_dir + Vector3.UP * 0.35).normalized()
		fill_light.global_position = ship_pos + fill_dir * 400.0
		fill_light.look_at(ship_pos, Vector3.UP)

	# BH disk is self-lit in the shader; this rim only nudges hull when close.
	var dist_bh: float = ship_pos.distance_to(bh_pos)
	var bh_prox: float = clampf(
		inverse_lerp(WorldScale.BH_OUTER_ZONE_UNITS, WorldScale.BH_INNER_ZONE_UNITS, dist_bh),
		0.0,
		1.0,
	)
	if bh_rim_light:
		var inward: Vector3 = (bh_pos - ship_pos).normalized()
		bh_rim_light.light_energy = lerpf(0.0, 0.65, bh_prox)
		bh_rim_light.global_position = ship_pos + inward * 280.0
		bh_rim_light.look_at(ship_pos, _safe_up(inward))

	if dust:
		dust.global_position = ship_pos
	_update_bh_audio(dist_bh)
	_sync_sky_directions(ship_pos)


func _sync_sky_directions(ship_pos: Vector3) -> void:
	if _world_env == null or _world_env.environment == null:
		return
	var sky: Sky = _world_env.environment.sky
	if sky == null:
		return
	var mat: Material = sky.sky_material
	if mat == null or not mat is ShaderMaterial:
		return
	var sm: ShaderMaterial = mat as ShaderMaterial
	var bh_dir: Vector3 = (WorldScale.BH_WORLD_POSITION - ship_pos).normalized()
	var star_dir: Vector3 = (WorldScale.PRIMARY_STAR_POSITION - ship_pos).normalized()
	sm.set_shader_parameter("disk_glow_dir", bh_dir)
	sm.set_shader_parameter("primary_star_dir", star_dir)


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
