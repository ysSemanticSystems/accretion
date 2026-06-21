extends RefCounted
## Shared black-hole disk shader sync (presentation only). Used by main.gd and explore BH.

const OUTER_RG := 14.0
const GRADIENT_OUTER_RISCO := 14.0


static func update_disk_material(bh: Node, mat: ShaderMaterial) -> void:
	if bh == null or mat == null:
		return
	var spin: float = bh.get("spin")
	var isco_rg: float = bh.call("isco_in_rg")
	var horizon_rg := 1.0 + sqrt(max(1.0 - spin * spin, 0.0))
	var f_qpo: float = bh.call("isco_orbital_frequency_hz")

	mat.set_shader_parameter("inner_color", bh.call("disk_color_at", 1.0))
	mat.set_shader_parameter("disc_color", bh.call("disk_color_at", GRADIENT_OUTER_RISCO))
	mat.set_shader_parameter("disc_inner_radius", clamp(isco_rg / OUTER_RG, 0.05, 0.6))
	mat.set_shader_parameter("ss_radius", clamp(horizon_rg / OUTER_RG, 0.02, 0.3))

	var t_in: float = bh.call("disk_inner_temp_k")
	var log_t: float = clamp(log(max(t_in, 1.0)) / log(10.0), 4.0, 7.5)
	mat.set_shader_parameter("emission_strength", remap(log_t, 4.0, 7.5, 0.6, 3.2))
	mat.set_shader_parameter("disc_speed", clamp(log(max(f_qpo, 1.0e-12)) / log(10.0) + 2.5, 0.8, 4.0))
	mat.set_shader_parameter("qpo_phase_rate", clamp(f_qpo * 0.02, 0.4, 6.0))
