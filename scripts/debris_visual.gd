extends Node3D
## Random low-poly rock mesh for harvestable debris (presentation only).

const DEBRIS_SCENES: Array[PackedScene] = [
	preload("res://assets/debris/debris_02.glb"),
	preload("res://assets/debris/rock_OQvi8PIZ40.glb"),
]

@export var target_size := 0.45


func _ready() -> void:
	if DEBRIS_SCENES.is_empty():
		return
	var scene: PackedScene = DEBRIS_SCENES.pick_random()
	var model: Node3D = scene.instantiate() as Node3D
	if model == null:
		return
	add_child(model)
	call_deferred("_fit_and_tint", model)


func _fit_and_tint(model: Node3D) -> void:
	var aabb: AABB = _combined_aabb(model)
	if aabb.size.length_squared() < 1.0e-8:
		return
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var jitter: float = randf_range(0.85, 1.15)
	var factor: float = (target_size * jitter) / max(longest, 1.0e-4)
	model.scale = Vector3.ONE * factor
	_apply_emissive_tint(model)


func _combined_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		var local: AABB = vi.get_aabb()
		if local.size.length_squared() < 1.0e-8:
			continue
		var xf: Transform3D = root.global_transform.affine_inverse() * vi.global_transform
		var world_box: AABB = xf * local
		if first:
			merged = world_box
			first = false
		else:
			merged = merged.merge(world_box)
	return merged


func _apply_emissive_tint(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var mat: Material = mi.get_surface_override_material(i)
			if mat == null and mi.mesh:
				mat = mi.mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				var dup: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
				dup.emission_enabled = true
				dup.emission = Color(0.95, 0.5, 0.15)
				dup.emission_energy_multiplier = 0.35
				mi.set_surface_override_material(i, dup)
	for child in node.get_children():
		_apply_emissive_tint(child)
