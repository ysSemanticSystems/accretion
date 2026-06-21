extends Node3D
## Random low-poly rock mesh for harvestable debris (presentation only).

const DEBRIS_SCENES: Array[PackedScene] = [
	preload("res://assets/debris/debris_02.glb"),
	preload("res://assets/debris/rock_OQvi8PIZ40.glb"),
]

@export var target_size := 12.0


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
	_apply_rock_material(model)


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


## Real PBR rock: no self-emission. Let the warm BH key + cool rim sculpt form.
## We keep the GLB albedo/normal where present and only fix roughness/metallic so
## surfaces read as rough rock rather than flat shadeless clay.
func _apply_rock_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var surfaces: int = 0
		if mi.mesh != null:
			surfaces = mi.mesh.get_surface_count()
		surfaces = maxi(surfaces, mi.get_surface_override_material_count())
		for i in surfaces:
			var mat: Material = mi.get_surface_override_material(i)
			if mat == null and mi.mesh != null:
				mat = mi.mesh.surface_get_material(i)
			var rock: StandardMaterial3D
			if mat is StandardMaterial3D:
				rock = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			else:
				rock = StandardMaterial3D.new()
				rock.albedo_color = Color(0.42, 0.34, 0.28)
			rock.emission_enabled = false
			rock.metallic = 0.04
			rock.metallic_specular = 0.4
			rock.roughness = 0.92
			rock.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			rock.ao_light_affect = 1.0
			mi.set_surface_override_material(i, rock)
	for child in node.get_children():
		_apply_rock_material(child)
