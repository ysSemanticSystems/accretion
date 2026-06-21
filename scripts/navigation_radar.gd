extends Control
## Tactical radar: heading-up blips with altitude stalks (presentation only).

const WorldScale = preload("res://scripts/world_scale.gd")

@export var nav_path: NodePath = ^"../../NavigationSystem"
@export var radar_radius_px := 88.0

var _nav: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(196, 196)
	_nav = get_node_or_null(nav_path)


func _draw() -> void:
	if _nav == null:
		return
	var center := size * 0.5
	draw_arc(center, radar_radius_px, 0.0, TAU, 64, Color(0.35, 0.55, 0.75, 0.55), 1.5)
	# Nose tick (heading-up: forward is up on disc)
	draw_line(center, center + Vector2(0.0, -radar_radius_px * 0.85), Color(0.5, 0.85, 0.95, 0.6), 2.0)
	var max_range: float = WorldScale.RADAR_RANGE_UNITS
	var ship_basis: Basis = Basis.IDENTITY
	if _nav.ship != null:
		ship_basis = _nav.ship.global_transform.basis
	for poi in _nav.radar_pois():
		var offset: Vector3 = poi.pos
		var local: Vector3 = ship_basis.inverse() * offset
		var flat := Vector2(local.x, -local.z)
		if flat.length_squared() < 0.01:
			continue
		var norm_dist: float = clampf(poi.dist / max_range, 0.0, 1.0)
		var ring: float = sqrt(norm_dist)
		var blip: Vector2 = center + flat.normalized() * ring * radar_radius_px
		var h: float = local.y / max_range
		var stalk_end: Vector2 = blip + Vector2(0.0, -h * radar_radius_px * 0.6)
		draw_line(blip, stalk_end, Color(1.0, 0.55, 0.15, 0.5), 1.0)
		draw_circle(stalk_end, 4.0, Color(1.0, 0.55, 0.15, 0.95))
		draw_circle(blip, 2.0, Color(1.0, 0.55, 0.15, 0.4))
	draw_circle(center, 5.0, Color(0.4, 0.85, 1.0, 1.0))


func _process(_delta: float) -> void:
	queue_redraw()
