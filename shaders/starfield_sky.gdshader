// Procedural deep-space sky — presentation only; no physics.
shader_type sky;

uniform vec3 nebula_tint : source_color = vec3(0.04, 0.05, 0.12);
uniform vec3 band_tint : source_color = vec3(0.14, 0.08, 0.22);
uniform float nebula_strength = 1.0;
// Direction of the distant accretion core (galactic-center glow).
uniform vec3 disk_glow_dir = vec3(0.0, 0.067, -1.0);
uniform vec3 disk_glow_color : source_color = vec3(1.0, 0.42, 0.12);
uniform vec3 core_color : source_color = vec3(1.0, 0.85, 0.6);
uniform float disk_glow_strength = 0.9;
uniform float star_density = 380.0;
uniform float star_threshold = 0.9962;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

// Smooth value noise on the sphere direction.
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 glow_dir = normalize(disk_glow_dir);

	// --- Nebula clouds with real structure (fbm), pooled along the band and core.
	float band = exp(-pow(d.y * 2.2, 2.0));
	float clouds = fbm(d * 3.4 + vec3(11.0, 3.0, 7.0));
	clouds = smoothstep(0.35, 0.95, clouds);
	float detail = fbm(d * 8.0);
	clouds *= 0.6 + 0.6 * detail;
	vec3 nebula = nebula_tint + band_tint * (band * 0.5 + clouds * 0.7) * nebula_strength;

	// --- Distant accretion core: broad warm halo + hot core, biased to glow_dir.
	float toward = max(dot(d, glow_dir), 0.0);
	float halo = pow(toward, 1.6);
	float core = pow(toward, 26.0);
	// Warm clouds intensify toward the core for a believable galactic glow.
	float warm_clouds = clouds * pow(toward, 2.5);
	vec3 disk_glow = disk_glow_color * (halo * disk_glow_strength + warm_clouds * 0.6);
	disk_glow += core_color * core * 1.4;

	// --- Stars: two layers with size + brightness + colour variation, twinkle.
	vec3 cell = floor(d * star_density);
	float h = hash13(cell);
	float star = smoothstep(star_threshold, 1.0, h);
	float twinkle = 0.6 + 0.4 * sin(TIME * 1.1 + h * 6.2831);
	float bright = star * twinkle * (0.3 + h * 1.8);

	vec3 cell2 = floor(d * (star_density * 0.5));
	float h2 = hash13(cell2 + 13.0);
	float star2 = smoothstep(0.9986, 1.0, h2) * (0.5 + h2);

	vec3 cool = vec3(0.72, 0.84, 1.0);
	vec3 warm = vec3(1.0, 0.86, 0.7);
	vec3 tintA = mix(cool, warm, hash13(cell + 7.0));
	vec3 tintB = mix(cool, warm, hash13(cell2 + 5.0));

	// Stars dim where the core glow washes them out.
	float wash = clamp(1.0 - halo * 0.7, 0.2, 1.0);

	vec3 col = nebula + disk_glow;
	col += tintA * bright * wash;
	col += tintB * star2 * wash;
	COLOR = col;
}
