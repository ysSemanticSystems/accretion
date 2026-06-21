extends Node3D
## Screen-stable target bracket — visible at all harvestable ranges.

const WorldScale = preload("res://scripts/world_scale.gd")

@onready var marker: Label3D = $Marker

var _ship: Node3D
var _host: Node3D


func _ready() -> void:
	_host = get_parent() as Node3D
	if marker == null:
		push_error("debris_target_bracket: missing Marker Label3D child")
		return
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 64
	marker.text = "▣"
	marker.modulate = Color(1.0, 0.72, 0.28, 0.92)
	marker.outline_modulate = Color(0.05, 0.08, 0.12, 0.85)
	marker.outline_size = 8


func _process(_delta: float) -> void:
	if _host == null or not _host.has_method("is_harvestable"):
		visible = false
		return
	if not _host.is_harvestable():
		visible = false
		return
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	if _ship == null:
		visible = false
		return
	var dist: float = _ship.global_position.distance_to(_host.global_position)
	visible = dist <= WorldScale.MARKER_BEACON_RADIUS_UNITS
	if not visible:
		return
	var screen_scale: float = clampf(dist * 0.0065, 2.0, 52.0)
	scale = Vector3.ONE * screen_scale
	var fade: float = clampf(
		inverse_lerp(WorldScale.MARKER_BEACON_RADIUS_UNITS, WorldScale.BEACON_FADE_IN_UNITS, dist),
		0.35,
		1.0,
	)
	if marker != null:
		marker.modulate.a = fade
