// Minimal procedural starfield sky, so the gravitational lensing has
// background detail to bend. Presentation only; no physics.
shader_type sky;

float hash13(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

void sky() {
    vec3 d = normalize(EYEDIR);

    // Quantize the view direction into cells; a sparse subset of cells host a
    // star, each with a stable brightness and a slow twinkle.
    vec3 cell = floor(d * 350.0);
    float h = hash13(cell);
    float star = smoothstep(0.9965, 1.0, h);
    float twinkle = 0.6 + 0.4 * sin(TIME * 1.5 + h * 6.2831);
    float brightness = star * twinkle * (0.4 + h * 1.4);

    // Cool stars vs warm stars for a little variety.
    vec3 star_tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.9, 0.75), hash13(cell + 7.0));

    // Faint band of "galactic" glow plus a near-black base.
    float band = exp(-pow(d.y * 3.0, 2.0)) * 0.05;
    vec3 nebula = vec3(0.02, 0.025, 0.05) + vec3(0.06, 0.04, 0.08) * band;

    COLOR = nebula + star_tint * brightness;
}
