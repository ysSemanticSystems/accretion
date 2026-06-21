extends RefCounted
## Shared black-hole disk shader sync (presentation only). Used by main.gd and explore BH.

const OUTER_RG := 14.0
const GRADIENT_OUTER_RISCO := 14.0


static func update_disk_material(
	bh: Node,
	mat: ShaderMaterial,
	proximity: float = 1.0,
	interior: float = 0.0,
) -> void:
	if bh == null or mat == null:
		return
	var isco_rg: float = bh.call("isco_in_rg")
	var horizon_rg: float = bh.call("horizon_in_rg")
	var f_qpo: float = bh.call("isco_orbital_frequency_hz")

	mat.set_shader_parameter("inner_color", bh.call("disk_color_at", 1.0))
	mat.set_shader_parameter("disc_color", bh.call("disk_color_at", GRADIENT_OUTER_RISCO))
	mat.set_shader_parameter("disc_inner_radius", clamp(isco_rg / OUTER_RG, 0.05, 0.6))
	mat.set_shader_parameter("ss_radius", clamp(horizon_rg / OUTER_RG, 0.02, 0.3))

	var t_in: float = bh.call("disk_inner_temp_k")
	var log_t: float = clamp(log(max(t_in, 1.0)) / log(10.0), 4.0, 7.5)
	var emission: float = remap(log_t, 4.0, 7.5, 0.6, 3.2)
	mat.set_shader_parameter("emission_strength", lerpf(emission * 0.45, emission * 1.08, proximity))
	mat.set_shader_parameter("view_shadow_strength", lerpf(0.92, 0.18, proximity))
	mat.set_shader_parameter("interior_strength", interior)
	mat.set_shader_parameter("turbulence_intensity", lerpf(0.1, 0.2, proximity))
	mat.set_shader_parameter("turbulence_octaves", int(lerpf(2.0, 3.0, proximity)))
	mat.set_shader_parameter("ray_steps", int(lerpf(224.0, 448.0, proximity)))
	mat.set_shader_parameter("step_size", lerpf(0.065, 0.038, proximity))
	mat.set_shader_parameter("doppler_beaming_factor", lerpf(58.0, 88.0, proximity))
	mat.set_shader_parameter("g_const", lerpf(0.32, 0.44, proximity))
	mat.set_shader_parameter("disc_speed", clamp(log(max(f_qpo, 1.0e-12)) / log(10.0) + 2.5, 0.8, 4.0))
	mat.set_shader_parameter("qpo_phase_rate", clamp(f_qpo * 0.02, 0.4, 6.0))
