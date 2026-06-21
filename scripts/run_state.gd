extends Node
## Session run seed and sector depletion tracking. Spec: wiki/features/F005-seeded-sector-debris.md

signal sector_depleted(sector: Vector3i)

var run_seed: int = 0
var _depleted: Dictionary = {}


func _ready() -> void:
	run_seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	if run_seed == 0:
		run_seed = 1


func is_depleted(sector: Vector3i) -> bool:
	return _depleted.has(_sector_key(sector))


func mark_depleted(sector: Vector3i) -> void:
	var key := _sector_key(sector)
	if _depleted.has(key):
		return
	_depleted[key] = true
	sector_depleted.emit(sector)


func sector_rng(sector: Vector3i) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, sector.x, sector.y, sector.z])
	return rng


func _sector_key(sector: Vector3i) -> String:
	return "%d,%d,%d" % [sector.x, sector.y, sector.z]
