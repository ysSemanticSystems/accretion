extends Node
## Signal bus — decouples gameplay from HUD/audio. Spec: wiki/architecture/game-shell.md

signal cargo_changed(current: float, maximum: float)
signal mass_banked(total: float, delta: float)
signal upgrade_bought(kind: int, level: int)
signal debris_collected(world_pos: Vector3, mass: float)
signal compass_target(world_pos: Vector3, dist: float, kind: String)
signal toast(text: String)
signal depot_docked(at_depot: bool)
signal tractor_state_changed(state: String)
signal run_stats_updated(stats: Dictionary)
signal sector_depleted(sector: Vector3i)
signal sector_ring_reached(ring: int, next_goal: int)
signal sector_goal_changed(goal: int)
signal milestone_updated(max_zone: int, next_zone: int, zone_count: int)
signal bh_interior_changed(inside: bool)
signal speed_band_changed(band: String)
