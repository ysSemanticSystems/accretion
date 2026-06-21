extends Node3D
## Forward tractor pull + forgiving intake. Spec: wiki/features/F002-tractor-cargo.md

signal target_changed(debris: Node3D)
signal collected(mass: float, material_id: String, world_pos: Vector3)

@export var tractor_range := 180.0
@export var tractor_cone_deg := 42.0
@export var vacuum_range := 70.0
@export var pull_accel := 85.0
@export var collect_radius := 45.0

@onready var ship_body: Node3D = get_parent()
@onready var cargo: Node = $"../../CargoHold"
@onready var beam_mesh: MeshInstance3D = $BeamVisual

var active_target: Node3D = null
var _beam_material: StandardMaterial3D


func _ready() -> void:
	_beam_material = StandardMaterial3D.new()
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.albedo_color = Color(0.35, 0.85, 1.0, 0.65)
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_material.emission_enabled = true
	_beam_material.emission = Color(0.2, 0.7, 1.0)
	_beam_material.emission_energy_multiplier = 0.9
	if beam_mesh:
		beam_mesh.material_override = _beam_material
		beam_mesh.visible = false


func _process(delta: float) -> void:
	if ship_body == null:
		return
	var tractoring := Input.is_action_pressed("ship_tractor") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if cargo != null and cargo.is_full():
		_clear_target()
		_hide_beam()
		return
	if tractoring:
		_tractor_tick(delta)
	else:
		_clear_target()
		_hide_beam()


func _tractor_tick(delta: float) -> void:
	var target: Node3D = _pick_target()
	_set_target(target)
	if target == null:
		_hide_beam()
		return
	target.apply_tractor_pull(ship_body.global_position, pull_accel, collect_radius, delta)
	_update_beam(target.global_position)
	var mat: String = target.material_id
	var amount: float = target.mass
	var pos: Vector3 = target.global_position
	if target.try_collect(cargo, ship_body.global_position, collect_radius):
		collected.emit(amount, mat, pos)
		_clear_target()
		_hide_beam()


func _pick_target() -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	var forward: Vector3 = -ship_body.global_transform.basis.z.normalized()
	var cos_limit: float = cos(deg_to_rad(tractor_cone_deg * 0.5))
	var origin: Vector3 = ship_body.global_position
	for node in get_tree().get_nodes_in_group("harvestable"):
		if not node.has_method("is_harvestable") or not node.is_harvestable():
			continue
		var offset: Vector3 = node.global_position - origin
		var dist: float = offset.length()
		if dist > tractor_range or dist < 0.1:
			continue
		if dist <= vacuum_range:
			if dist < best_score:
				best_score = dist
				best = node
			continue
		var dir: Vector3 = offset / dist
		if forward.dot(dir) < cos_limit:
			continue
		if dist < best_score:
			best_score = dist
			best = node
	return best


func _set_target(debris: Node3D) -> void:
	if active_target == debris:
		return
	active_target = debris
	target_changed.emit(debris)


func _clear_target() -> void:
	if active_target == null:
		return
	active_target = null
	target_changed.emit(null)


func _update_beam(target_pos: Vector3) -> void:
	if beam_mesh == null or ship_body == null:
		return
	var start: Vector3 = ship_body.global_position
	var end: Vector3 = target_pos
	var delta_vec: Vector3 = end - start
	var length: float = delta_vec.length()
	if length < 0.05:
		_hide_beam()
		return
	beam_mesh.visible = true
	beam_mesh.global_position = start + delta_vec * 0.5
	beam_mesh.look_at(end, Vector3.UP)
	var cyl := beam_mesh.mesh as CylinderMesh
	if cyl == null:
		return
	cyl.height = length
	beam_mesh.scale = Vector3(1.0, 1.0, 1.0)


func _hide_beam() -> void:
	if beam_mesh:
		beam_mesh.visible = false
