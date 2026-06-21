extends Node
## Session progression — banked mass and ship upgrades. Spec: wiki/features/F004-home-depot-progression.md

enum UpgradeKind { CARGO, TRACTOR, CRUISE }

signal progression_changed
signal upgrade_purchased(kind: UpgradeKind, level: int)

const MAX_LEVEL := 2

@export var cargo_path: NodePath = ^"../CargoHold"
@export var tractor_path: NodePath = ^"../ShipBody/TractorBeam"
@export var ship_path: NodePath = ^"../ShipBody"

@export var base_cargo_mass := 500.0
@export var cargo_mass_per_level := 100.0
@export var cargo_costs: Array[float] = [150.0, 350.0]

@export var tractor_range_per_level := 40.0
@export var tractor_costs: Array[float] = [120.0, 280.0]
@export var base_tractor_range := 180.0

@export var cruise_accel_per_level := 0.25
@export var cruise_costs: Array[float] = [200.0, 450.0]

var banked_mass: float = 0.0
var cargo_level: int = 0
var tractor_level: int = 0
var cruise_level: int = 0
var selected_upgrade: UpgradeKind = UpgradeKind.CARGO

var _cargo: Node
var _tractor: Node
var _ship: Node


func _ready() -> void:
	_cargo = get_node_or_null(cargo_path)
	_tractor = get_node_or_null(tractor_path)
	_ship = get_node_or_null(ship_path)
	_apply_all()


func add_banked(mass: float) -> void:
	if mass <= 0.0:
		return
	banked_mass += mass
	GameEvents.mass_banked.emit(banked_mass, mass)
	progression_changed.emit()


func cycle_upgrade_selection() -> void:
	selected_upgrade = ((int(selected_upgrade) + 1) % 3) as UpgradeKind
	progression_changed.emit()


func try_purchase() -> bool:
	return try_purchase_at_depot(false)


func try_purchase_at_depot(require_depot: bool) -> bool:
	if require_depot:
		var depot := get_parent().get_node_or_null("HomeDepot")
		if depot == null or not depot.is_at_depot():
			return false
	var kind := selected_upgrade
	var level := _level_for(kind)
	if level >= MAX_LEVEL:
		return false
	var cost := _cost_for(kind, level)
	if banked_mass < cost:
		return false
	banked_mass -= cost
	match kind:
		UpgradeKind.CARGO:
			cargo_level += 1
		UpgradeKind.TRACTOR:
			tractor_level += 1
		UpgradeKind.CRUISE:
			cruise_level += 1
	_apply_all()
	upgrade_purchased.emit(kind, _level_for(kind))
	GameEvents.upgrade_bought.emit(kind, _level_for(kind))
	GameEvents.mass_banked.emit(banked_mass, -cost)
	GameEvents.toast.emit("%s → Lv %d" % [track_name(kind), _level_for(kind)])
	RunTracker.note_upgrade(kind, _level_for(kind))
	progression_changed.emit()
	var root := get_parent()
	if root != null and root.has_method("persist_run"):
		root.persist_run()
	return true


func try_purchase_track(kind: int) -> bool:
	selected_upgrade = kind as UpgradeKind
	return try_purchase_at_depot(true)


func track_level(kind: int) -> int:
	return _level_for(kind as UpgradeKind)


func track_cost(kind: int) -> float:
	return _cost_for(kind as UpgradeKind, _level_for(kind as UpgradeKind))


func track_name(kind: int) -> String:
	var names := ["Cargo Hold", "Tractor", "Cruise Drive"]
	return names[kind] if kind >= 0 and kind < names.size() else "Upgrade"


func total_upgrades() -> int:
	return cargo_level + tractor_level + cruise_level


func max_upgrades() -> int:
	return (MAX_LEVEL + 1) * 3


func is_fully_upgraded() -> bool:
	return cargo_level >= MAX_LEVEL and tractor_level >= MAX_LEVEL and cruise_level >= MAX_LEVEL


func export_state() -> Dictionary:
	return {
		"banked_mass": banked_mass,
		"cargo_level": cargo_level,
		"tractor_level": tractor_level,
		"cruise_level": cruise_level,
	}


func restore_state(data: Dictionary) -> void:
	banked_mass = float(data.get("banked_mass", 0.0))
	cargo_level = int(data.get("cargo_level", 0))
	tractor_level = int(data.get("tractor_level", 0))
	cruise_level = int(data.get("cruise_level", 0))
	_apply_all()
	GameEvents.mass_banked.emit(banked_mass, 0.0)
	progression_changed.emit()


func cargo_capacity() -> float:
	return base_cargo_mass + cargo_level * cargo_mass_per_level


func tractor_range() -> float:
	return base_tractor_range + tractor_level * tractor_range_per_level


func cruise_accel_multiplier() -> float:
	return 1.0 + cruise_level * cruise_accel_per_level


func selection_label() -> String:
	var names := ["Cargo +100u", "Tractor +40km", "Cruise +25%"]
	return names[selected_upgrade]


func selection_cost() -> float:
	return _cost_for(selected_upgrade, _level_for(selected_upgrade))


func selection_level() -> int:
	return _level_for(selected_upgrade)


func _level_for(kind: UpgradeKind) -> int:
	match kind:
		UpgradeKind.CARGO:
			return cargo_level
		UpgradeKind.TRACTOR:
			return tractor_level
		UpgradeKind.CRUISE:
			return cruise_level
	return 0


func _cost_for(kind: UpgradeKind, level: int) -> float:
	if level >= MAX_LEVEL:
		return INF
	match kind:
		UpgradeKind.CARGO:
			return cargo_costs[level] if level < cargo_costs.size() else INF
		UpgradeKind.TRACTOR:
			return tractor_costs[level] if level < tractor_costs.size() else INF
		UpgradeKind.CRUISE:
			return cruise_costs[level] if level < cruise_costs.size() else INF
	return INF


func _apply_all() -> void:
	if _cargo != null and _cargo.has_method("set_max_mass"):
		_cargo.set_max_mass(cargo_capacity())
	if _tractor != null:
		_tractor.tractor_range = tractor_range()
	if _ship != null and _ship.has_method("set_cruise_accel_multiplier"):
		_ship.set_cruise_accel_multiplier(cruise_accel_multiplier())
