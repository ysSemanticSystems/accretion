extends RefCounted
## M87* approach milestone pip formatting. Spec: F012.

const WorldScale = preload("res://scripts/world_scale.gd")


static func approach_pips(max_zone: int, next_zone: int, zone_count: int) -> String:
	var parts: PackedStringArray = []
	for zone in range(1, zone_count + 1):
		if zone <= max_zone:
			parts.append("●")
		elif zone == next_zone:
			parts.append("◐")
		else:
			parts.append("○")
	return " ".join(parts)


static func approach_line(max_zone: int, next_zone: int, zone_count: int) -> String:
	return "M87* approach %s · next: %s" % [
		approach_pips(max_zone, next_zone, zone_count),
		WorldScale.approach_zone_label(next_zone),
	]
