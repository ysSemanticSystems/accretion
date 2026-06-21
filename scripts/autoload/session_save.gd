extends Node
## Active-run snapshot + profile stats. Spec: wiki/features/F012-milestone-ladder-victory.md

const WorldScale = preload("res://scripts/world_scale.gd")
const ACTIVE_PATH := "user://active_run.cfg"
const PROFILE_PATH := "user://profile.cfg"

var has_active_run: bool = false
var deepest_approach_zone: int = 0
var closest_bh_km: float = -1.0
var last_seed: int = 0
var last_banked: float = 0.0
var total_runs: int = 0

var _active: Dictionary = {}


func _ready() -> void:
	_load_profile()


func profile_line() -> String:
	if total_runs <= 0:
		return "New pilots welcome — fly inward toward M87*"
	var closest_text := "no approach logged yet"
	if closest_bh_km >= 0.0:
		closest_text = "closest M87* %s" % WorldScale.format_distance(
			closest_bh_km * WorldScale.UNITS_PER_KM
		)
	return "%s · last seed %d · %d runs" % [closest_text, last_seed, total_runs]


func active_snapshot() -> Dictionary:
	return _active.duplicate(true)


func save_active_run(snapshot: Dictionary) -> void:
	_active = snapshot.duplicate(true)
	has_active_run = true
	var cfg := ConfigFile.new()
	for key in snapshot.keys():
		cfg.set_value("active", key, snapshot[key])
	cfg.save(ACTIVE_PATH)


func clear_active_run() -> void:
	has_active_run = false
	_active.clear()
	if FileAccess.file_exists(ACTIVE_PATH):
		DirAccess.remove_absolute(ACTIVE_PATH)


func record_completed_run(stats: Dictionary) -> void:
	total_runs += 1
	last_seed = int(stats.get("seed", 0))
	last_banked = float(stats.get("banked", 0.0))
	var run_closest: float = float(stats.get("closest_bh_km", -1.0))
	if run_closest >= 0.0:
		if closest_bh_km < 0.0:
			closest_bh_km = run_closest
		else:
			closest_bh_km = minf(closest_bh_km, run_closest)
	var approach: int = int(stats.get("deepest_approach_zone", 0))
	if approach <= 0 and run_closest >= 0.0:
		approach = WorldScale.approach_zone_for_distance(run_closest)
	deepest_approach_zone = maxi(deepest_approach_zone, approach)
	_save_profile()


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) != OK:
		return
	deepest_approach_zone = int(cfg.get_value("profile", "deepest_approach_zone", 0))
	closest_bh_km = float(cfg.get_value("profile", "closest_bh_km", -1.0))
	last_seed = int(cfg.get_value("profile", "last_seed", 0))
	last_banked = float(cfg.get_value("profile", "last_banked", 0.0))
	total_runs = int(cfg.get_value("profile", "total_runs", 0))
	if cfg.load(ACTIVE_PATH) == OK:
		has_active_run = true
		_active.clear()
		for key in cfg.get_section_keys("active"):
			_active[key] = cfg.get_value("active", key)


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "deepest_approach_zone", deepest_approach_zone)
	cfg.set_value("profile", "closest_bh_km", closest_bh_km)
	cfg.set_value("profile", "last_seed", last_seed)
	cfg.set_value("profile", "last_banked", last_banked)
	cfg.set_value("profile", "total_runs", total_runs)
	cfg.save(PROFILE_PATH)


func load_active_into_cfg() -> Dictionary:
	if not has_active_run:
		return {}
	return _active.duplicate(true)
