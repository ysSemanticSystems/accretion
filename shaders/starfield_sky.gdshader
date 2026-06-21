// Procedural deep-space sky — presentation only; no physics.
shader_type sky;

uniform vec3 nebula_tint : source_color = vec3(0.04, 0.05, 0.12);
uniform vec3 band_tint : source_color = vec3(0.14, 0.08, 0.22);
uniform vec3 disk_glow_dir = vec3(0.0, 0.04, -1.0);
uniform vec3 disk_glow_color : source_color = vec3(1.0, 0.42, 0.12);
uniform float disk_glow_strength = 0.42;
uniform float star_density = 380.0;
uniform float star_threshold = 0.9962;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 d = normalize(EYEDIR);

	vec3 cell = floor(d * star_density);
	float h = hash13(cell);
	float star = smoothstep(star_threshold, 1.0, h);
	float twinkle = 0.55 + 0.45 * sin(TIME * 1.2 + h * 6.2831);
	float brightness = star * twinkle * (0.35 + h * 1.6);

	vec3 cool = vec3(0.72, 0.84, 1.0);
	vec3 warm = vec3(1.0, 0.88, 0.72);
	vec3 star_tint = mix(cool, warm, hash13(cell + 7.0));

	float band = exp(-pow(d.y * 2.4, 2.0));
	vec3 nebula = nebula_tint + band_tint * band * 0.35;

	vec3 glow_dir = normalize(disk_glow_dir);
	float toward_disk = max(dot(d, glow_dir), 0.0);
	vec3 disk_glow = disk_glow_color * pow(toward_disk, 2.8) * disk_glow_strength;

	float warm_blob = exp(-length(d.xz + glow_dir.xz * 0.15) * 2.2);
	warm_blob *= exp(-abs(d.y - glow_dir.y * 0.25) * 2.0);
	vec3 inner_nebula = vec3(0.85, 0.35, 0.12) * warm_blob * 0.18;

	vec3 cell2 = floor(d * (star_density * 0.55));
	float h2 = hash13(cell2 + 13.0);
	float star2 = smoothstep(0.9985, 1.0, h2) * 0.45;

	vec3 col = nebula + inner_nebula + disk_glow + star_tint * brightness + vec3(0.9, 0.92, 1.0) * star2;
	COLOR = col;
}
