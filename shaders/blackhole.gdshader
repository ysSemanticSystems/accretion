/*
Copyright 2026 Tyler Kennedy

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Procedural Black Hole Shader
============================
Source: Tyler Kennedy, "Building a Black Hole Shader in Godot 4" (2026),
https://tkte.ch/articles/2026/01/15/godot-blackhole-shader.html

Mental model:
- Raymarch inside a bounding sphere, bending the ray toward the center.
- If the ray hits the event horizon, it is absorbed; if it hits the disc, it emits.
- The final ray direction warps the screen sample to create lensing.

This is a stylized effect with simple physics approximations.

ACCRETION-GAME MODIFICATION
---------------------------
The original hardcoded the disc's hot inner color as `vec3(1.0, 1.0, 0.95)`.
Here it is exposed as the `inner_color` uniform, which is driven every frame by
the BlackHole gdext node from `accretion_core::blackbody_rgb(T_inner)`. The disc
color is therefore computed in Rust from accretion-core disk temperature physics, not in the
shader. (Search "inner_color" for the two touched lines.)
*/

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D disc_texture : filter_linear, repeat_enable;
uniform float disc_outer_radius : hint_range(0.0, 1.0) = 1.0;
uniform float disc_inner_radius : hint_range(0.0, 1.0) = 0.25;
uniform float disc_speed : hint_range(0.0, 10.0) = 2.0;
uniform vec4 disc_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
// Driven from Rust (accretion_core::blackbody_rgb of the inner-edge temperature).
uniform vec4 inner_color : source_color = vec4(1.0, 1.0, 0.95, 1.0);
uniform float doppler_beaming_factor : hint_range(0.0, 200.0) = 66.0;
// Bounded HDR bloom factor; driven from Rust as a tone-map of the inner-edge
// temperature, so hotter disks visibly bloom brighter (presentation only).
uniform float emission_strength : hint_range(0.1, 6.0) = 1.0;
// ISCO orbital phase rate (Hz, presentation-scaled from Rust QPO frequency).
uniform float qpo_phase_rate : hint_range(0.0, 10.0) = 1.5;
uniform float hue_radius : hint_range(0.0, 1.0) = 0.75;
uniform float hue_shift_factor : hint_range(-1.0, 1.0) = -0.03;
uniform float streak_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float streak_count : hint_range(1.0, 50.0) = 20.0;

uniform float turbulence_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float turbulence_scale : hint_range(0.5, 10.0) = 3.0;
uniform float turbulence_speed : hint_range(0.0, 2.0) = 0.5;
uniform int turbulence_octaves : hint_range(1, 6) = 4;

uniform int ray_steps : hint_range(32, 512) = 256;
uniform float step_size : hint_range(0.001, 1.0) = 0.1;
uniform float ss_radius : hint_range(0.0, 1.0) = 0.1;
uniform float g_const : hint_range(0.0, 2.0) = 0.3;
// Stylized EHT shadow radius = horizon_frac * disc_radius * this scale (presentation).
uniform float eht_shadow_scale : hint_range(1.5, 4.0) = 2.6;
// Screen-centre shadow when viewing the BH from far away (0 = off).
uniform float view_shadow_strength : hint_range(0.0, 1.0) = 0.85;
// Camera inside the capture sphere — stylized infall view (presentation).
uniform float interior_strength : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

const float MAX_FLOAT = 3.402823466e+38;
const float SEAM_BLEND_START = 0.9;

varying vec3 frag_pos_ws;
varying vec3 centre;
varying vec3 object_scale;

void vertex() {
    frag_pos_ws = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    centre = MODEL_MATRIX[3].xyz;
    object_scale = vec3(
        length(MODEL_MATRIX[0].xyz),
        length(MODEL_MATRIX[1].xyz),
        length(MODEL_MATRIX[2].xyz)
    );
}

float hash(float n) { return fract(sin(n) * 43758.5453); }

float noise1d(float x) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), f);
}

float noise2d(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(dot(i, vec2(1.0, 157.0)));
    float b = hash(dot(i + vec2(1.0, 0.0), vec2(1.0, 157.0)));
    float c = hash(dot(i + vec2(0.0, 1.0), vec2(1.0, 157.0)));
    float d = hash(dot(i + vec2(1.0, 1.0), vec2(1.0, 157.0)));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float seamless_fbm_cylinder(float u, float v, float scale, float time, int octaves) {
    float angle = v * 2.0 * PI;
    vec3 cyl_pos = vec3(u * scale, cos(angle) * scale * 0.5, sin(angle) * scale * 0.5);
    cyl_pos.x += time;

    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < octaves; i++) {
        float n1 = noise2d(cyl_pos.xy * frequency);
        float n2 = noise2d(cyl_pos.xz * frequency + 100.0);
        value += amplitude * mix(n1, n2, 0.5);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

vec2 turbulent_displacement_seamless(float u, float v, float time, float scale, float intensity, int octaves) {
    vec2 offset = vec2(
        seamless_fbm_cylinder(u, v, scale, time * 0.7, octaves),
        seamless_fbm_cylinder(u, v + 0.37, scale, time * 0.5, octaves)
    );
    return (offset - 0.5) * intensity;
}

float seamless_noise1d(float x, float period) {
    float t = fract(x / period);
    float n1 = noise1d(x);
    float n2 = noise1d(x - period);
    return mix(n1, n2, smoothstep(SEAM_BLEND_START, 1.0, t));
}

float soft_edge(float radius_norm, float angle, float time) {
    float period = 2.0 * PI;
    float scaled_angle1 = angle * streak_count;
    float scaled_angle2 = angle * streak_count * 2.3 + 100.0;

    float edge_noise = seamless_noise1d(scaled_angle1 + time * 0.1, streak_count * period) * 0.5 + 0.5;
    float edge_noise2 = seamless_noise1d(scaled_angle2 + time * 0.15, streak_count * 2.3 * period) * 0.5 + 0.5;
    float combined_noise = edge_noise * 0.6 + edge_noise2 * 0.4;

    float falloff_start = 0.6 + combined_noise * streak_intensity * 0.4;
    float falloff = 1.0 - smoothstep(falloff_start, 1.0, radius_norm);

    return falloff;
}

vec2 intersect_sphere(vec3 ray_origin, vec3 ray_dir, vec3 sphere_centre, float radius) {
    vec3 offset = ray_origin - sphere_centre;
    float b = 2.0 * dot(offset, ray_dir);
    float c = dot(offset, offset) - radius * radius;
    float discriminant = b * b - 4.0 * c;

    if (discriminant > 0.0) {
        float s = sqrt(discriminant);
        float dst_near = max(0.0, (-b - s) * 0.5);
        float dst_far = (-b + s) * 0.5;
        if (dst_far >= 0.0) {
            return vec2(dst_near, dst_far - dst_near);
        }
    }
    return vec2(MAX_FLOAT, 0.0);
}

float remap(float v, float min_old, float max_old, float min_new, float max_new) {
    float denom = max_old - min_old;
    if (abs(denom) < 1e-6) {
        return min_new;
    }
    return min_new + (v - min_old) * (max_new - min_new) / denom;
}

vec2 disc_safe_radii() {
    float safe_outer = max(disc_outer_radius, 1e-4);
    float safe_inner = clamp(disc_inner_radius, 0.0, safe_outer - 1e-4);
    return vec2(safe_inner, safe_outer);
}

vec2 disc_uv(vec3 planar_disc_pos, float radius) {
    float sample_dist = length(planar_disc_pos) / max(radius, 1e-6);
    float phi = atan(planar_disc_pos.z, planar_disc_pos.x);
    phi = phi / (2.0 * PI) + 0.5;
    return vec2(sample_dist, phi);
}

vec3 linear_to_gamma(vec3 col) {
    col = max(col, vec3(0.0));
    return max(1.055 * pow(col, vec3(0.416666667)) - 0.055, vec3(0.0));
}

vec3 gamma_to_linear(vec3 col) {
    return col * (col * (col * 0.305306011 + 0.682171111) + 0.012522878);
}

vec3 hdr_intensity(vec3 col, float intensity) {
    col = linear_to_gamma(col);
    col *= pow(2.0, intensity);
    col = gamma_to_linear(col);
    return col;
}

vec3 rgb_to_hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rotate_about_axis(vec3 v, vec3 axis, float rotation) {
    float s = sin(rotation);
    float c = cos(rotation);
    float omc = 1.0 - c;
    axis = normalize(axis);
    mat3 rot = mat3(
        vec3(omc * axis.x * axis.x + c, omc * axis.x * axis.y + axis.z * s, omc * axis.z * axis.x - axis.y * s),
        vec3(omc * axis.x * axis.y - axis.z * s, omc * axis.y * axis.y + c, omc * axis.y * axis.z + axis.x * s),
        vec3(omc * axis.z * axis.x + axis.y * s, omc * axis.y * axis.z - axis.x * s, omc * axis.z * axis.z + c)
    );
    return rot * v;
}

vec3 calc_disc_color(vec3 base_color, vec3 planar_disc_pos, vec3 disc_dir, vec3 camera_pos, float u, float v, float radius, float time) {
    float radial_t = clamp(u, 0.0, 1.0);

    float turb_time = time * turbulence_speed;
    float turb_noise = seamless_fbm_cylinder(u * 2.0, v, turbulence_scale, turb_time, turbulence_octaves);

    vec2 swirl_offset = turbulent_displacement_seamless(u * 2.0, v, turb_time, turbulence_scale * 0.5, turbulence_intensity * 0.3, turbulence_octaves);
    float swirl_noise = seamless_fbm_cylinder(u * 2.0 + swirl_offset.x, v + swirl_offset.y, turbulence_scale * 1.5, turb_time * 0.5, turbulence_octaves);

    float combined_turb = mix(turb_noise, swirl_noise, 0.35);
    combined_turb = smoothstep(0.18, 0.82, combined_turb);
    float turb_intensity_mod = (combined_turb - 0.5) * turbulence_intensity * 0.35;

    float hot_spot = pow(max(0.0, combined_turb - 0.72) * 3.0, 2.0) * turbulence_intensity * 0.45;
    // Keplerian hotspot orbiting at the ISCO (QPO-scale flicker; phase rate from Rust).
    float qpo_angle = v * PI * 2.0 + TIME * qpo_phase_rate;
    float qpo_spot = pow(max(0.0, cos(qpo_angle) * 0.5 + 0.5), 6.0) * (1.0 - radial_t);
    hot_spot += qpo_spot * 0.28;

    // inner_color is the Rust-computed blackbody color of the disc inner edge.
    vec3 temp_color = mix(inner_color.rgb, base_color, pow(radial_t, 0.6));

    temp_color = mix(temp_color, inner_color.rgb, hot_spot * 0.5);

    float base_intensity = remap(radial_t, 0.0, 1.0, 1.35, -2.5);

    vec3 rotated_pos = rotate_about_axis(planar_disc_pos, disc_dir, 0.01);
    float safe_radius = max(radius, 1e-6);
    float doppler_dist = (length(rotated_pos - camera_pos) - length(planar_disc_pos - camera_pos)) / safe_radius;
    float doppler_contribution = doppler_dist * disc_speed * doppler_beaming_factor * (1.0 - radial_t * 0.7);

    float intensity = base_intensity + doppler_contribution + turb_intensity_mod + hot_spot * 0.75;
    // EHT-style azimuthal asymmetry (approaching side brighter; presentation stylized).
    float phi = atan(planar_disc_pos.z, planar_disc_pos.x);
    intensity += sin(phi + TIME * disc_speed * 0.04) * 0.14 * (1.0 - radial_t);

    intensity = clamp(intensity, -3.0, 3.0);

    vec3 new_color = hdr_intensity(temp_color, intensity);

    vec3 hsv = rgb_to_hsv(new_color);
    float hue_shift = clamp(remap(radial_t, hue_radius, 1.0, 0.0, 1.0), 0.0, 1.0);
    hue_shift += (combined_turb - 0.5) * turbulence_intensity * 0.1;
    hsv.x += hue_shift * hue_shift_factor;
    new_color = hsv_to_rgb(hsv);

    return new_color;
}

// EHT-inspired radial profile: dark shadow interior, bright photon ring, outer disc falloff.
vec3 apply_eht_disc_profile(vec3 disc_col, float r_norm, float horizon_frac, out float disc_weight) {
    float shadow_r = clamp(horizon_frac * eht_shadow_scale, 0.04, 0.92);
    float hole = smoothstep(shadow_r * 0.88, shadow_r * 1.06, r_norm);
    float ring_inner = shadow_r * 1.04;
    float ring_outer = shadow_r * 1.42;
    float photon_ring = smoothstep(ring_inner, ring_inner + shadow_r * 0.05, r_norm)
        * (1.0 - smoothstep(ring_outer - shadow_r * 0.08, ring_outer, r_norm));
    photon_ring = pow(photon_ring, 0.82);
    disc_weight *= hole;
    return disc_col * (0.28 + photon_ring * 3.4);
}

vec3 render_interior(vec3 ray_origin, vec3 ray_dir, float sphere_radius, vec2 screen_uv, float blend) {
    vec3 fall_dir = normalize(centre - ray_origin);
    vec2 centered = screen_uv - 0.5;
    float r = length(centered);
    float warp = blend * 2.2 / max(0.06, 1.0 - r * 1.05);
    vec2 warped_uv = clamp(0.5 + centered * (1.0 + warp), vec2(0.002), vec2(0.998));
    vec3 bg = texture(screen_texture, warped_uv).rgb;
    vec3 redshift = vec3(1.35, 0.82, 0.42);
    bg *= mix(vec3(1.0), redshift, blend * 0.72);
    float tunnel = pow(max(dot(ray_dir, fall_dir), 0.0), mix(1.2, 5.0, blend));
    float ring_echo = pow(clamp(r * 1.35, 0.0, 1.0), 1.1) * blend;
    vec3 col = bg * mix(0.12, 0.5, tunnel);
    col += vec3(1.0, 0.38, 0.1) * ring_echo * 1.35;
    col += vec3(0.12, 0.06, 0.22) * (1.0 - tunnel) * blend * 0.9;
    col *= mix(1.0, 0.25, pow(tunnel, 2.5) * blend);
    return col;
}

void fragment() {
    vec3 ray_origin = CAMERA_POSITION_WORLD;
    vec3 ray_dir = normalize(frag_pos_ws - ray_origin);

    float sphere_radius = 0.5 * min(min(object_scale.x, object_scale.y), object_scale.z);
    float cam_dist = length(ray_origin - centre);
    float interior_t = max(interior_strength, clamp(1.0 - cam_dist / max(sphere_radius, 1e-4), 0.0, 1.0));
    vec2 screen_uv = SCREEN_UV;

    if (interior_t > 0.02) {
        vec3 interior_col = render_interior(ray_origin, ray_dir, sphere_radius, screen_uv, interior_t);
        ALBEDO = interior_col;
        ALPHA = 1.0;
    } else {
    vec2 outer_sphere = intersect_sphere(ray_origin, ray_dir, centre, sphere_radius);
    bool has_sphere = outer_sphere.x < MAX_FLOAT;

    vec3 disc_dir = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
    vec2 radii = disc_safe_radii();
    float disc_radius = sphere_radius * radii.y;
    float inner_radius = sphere_radius * radii.x;
    float scaled_step = step_size * sphere_radius;

    float disc_hit = 0.0;
    float black_hole_mask = 0.0;
    vec3 sample_pos = vec3(MAX_FLOAT, 0.0, 0.0);
    vec3 current_ray_pos = has_sphere ? (ray_origin + ray_dir * outer_sphere.x) : (ray_origin + ray_dir);
    vec3 current_ray_dir = ray_dir;
    float event_horizon_radius = ss_radius * sphere_radius;

    if (has_sphere) {
        for (int i = 0; i < ray_steps; i++) {
            vec3 dir_to_centre = centre - current_ray_pos;
            float dst_to_centre = length(dir_to_centre);
            if (dst_to_centre <= event_horizon_radius) {
                black_hole_mask = 1.0;
                break;
            }
            dir_to_centre /= dst_to_centre;

            if (dst_to_centre > sphere_radius + scaled_step) {
                break;
            }

            vec3 prev_ray_pos = current_ray_pos;
            float prev_plane_dist = dot(prev_ray_pos - centre, disc_dir);

            float norm_dst = max(dst_to_centre / sphere_radius, 1e-4);
            float force = g_const / (norm_dst * norm_dst + 0.015);
            current_ray_dir = normalize(current_ray_dir + dir_to_centre * force * step_size);
            float near_horizon = clamp(
                (dst_to_centre - event_horizon_radius) / max(sphere_radius - event_horizon_radius, 1e-4),
                0.0,
                1.0
            );
            float adaptive_step = scaled_step * mix(0.28, 1.0, near_horizon);

            current_ray_pos += current_ray_dir * adaptive_step;

            float curr_dst_to_centre = length(current_ray_pos - centre);

            float falloff_zone = event_horizon_radius * 1.5;
            if (falloff_zone > event_horizon_radius + 1e-6 && curr_dst_to_centre < falloff_zone) {
                float proximity = 1.0 - (curr_dst_to_centre - event_horizon_radius) / (falloff_zone - event_horizon_radius);
                black_hole_mask = max(black_hole_mask, clamp(proximity, 0.0, 1.0));
            }

            if (curr_dst_to_centre <= event_horizon_radius) {
                black_hole_mask = 1.0;
                break;
            }

            float curr_plane_dist = dot(current_ray_pos - centre, disc_dir);
            if (disc_hit < 1.0 && prev_plane_dist * curr_plane_dist < 0.0) {
                float interp = abs(prev_plane_dist) / (abs(prev_plane_dist) + abs(curr_plane_dist));
                vec3 crossing_pos = mix(prev_ray_pos, current_ray_pos, interp);
                vec3 planar_offset = crossing_pos - centre - dot(crossing_pos - centre, disc_dir) * disc_dir;
                float radial_dist_sqr = dot(planar_offset, planar_offset);
                float outer_fade_radius = disc_radius * 1.3;
                if (radial_dist_sqr < outer_fade_radius * outer_fade_radius) {
                    disc_hit = 1.0;
                    sample_pos = crossing_pos;
                }
            }

            if (disc_hit > 0.0 && abs(curr_plane_dist) > abs(prev_plane_dist)) {
                break;
            }
        }
    }

    vec2 uv = vec2(0.0);
    vec3 planar_disc_pos = vec3(0.0);
    float streaks = 1.0;
    float radial_falloff = 1.0;
    if (sample_pos.x < MAX_FLOAT) {
        planar_disc_pos = sample_pos - dot(sample_pos - centre, disc_dir) * disc_dir - centre;
        uv = disc_uv(planar_disc_pos, disc_radius);
        uv.y += TIME * disc_speed * 0.1;

        float inner_norm = radii.x / radii.y;
        float radius_norm = clamp((uv.x - inner_norm) / max(1.0 - inner_norm, 1e-4), 0.0, 1.0);
        streaks = soft_edge(radius_norm, uv.y * PI * 2.0, TIME);

        float radial_dist = length(planar_disc_pos) / disc_radius;
        radial_falloff = 1.0 - smoothstep(0.85, 1.3, radial_dist);
    }
    float tex_col = mix(0.85, texture(disc_texture, uv).r, 0.65);

    vec3 distorted_ray_dir = has_sphere ? current_ray_dir : ray_dir;
    vec4 ray_camera_space = VIEW_MATRIX * vec4(distorted_ray_dir, 0.0);
    vec4 ray_uv_projection = PROJECTION_MATRIX * vec4(ray_camera_space.xyz, 0.0);
    vec2 distorted_screen_uv = ray_uv_projection.xy * 0.5 + 0.5;

    float ray_bend = 1.0 - dot(ray_dir, current_ray_dir);
    float bend_blend = smoothstep(0.0, 0.15, ray_bend);

    float edge_fade_x = smoothstep(0.0, 0.15, min(screen_uv.x, 1.0 - screen_uv.x));
    float edge_fade_y = smoothstep(0.0, 0.15, min(screen_uv.y, 1.0 - screen_uv.y));

    float lens_blend = has_sphere ? smoothstep(0.0, 0.22, ray_bend) : 0.0;
    distorted_screen_uv = mix(screen_uv, distorted_screen_uv, lens_blend);

    vec3 background_col = texture(screen_texture, distorted_screen_uv).rgb * (1.0 - black_hole_mask);

    vec3 final_disc_col = calc_disc_color(disc_color.rgb, planar_disc_pos, disc_dir, ray_origin, uv.x, uv.y, disc_radius, TIME);

    float horizon_fade = 1.0;
    if (sample_pos.x < MAX_FLOAT) {
        float sample_dist_to_centre = length(sample_pos - centre);
        if (event_horizon_radius > 1e-6) {
            float fade_center = event_horizon_radius * 1.2;
            float fade_width = max(fwidth(sample_dist_to_centre) * 2.0, event_horizon_radius * 0.15);
            horizon_fade = smoothstep(fade_center - fade_width, fade_center + fade_width, sample_dist_to_centre);
        }
    }

    disc_hit *= tex_col * disc_color.a * streaks * horizon_fade * radial_falloff;
    final_disc_col *= emission_strength;

    float horizon_frac = event_horizon_radius / max(disc_radius, 1e-6);
    if (sample_pos.x < MAX_FLOAT) {
        float r_norm = length(planar_disc_pos) / max(disc_radius, 1e-6);
        final_disc_col = apply_eht_disc_profile(final_disc_col, r_norm, horizon_frac, disc_hit);
    }

    vec3 col = mix(background_col, final_disc_col, disc_hit);

    if (has_sphere && view_shadow_strength > 0.001) {
        vec3 to_centre = normalize(centre - ray_origin);
        float view_align = max(dot(ray_dir, to_centre), 0.0);
        float dist_norm = length(centre - ray_origin) / max(sphere_radius * 4.0, 1.0);
        float proximity_shadow = smoothstep(1.4, 0.35, dist_norm);
        float angular_hole = smoothstep(0.88, 0.97, view_align)
            * (1.0 - smoothstep(0.97, 0.998, view_align));
        angular_hole *= view_shadow_strength * proximity_shadow;
        col = mix(col, background_col * (1.0 - black_hole_mask), angular_hole);
    }

    ALBEDO = col;
    ALPHA = 1.0;
    }
}
