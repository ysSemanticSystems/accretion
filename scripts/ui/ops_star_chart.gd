extends Control
## M87* approach star chart — Warframe-style node graph. Spec: F014.

const WorldScale = preload("res://scripts/world_scale.gd")
const OpsStyles = preload("res://scripts/ui/ops_styles.gd")

var max_zone: int = 0
var live_zone: int = 0
var live_dist_km: float = INF
var at_home: bool = false

var _pulse: float = 0.0


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func refresh(max_cleared: int, ship_pos: Vector3, home_pos: Vector3) -> void:
	max_zone = max_cleared
	live_dist_km = WorldScale.distance_to_bh_km(ship_pos)
	live_zone = WorldScale.approach_zone_for_distance(live_dist_km)
	at_home = ship_pos.distance_to(home_pos) <= WorldScale.DEPOT_RADIUS_UNITS
	queue_redraw()


func _draw() -> void:
	var rect := get_rect()
	draw_rect(rect, Color(0.02, 0.04, 0.06, 0.55))
	_draw_grid(rect)
	var nodes: Array[Dictionary] = _node_layout(rect)
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		if i > 0:
			var prev: Dictionary = nodes[i - 1]
			draw_line(prev.pos, node.pos, OpsStyles.BORDER * Color(1, 1, 1, 0.45), 2.0)
	for i in nodes.size():
		_draw_node(nodes[i], i)
	_draw_ship_blip(nodes)


func _draw_grid(rect: Rect2) -> void:
	var step := 32.0
	var c := OpsStyles.BORDER * Color(1, 1, 1, 0.08)
	var x := fmod(rect.position.x, step)
	while x < rect.size.x:
		draw_line(Vector2(x, 0), Vector2(x, rect.size.y), c, 1.0)
		x += step
	var y := fmod(rect.position.y, step)
	while y < rect.size.y:
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), c, 1.0)
		y += step


func _node_layout(rect: Rect2) -> Array[Dictionary]:
	var pad := 48.0
	var y := rect.size.y * 0.5
	var count := WorldScale.APPROACH_ZONE_COUNT + 2
	var span := maxf(rect.size.x - pad * 2.0, 1.0)
	var step := span / float(count - 1)
	var out: Array[Dictionary] = []
	var labels := ["HOME BEACON", "OUTER WAKE", "LENSING FIELD", "PHOTON HALO", "DISK PLANE", "M87* CORE"]
	for i in count:
		var gate := -1 if i == 0 else (99 if i == count - 1 else i)
		out.append({
			"pos": Vector2(pad + step * i, y),
			"label": labels[i],
			"gate": gate,
		})
	return out


func _draw_node(node: Dictionary, index: int) -> void:
	var pos: Vector2 = node.pos
	var gate: int = node.gate
	var label: String = node.label
	var cleared := false
	var current := false
	var locked := false
	if gate < 0:
		cleared = true
		current = at_home
	elif gate == 99:
		cleared = max_zone >= WorldScale.APPROACH_ZONE_COUNT
		current = live_zone >= WorldScale.APPROACH_ZONE_COUNT and not at_home
		locked = max_zone < WorldScale.APPROACH_ZONE_COUNT - 1
	else:
		cleared = max_zone >= gate
		current = live_zone == gate and not at_home
		locked = max_zone < gate - 1 and live_zone < gate
	var radius := 14.0 if index < 5 else 18.0
	var fill: Color = OpsStyles.LOCKED
	if cleared:
		fill = OpsStyles.OK
	if current:
		var pulse := 0.65 + 0.35 * sin(_pulse * 4.0)
		fill = OpsStyles.WARN * Color(1, 1, 1, pulse)
	if locked and not current:
		fill = OpsStyles.LOCKED
	draw_circle(pos, radius + 3.0, OpsStyles.ACCENT * Color(1, 1, 1, 0.15 if not current else 0.35))
	draw_circle(pos, radius, fill)
	draw_arc(pos, radius, 0.0, TAU, 32, OpsStyles.BORDER, 1.5)
	var text_col := OpsStyles.TEXT if not locked else OpsStyles.DIM
	draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(-radius, radius + 16.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		radius * 2.0 + 80.0,
		11,
		text_col,
	)


func _draw_ship_blip(nodes: Array[Dictionary]) -> void:
	if nodes.is_empty() or live_dist_km >= INF:
		return
	var t := clampf(
		1.0 - live_dist_km / WorldScale.APPROACH_ZONE_DISTANCES[0],
		0.0,
		1.0,
	)
	t = clampf(t * float(nodes.size() - 1), 0.0, float(nodes.size() - 1))
	var idx := int(floor(t))
	var frac := t - float(idx)
	idx = mini(idx, nodes.size() - 2)
	var a: Vector2 = nodes[idx].pos
	var b: Vector2 = nodes[idx + 1].pos
	var pos := a.lerp(b, frac) + Vector2(0.0, -22.0)
	draw_line(pos, pos + Vector2(0.0, 10.0), OpsStyles.ACCENT, 2.0)
	draw_colored_polygon(
		PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(-6, 4), pos + Vector2(6, 4)]),
		OpsStyles.ACCENT,
	)
	var dist_text := "YOU · %s to M87*" % WorldScale.format_distance(
		live_dist_km * WorldScale.UNITS_PER_KM
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12.0, get_rect().size.y - 12.0),
		dist_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		get_rect().size.x - 24.0,
		12,
		OpsStyles.ACCENT,
	)
