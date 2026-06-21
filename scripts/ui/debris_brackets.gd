extends Control
## Screen-space target brackets for harvestable debris. Spec: wiki/features/F011-explore-world-soul.md
##
## Draws thin hollow corner ticks that FRAME a target — never a filled glyph stamped
## over it. Nearest contacts only, so dense belts stay readable.

const WorldScale = preload("res://scripts/world_scale.gd")

const MAX_BRACKETS := 16
const MIN_DIST := 3.0
const TICK_LEN := 6.0
const THICKNESS := 2.0
const BASE_COLOR := Color(1.0, 0.74, 0.34, 1.0)

var _ship: Node3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if _ship == null or not is_instance_valid(_ship):
		_ship = get_tree().get_first_node_in_group("player_ship") as Node3D
	if _ship == null:
		return
	if WorldScale.is_inside_bh_volume(_ship.global_position):
		return
	var origin: Vector3 = _ship.global_position
	var items: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var n3 := node as Node3D
		if n3 == null:
			continue
		var wp: Vector3 = n3.global_position
		var dist: float = origin.distance_to(wp)
		if dist < MIN_DIST or dist > WorldScale.MARKER_BEACON_RADIUS_UNITS:
			continue
		if cam.is_position_behind(wp):
			continue
		items.append({"wp": wp, "dist": dist})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dist < b.dist)

	var drawn: int = 0
	for item in items:
		if drawn >= MAX_BRACKETS:
			break
		var wp: Vector3 = item.wp
		var dist: float = item.dist
		var center: Vector2 = cam.unproject_position(wp)
		var half: float = clampf(2400.0 / maxf(dist, 1.0), 8.0, 44.0)
		var fade: float = clampf(
			inverse_lerp(WorldScale.MARKER_BEACON_RADIUS_UNITS, WorldScale.BEACON_FADE_IN_UNITS, dist),
			0.28,
			1.0,
		)
		var col := BASE_COLOR
		col.a = fade
		_draw_bracket(center, half, col)
		drawn += 1


func _draw_bracket(center: Vector2, half: float, col: Color) -> void:
	var tick: float = minf(TICK_LEN, half * 0.5)
	var tl := center + Vector2(-half, -half)
	var tr := center + Vector2(half, -half)
	var bl := center + Vector2(-half, half)
	var br := center + Vector2(half, half)
	# Top-left
	draw_line(tl, tl + Vector2(tick, 0.0), col, THICKNESS)
	draw_line(tl, tl + Vector2(0.0, tick), col, THICKNESS)
	# Top-right
	draw_line(tr, tr + Vector2(-tick, 0.0), col, THICKNESS)
	draw_line(tr, tr + Vector2(0.0, tick), col, THICKNESS)
	# Bottom-left
	draw_line(bl, bl + Vector2(tick, 0.0), col, THICKNESS)
	draw_line(bl, bl + Vector2(0.0, -tick), col, THICKNESS)
	# Bottom-right
	draw_line(br, br + Vector2(-tick, 0.0), col, THICKNESS)
	draw_line(br, br + Vector2(0.0, -tick), col, THICKNESS)
