extends Node
## Origin home depot — auto-deposit cargo in range. Spec: wiki/features/F004-home-depot-progression.md

signal deposited(mass: float)

@export var deposit_radius := 80.0
@export var depot_position := Vector3.ZERO
@export var ship_path: NodePath = ^"../ShipBody"
@export var cargo_path: NodePath = ^"../CargoHold"
@export var progression_path: NodePath = ^"../Progression"

var _ship: Node3D
var _cargo: Node
var _progression: Node


func _ready() -> void:
	_ship = get_node_or_null(ship_path) as Node3D
	_cargo = get_node_or_null(cargo_path)
	_progression = get_node_or_null(progression_path)


func _process(_delta: float) -> void:
	if _ship == null or _cargo == null or _progression == null:
		return
	var held: float = _cargo.current_mass
	if held <= 0.01:
		return
	if _ship.global_position.distance_to(depot_position) > deposit_radius:
		return
	_try_deposit(held)


func _try_deposit(mass: float) -> void:
	_cargo.clear_all()
	_progression.add_banked(mass)
	deposited.emit(mass)
