class_name RunScore
extends RefCounted
## Run scoring and persisted high score (presentation only).

const SAVE_PATH := "user://accretion_best.run"

static func compute(mass_msun: float, milestones: int, disruptions: int, sim_years: float) -> int:
	var mass_pts := int(max(log(max(mass_msun, 1.0)) / log(10.0), 0.0) * 1200.0)
	var milestone_pts := milestones * 800
	var survival_pts := int(min(sim_years, 1.0e12) / 1.0e6)  # 1 pt per Myr, capped
	var penalty := disruptions * 350
	return max(mass_pts + milestone_pts + survival_pts - penalty, 0)


static func load_best() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return 0
	var text := f.get_as_text().strip_edges()
	return int(text) if text.is_valid_int() else 0


static func save_best(score: int) -> bool:
	var best := load_best()
	if score <= best:
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(str(score))
	return true
