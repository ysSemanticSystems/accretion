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
