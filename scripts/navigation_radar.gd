extends Control
## Tactical radar: heading-up blips, depot beacon, objective highlight.

const WorldScale = preload("res://scripts/world_scale.gd")

@export var nav_path: NodePath = ^"../../NavigationSystem"
@export var radar_radius_px := 88.0
## Blips closer than this (px) on the disc merge into one sized cluster blip.
const CLUSTER_MERGE_PX := 11.0
## Hard cap on drawn cluster blips so dense belts never become a smear.
const MAX_BLIPS := 14

var _nav: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(196, 196)
	_nav = get_node_or_null(nav_path)


func set_nav(nav: Node) -> void:
	_nav = nav


func _draw() -> void:
	if _nav == null or _nav.ship == null:
		return
	var center := size * 0.5
	var max_range: float = WorldScale.RADAR_RANGE_UNITS
	for ring_ratio in [0.33, 0.66, 1.0]:
		draw_arc(
			center,
			radar_radius_px * ring_ratio,
			0.0,
			TAU,
			48,
			Color(0.35, 0.55, 0.75, 0.22 if ring_ratio < 1.0 else 0.55),
			1.0,
		)
	draw_line(center, center + Vector2(0.0, -radar_radius_px * 0.85), Color(0.5, 0.85, 0.95, 0.6), 2.0)

	var ship_basis: Basis = _nav.ship.global_transform.basis
	var objective: Dictionary = _nav.navigation_objective() if _nav.has_method("navigation_objective") else {}
	var objective_world: Vector3 = objective.get("pos", Vector3.INF)
	var origin: Vector3 = _nav.ship.global_position

	_draw_depot_blip(center, ship_basis, origin, max_range, objective)

	var clusters: Array[Dictionary] = []
	for poi in _nav.radar_pois():
		var offset: Vector3 = poi.pos
		var local: Vector3 = ship_basis.inverse() * offset
		var flat := Vector2(local.x, -local.z)
		if flat.length_squared() < 0.01:
			continue
		var norm_dist: float = clampf(poi.dist / max_range, 0.0, 1.0)
		var blip: Vector2 = center + flat.normalized() * sqrt(norm_dist) * radar_radius_px
		var is_objective: bool = objective_world.distance_squared_to(origin + offset) < 400.0
		var h: float = local.y / max_range
		var merged := false
		for c in clusters:
			if (c["pos"] as Vector2).distance_to(blip) <= CLUSTER_MERGE_PX:
				var n: int = c["count"]
				c["pos"] = ((c["pos"] as Vector2) * float(n) + blip) / float(n + 1)
				c["count"] = n + 1
				c["h"] = float(c["h"]) + h
				c["is_objective"] = bool(c["is_objective"]) or is_objective
				merged = true
				break
		if not merged:
			clusters.append({"pos": blip, "count": 1, "h": h, "is_objective": is_objective})

	clusters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["count"] > b["count"])
	var shown: int = 0
	for c in clusters:
		if shown >= MAX_BLIPS:
			break
		_draw_cluster(center, c, radar_radius_px)
		shown += 1

	draw_circle(center, 5.0, Color(0.4, 0.85, 1.0, 1.0))


func _draw_cluster(center: Vector2, c: Dictionary, radar_radius_px: float) -> void:
	var blip: Vector2 = c["pos"]
	var count: int = c["count"]
	var is_objective: bool = c["is_objective"]
	var avg_h: float = float(c["h"]) / float(count)
	var radius: float = clampf(3.0 + sqrt(float(count)) * 1.6, 3.0, 9.0)
	var stalk_end: Vector2 = blip + Vector2(0.0, -avg_h * radar_radius_px * 0.6)
	var stalk_color := Color(1.0, 0.85, 0.25, 0.85) if is_objective else Color(1.0, 0.55, 0.15, 0.5)
	draw_line(blip, stalk_end, stalk_color, 1.5 if is_objective else 1.0)
	draw_circle(stalk_end, radius, stalk_color)
	if is_objective:
		draw_arc(blip, radius + 4.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.25, 0.75), 1.5)
	draw_circle(blip, 2.0, Color(1.0, 0.55, 0.15, 0.35))
	if count > 1:
		var font := ThemeDB.fallback_font
		draw_string(
			font,
			stalk_end + Vector2(radius + 1.0, 4.0),
			str(count),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			Color(1.0, 0.9, 0.7, 0.9),
		)


func _draw_depot_blip(
	center: Vector2,
	ship_basis: Basis,
	origin: Vector3,
	max_range: float,
	objective: Dictionary,
) -> void:
	var depot_pos: Vector3 = _nav.depot_position
	var dep_offset: Vector3 = depot_pos - origin
	var dep_dist: float = dep_offset.length()
	if dep_dist > max_range:
		return
	var dep_local: Vector3 = ship_basis.inverse() * dep_offset
	var dep_flat := Vector2(dep_local.x, -dep_local.z)
	if dep_flat.length_squared() < 0.01:
		return
	var dep_blip: Vector2 = center + dep_flat.normalized() * sqrt(dep_dist / max_range) * radar_radius_px
	var is_objective: bool = str(objective.get("name", "")) == "depot"
	var color := Color(0.25, 0.85, 1.0, 0.95)
	draw_circle(dep_blip, 6.0 if is_objective else 4.5, color)
	if is_objective:
		draw_arc(dep_blip, 10.0, 0.0, TAU, 24, color.lightened(0.2), 1.5)


func _process(_delta: float) -> void:
	queue_redraw()
