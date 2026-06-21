extends Node
## Ship cargo bay (presentation tuning). Spec: wiki/features/F002-tractor-cargo.md

signal cargo_changed(current_mass: float, max_mass: float)

@export var max_cargo_mass := 500.0
## Fraction of max speed removed at full cargo (0 = no penalty, 1 = stop).
@export var cargo_speed_penalty := 0.35

var current_mass: float = 0.0


func set_max_mass(maximum: float) -> void:
	max_cargo_mass = max(maximum, 1.0)
	if current_mass > max_cargo_mass:
		current_mass = max_cargo_mass
	cargo_changed.emit(current_mass, max_cargo_mass)
	GameEvents.cargo_changed.emit(current_mass, max_cargo_mass)


func clear_all() -> void:
	if current_mass <= 0.01:
		return
	current_mass = 0.0
	cargo_changed.emit(current_mass, max_cargo_mass)
	GameEvents.cargo_changed.emit(current_mass, max_cargo_mass)


func free_mass() -> float:
	return max(max_cargo_mass - current_mass, 0.0)


func is_full() -> bool:
	return current_mass >= max_cargo_mass - 0.01


func fill_ratio() -> float:
	if max_cargo_mass <= 0.0:
		return 0.0
	return clampf(current_mass / max_cargo_mass, 0.0, 1.0)


func speed_multiplier() -> float:
	return 1.0 - cargo_speed_penalty * fill_ratio()


func try_add(mass: float) -> float:
	if mass <= 0.0:
		return 0.0
	var taken: float = minf(mass, free_mass())
	if taken <= 0.0:
		return 0.0
	current_mass += taken
	cargo_changed.emit(current_mass, max_cargo_mass)
	GameEvents.cargo_changed.emit(current_mass, max_cargo_mass)
	return taken
