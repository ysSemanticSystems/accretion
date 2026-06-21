extends RefCounted
## Display scale + sector constants (presentation tuning).
## Spec: wiki/game-design/distance-and-visibility.md

## One game unit is shown to the player as one kilometre.
const UNITS_PER_KM := 1.0
## Sector cube edge length in game units (matches architecture sector-streaming placeholder).
const SECTOR_EDGE_UNITS := 1000.0
## Tactical radar shows POIs within this true radius.
const RADAR_RANGE_UNITS := 2500.0
## Full debris mesh drawn within this range.
const VISUAL_MESH_RADIUS_UNITS := 500.0
## Nav billboard marker shown beyond mesh radius up to this range.
const MARKER_BEACON_RADIUS_UNITS := 8000.0


static func sector_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(pos.x / SECTOR_EDGE_UNITS)),
		int(floor(pos.y / SECTOR_EDGE_UNITS)),
		int(floor(pos.z / SECTOR_EDGE_UNITS)),
	)


static func format_distance(units: float) -> String:
	var km: float = units / UNITS_PER_KM
	if km < 1000.0:
		return "%.0f km" % km
	return "%.2f Mm" % (km / 1000.0)


static func format_position(pos: Vector3) -> String:
	return "(%.0f, %.0f, %.0f) km" % [pos.x, pos.y, pos.z]
