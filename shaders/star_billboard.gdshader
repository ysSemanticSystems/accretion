// Distant host star billboard — presentation only.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform sampler2D corona_texture : filter_linear, repeat_disable;
uniform vec4 star_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float corona_boost = 1.35;

void fragment() {
	vec4 tex = texture(corona_texture, UV);
	float glow = tex.a * corona_boost;
	ALBEDO = star_color.rgb * glow;
	ALPHA = glow * star_color.a;
}
