extends Node
## Per-run statistics for the exploration log. Spec: wiki/features/F008-game-shell.md

var run_seed: int = 0
var banked_mass: float = 0.0
var sectors_visited: Dictionary = {}
var upgrades_bought: int = 0
var max_chebyshev: int = 0
var closest_bh_km: float = -1.0
var deepest_approach_zone: int = 0
var elapsed_sec: float = 0.0
var _running := false


func begin_run(seed: int) -> void:
	run_seed = seed
	banked_mass = 0.0
	sectors_visited.clear()
	upgrades_bought = 0
	max_chebyshev = 0
	closest_bh_km = -1.0
	deepest_approach_zone = 0
	elapsed_sec = 0.0
	_running = true
	_emit()


func end_run() -> void:
	_running = false
	_emit()


func _process(delta: float) -> void:
	if not _running:
		return
	elapsed_sec += delta


func note_sector(sector: Vector3i) -> void:
	sectors_visited[_key(sector)] = true
	_emit()


func note_position(pos: Vector3) -> void:
	const WorldScale = preload("res://scripts/world_scale.gd")
	var sector := WorldScale.sector_coords(pos)
	note_sector(sector)
	var dist: int = maxi(absi(sector.x), maxi(absi(sector.y), absi(sector.z)))
	max_chebyshev = maxi(max_chebyshev, dist)
	_emit()


func note_banked(total: float, _delta: float) -> void:
	banked_mass = total
	_emit()


func note_upgrade(_kind: int, _level: int) -> void:
	upgrades_bought += 1
	_emit()


func note_bh_distance(dist_km: float) -> void:
	if closest_bh_km < 0.0 or dist_km < closest_bh_km:
		closest_bh_km = dist_km
		_emit()


func note_approach_zone(zone: int) -> void:
	deepest_approach_zone = maxi(deepest_approach_zone, zone)
	_emit()


func summary_dict() -> Dictionary:
	return {
		"seed": run_seed,
		"banked": banked_mass,
		"sectors": sectors_visited.size(),
		"upgrades": upgrades_bought,
		"max_distance": max_chebyshev,
		"closest_bh_km": closest_bh_km,
		"deepest_approach_zone": deepest_approach_zone,
		"time_sec": elapsed_sec,
	}


func _emit() -> void:
	GameEvents.run_stats_updated.emit(summary_dict())


func _key(sector: Vector3i) -> String:
	return "%d,%d,%d" % [sector.x, sector.y, sector.z]
