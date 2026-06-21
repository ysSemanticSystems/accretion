extends RefCounted
## Single source for upgrade track labels and row formatting. Spec: F004, F014.

const TRACK_COUNT := 3
const MAX_PIPS := 3
const TRACK_NAMES := ["Cargo Hold", "Tractor Beam", "Cruise Drive"]
const TRACK_EFFECTS := ["+100 u hold", "+40 km range", "+25% cruise accel"]


static func track_name(kind: int) -> String:
	return TRACK_NAMES[kind] if kind >= 0 and kind < TRACK_NAMES.size() else "Upgrade"


static func pips_for_level(level: int) -> String:
	var out := ""
	for p in MAX_PIPS:
		out += "●" if p < level else "○"
	return out


static func row_text(kind: int, selected: int, level: int, cost: float, prefix_style: bool) -> String:
	var prefix := "> " if prefix_style and kind == selected else "  "
	var cost_text := "MAXED" if cost == INF else "%.0f u" % cost
	return "%s%s  %s  %s  %s" % [
		prefix,
		track_name(kind),
		pips_for_level(level),
		TRACK_EFFECTS[kind],
		cost_text,
	]


static func row_color(affordable: bool, docked: bool, ops_style: bool) -> Color:
	if ops_style:
		if affordable:
			return Color(0.42, 0.92, 0.58)
		if docked:
			return Color(0.98, 0.72, 0.28)
		return Color(0.45, 0.52, 0.58)
	if affordable:
		return Color(0.45, 0.95, 0.55)
	return Color(0.95, 0.75, 0.35)
