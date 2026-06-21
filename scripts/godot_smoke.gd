extends Node
## Headless GDExtension smoke test — every BlackHole API used by main.gd.
##
## Run: make godot-smoke  (or godot --headless --path . res://scenes/GodotSmoke.tscn)

const GRADIENT_OUTER_RISCO := 14.0


func _ready() -> void:
	var exit_code := _run()
	get_tree().quit(exit_code)


func _run() -> int:
	if not ClassDB.class_exists("BlackHole"):
		push_error("BlackHole GDExtension class not registered — run `make build` first")
		return 1

	var bh: Node = ClassDB.instantiate("BlackHole")
	if bh == null:
		push_error("Failed to instantiate BlackHole")
		return 1
	add_child(bh)

	bh.set("mass_solar", 21.0)
	bh.set("mdot_gs", 8.0e17)
	bh.set("spin", 0.0)

	var methods := [
		"l_eddington",
		"luminosity_erg_s",
		"eddington_ratio",
		"isco_in_rg",
		"schwarzschild_radius_cm",
		"disk_inner_temp_k",
		"isco_orbital_frequency_hz",
		"salpeter_time_s",
		"mdot_at_eddington",
		"disk_inner_color",
		"integrity_rate",
	]
	for method in methods:
		if not bh.has_method(method):
			push_error("Missing BlackHole method: %s (stale libgodot_ext.dylib? run `make build`)" % method)
			return 1

	var t_salpeter: float = bh.call("salpeter_time_s")
	if not is_finite(t_salpeter) or t_salpeter <= 0.0:
		push_error("salpeter_time_s returned invalid value: %s" % t_salpeter)
		return 1

	var dt := t_salpeter * 0.01
	var new_mass: float = bh.call("advance_mass", dt)
	if not is_finite(new_mass) or new_mass <= 0.0:
		push_error("advance_mass returned invalid value: %s" % new_mass)
		return 1
	bh.set("mass_solar", new_mass)

	var new_spin: float = bh.call("advance_spin", dt)
	if not is_finite(new_spin):
		push_error("advance_spin returned invalid value: %s" % new_spin)
		return 1
	bh.set("spin", new_spin)

	var eta: float = bh.get("efficiency")
	if not is_finite(eta) or eta <= 0.0 or eta >= 1.0:
		push_error("efficiency out of range after spin sync: %s" % eta)
		return 1

	var rate: float = bh.call("integrity_rate")
	if not is_finite(rate):
		push_error("integrity_rate returned NaN")
		return 1

	var inner: Color = bh.call("disk_color_at", 1.0)
	var outer: Color = bh.call("disk_color_at", GRADIENT_OUTER_RISCO)
	if inner.r + inner.g + inner.b <= 0.0:
		push_error("disk_color_at(1.0) returned black")
		return 1

	print(
		"[godot_smoke] OK mass=", new_mass,
		" spin=", new_spin,
		" eta=", eta,
		" salpeter_s=", t_salpeter,
		" integrity=", rate
	)
	return 0
