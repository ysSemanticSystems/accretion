extends RefCounted
## Display scale + sector constants (presentation tuning).
## Spec: wiki/game-design/distance-and-visibility.md, F011-explore-world-soul.md

## One game unit is shown to the player as one kilometre.
const UNITS_PER_KM := 1.0
## Home depot deposit / upgrade dock radius (single source of truth).
const DEPOT_RADIUS_UNITS := 80.0
## Sector cube edge length in game units (matches architecture sector-streaming placeholder).
const SECTOR_EDGE_UNITS := 1000.0
## Tactical radar shows POIs within this true radius.
const RADAR_RANGE_UNITS := 2500.0
## Full debris rock mesh shown within this radius (km).
const VISUAL_MESH_RADIUS_UNITS := 550.0
## Nav billboard marker fades between these radii (km).
const BEACON_FADE_OUT_UNITS := 600.0
const BEACON_FADE_IN_UNITS := 400.0
## Target bracket + beacon visible out to this radius (km).
const MARKER_BEACON_RADIUS_UNITS := 8000.0
## Distant skyline black hole (visual landmark). Negative Z = inward.
const BH_WORLD_POSITION := Vector3(0.0, 600.0, -9000.0)
## Audio/lighting ramp: outer calm → inner hot (km from BH).
const BH_OUTER_ZONE_UNITS := 8000.0
const BH_INNER_ZONE_UNITS := 2500.0


static func sector_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(pos.x / SECTOR_EDGE_UNITS)),
		int(floor(pos.y / SECTOR_EDGE_UNITS)),
		int(floor(pos.z / SECTOR_EDGE_UNITS)),
	)


static func chebyshev_from_origin(sector: Vector3i) -> int:
	return maxi(absi(sector.x), maxi(absi(sector.y), absi(sector.z)))


static func format_distance(units: float) -> String:
	var km: float = units / UNITS_PER_KM
	if km < 1000.0:
		return "%.0f km" % km
	return "%.2f Mm" % (km / 1000.0)


static func format_position(pos: Vector3) -> String:
	return "(%.0f, %.0f, %.0f) km" % [pos.x, pos.y, pos.z]
