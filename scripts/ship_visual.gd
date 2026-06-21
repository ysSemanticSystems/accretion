extends Node3D
## Player ship mesh + subtle engine glow (presentation only).

const SHIP_SCENE := preload("res://assets/ships/player_ship.glb")

@export var target_length := 1.7


func _ready() -> void:
	var model: Node3D = SHIP_SCENE.instantiate() as Node3D
	if model == null:
		return
	add_child(model)
	model.rotation_degrees.x = -90.0
	call_deferred("_fit_and_finish", model)


func _fit_and_finish(model: Node3D) -> void:
	var aabb: AABB = _combined_aabb(model)
	if aabb.size.length_squared() < 1.0e-8:
		push_warning("ShipVisual: empty mesh AABB")
		return
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var factor: float = target_length / max(longest, 1.0e-4)
	model.scale = Vector3.ONE * factor
	_apply_hull_material(model)
	_add_engine_glow()


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


func _apply_hull_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			return
		for i in mi.mesh.get_surface_count():
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.55, 0.62, 0.72)
			mat.metallic = 0.85
			mat.roughness = 0.38
			mat.emission_enabled = true
			mat.emission = Color(0.12, 0.35, 0.75)
			mat.emission_energy_multiplier = 0.25
			mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_hull_material(child)


func _add_engine_glow() -> void:
	var light := OmniLight3D.new()
	light.name = "EngineGlow"
	light.light_color = Color(0.35, 0.65, 1.0)
	light.light_energy = 0.35
	light.omni_range = 1.8
	light.position = Vector3(0, 0, 0.85)
	add_child(light)
