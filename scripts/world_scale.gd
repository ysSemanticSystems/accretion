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
const BH_DISK_MESH_SCALE := 2200.0
## Raymarch bounding sphere radius (unit sphere × this scale × 0.5).
const BH_VISUAL_SPHERE_RADIUS := BH_DISK_MESH_SCALE * 0.5
const BH_WORLD_POSITION := Vector3(0.0, 600.0, -9000.0)
## Host star — scene key light + sky point (G-type presentation colour). Opposite quadrant from BH.
const PRIMARY_STAR_POSITION := Vector3(14000.0, 8200.0, 10500.0)
## Audio/lighting ramp: outer calm → inner hot (km from BH).
const BH_OUTER_ZONE_UNITS := 8000.0
const BH_INNER_ZONE_UNITS := 2500.0
## Approach milestones — distance thresholds (km) from BH centre; index 0 = outermost gate.
const APPROACH_ZONE_DISTANCES := [7500.0, 5200.0, 3400.0, 1400.0]
const APPROACH_ZONE_COUNT := 4
const APPROACH_ZONE_LABELS := [
	"Outer wake",
	"Lensing field",
	"Photon halo",
	"Disk plane",
]


static func sector_coords(pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(pos.x / SECTOR_EDGE_UNITS)),
		int(floor(pos.y / SECTOR_EDGE_UNITS)),
		int(floor(pos.z / SECTOR_EDGE_UNITS)),
	)


static func chebyshev_from_origin(sector: Vector3i) -> int:
	return maxi(absi(sector.x), maxi(absi(sector.y), absi(sector.z)))


static func distance_to_bh_km(pos: Vector3) -> float:
	return pos.distance_to(BH_WORLD_POSITION) / UNITS_PER_KM


static func distance_to_bh(pos: Vector3) -> float:
	return pos.distance_to(BH_WORLD_POSITION)


static func is_inside_bh_volume(pos: Vector3) -> bool:
	return distance_to_bh(pos) < BH_VISUAL_SPHERE_RADIUS


static func bh_interior_blend(pos: Vector3) -> float:
	var r: float = distance_to_bh(pos)
	if r >= BH_VISUAL_SPHERE_RADIUS:
		return 0.0
	return clampf(1.0 - r / BH_VISUAL_SPHERE_RADIUS, 0.0, 1.0)


static func approach_zone_for_distance(dist_km: float) -> int:
	var zone := 0
	for threshold in APPROACH_ZONE_DISTANCES:
		if dist_km <= threshold:
			zone += 1
	return zone


static func next_approach_zone(current_zone: int) -> int:
	return mini(current_zone + 1, APPROACH_ZONE_COUNT)


static func approach_zone_label(zone: int) -> String:
	if zone <= 0:
		return "Deep space"
	var idx: int = mini(zone, APPROACH_ZONE_LABELS.size()) - 1
	return APPROACH_ZONE_LABELS[idx]


static func format_distance(units: float) -> String:
	var km: float = units / UNITS_PER_KM
	if km < 1000.0:
		return "%.0f km" % km
	return "%.2f Mm" % (km / 1000.0)


static func format_position(pos: Vector3) -> String:
	return "(%.0f, %.0f, %.0f) km" % [pos.x, pos.y, pos.z]
