extends Control
## Intel tab — live run telemetry readout. Spec: F014.

const WorldScale = preload("res://scripts/world_scale.gd")
const OpsStyles = preload("res://scripts/ui/ops_styles.gd")

@onready var body: RichTextLabel = $VBox/Body

var _nav: Node
var _objectives: Node
var _cargo: Node
var _progression: Node


func bind(nav: Node, objectives: Node, cargo: Node, progression: Node) -> void:
	_nav = nav
	_objectives = objectives
	_cargo = cargo
	_progression = progression
	if is_node_ready():
		refresh()


func refresh() -> void:
	var stats: Dictionary = RunTracker.summary_dict()
	var lines: PackedStringArray = []
	lines.append("[color=#59d1f2]RUN TELEMETRY[/color]")
	lines.append("Seed · %d" % int(stats.get("seed", 0)))
	lines.append("Elapsed · %s" % _fmt_time(float(stats.get("time_sec", 0.0))))
	lines.append("")
	lines.append("[color=#59d1f2]POSITION[/color]")
	if _nav != null and _nav.has_method("sector_label"):
		lines.append(_nav.sector_label())
	if _nav != null and _nav.has_method("position_label"):
		lines.append(_nav.position_label())
	var bh_km: float = float(stats.get("closest_bh_km", -1.0))
	if bh_km > 0.0:
		lines.append(
			"Closest M87* · %s"
			% WorldScale.format_distance(bh_km * WorldScale.UNITS_PER_KM)
		)
	var zone: int = int(stats.get("deepest_approach_zone", 0))
	if zone > 0:
		lines.append("Deepest gate · %s" % WorldScale.approach_zone_label(zone))
	lines.append("")
	lines.append("[color=#59d1f2]CARGO & BANK[/color]")
	var held: float = _cargo.current_mass if _cargo != null else 0.0
	var cap: float = _progression.cargo_capacity() if _progression != null else 0.0
	lines.append("Hold · %.0f / %.0f u" % [held, cap])
	lines.append("Banked · %.0f u" % float(stats.get("banked", 0.0)))
	lines.append("")
	lines.append("[color=#59d1f2]EXPLORATION[/color]")
	lines.append("Sectors charted · %d" % int(stats.get("sectors", 0)))
	lines.append("Max sector ring · %d" % int(stats.get("max_distance", 0)))
	if _objectives != null:
		lines.append(
			"Approach gates cleared · %d / %d"
			% [_objectives.max_approach_zone, WorldScale.APPROACH_ZONE_COUNT]
		)
	lines.append("")
	lines.append("[color=#59d1f2]OBJECTIVE[/color]")
	if _nav != null and _nav.has_method("navigation_objective"):
		var obj: Dictionary = _nav.navigation_objective()
		var name: String = obj.get("name", "none")
		if name == "depot":
			lines.append("Return cargo · home beacon")
		elif name == "black_hole":
			var dist := WorldScale.distance_to_bh_km(
				_nav.ship.global_position if _nav.ship != null else Vector3.ZERO
			)
			lines.append(
				"Inward survey · M87* %s away"
				% WorldScale.format_distance(dist * WorldScale.UNITS_PER_KM)
			)
		elif not obj.is_empty():
			lines.append("Nearest debris · tractoring priority")
		else:
			lines.append("No active objective")
	body.text = "\n".join(lines)


func _fmt_time(sec: float) -> String:
	var mins := int(sec) / 60
	var rem := int(sec) % 60
	return "%d:%02d" % [mins, rem]
