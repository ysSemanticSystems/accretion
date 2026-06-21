---
id: presentation-boundary
title: Presentation Boundary
status: active
layer: invariants
applies_to: ["crates/godot-ext/**/*.rs", "scripts/**/*.gd", "shaders/**/*.gdshader"]
depends_on: [project-context]
last_reviewed: 2026-06-21
---

# Presentation boundary

This is the invariant that keeps the game physically honest, and the direct
analogue of "Streamlit is presentation only" in BlackHoleResearch.

**All numbers come from `accretion-core`. The presentation layer only routes
input in and renders state out.**

## What "presentation layer" means here

- `godot-ext/` (the gdext binding),
- `shaders/*.gdshader`,
- `scripts/*.gd` (GDScript) and `scenes/*.tscn`.

## Rules

1. **No physics formulas in the presentation layer.** No Eddington luminosity,
   no Shakura-Sunyaev temperature, no ISCO, no blackbody/colorimetry math in
   `godot-ext`, a shader, or GDScript. If you are writing such a formula in any
   of these, stop and put it in `accretion-core`.

2. **`godot-ext` functions are one-line delegations.** Each `#[func]` /
   property that returns a physical quantity calls straight into
   `accretion-core`:

   ```rust
   // GOOD - delegation only.
   #[func]
   fn disk_inner_radius_rg(&self) -> f64 {
       accretion_core::isco_radius(self.spin)
   }

   // BAD - physics leaked into the binding.
   #[func]
   fn disk_inner_radius_rg(&self) -> f64 {
       let z1 = 1.0 + /* ... Bardeen+1972 expansion ... */;
       3.0 + z2 - ((3.0 - z1) * (3.0 + z1 + 2.0 * z2)).sqrt()
   }
   ```

3. **No physical constants in the presentation layer.** `G`, `c`, `M_sun`,
   `sigma_T`, etc. live only in `accretion-core`. A shader may hold *stylistic*
   constants (step counts, falloff widths); it may not recompute physics.

4. **Color is computed in Rust.** The disk's blackbody color comes from
   `accretion_core::blackbody_rgb`; the shader receives it as the `inner_color`
   uniform. The shader does not derive disk color from temperature itself.

5. **Shaders are stylized presentation.** The lensing/disk shader is an
   artistic approximation (it is fine for it to be non-physical); it consumes
   physics-derived inputs (colors, radii) but is not a source of truth for any
   reported number.

## Gameplay tuning in GDScript

Gameplay feel constants (camera smoothing, drain/recover rates, spawn caps) may
live in GDScript when documented in the wiki feature spec. They are not
physics formulas.

## Checklist for a presentation-layer change

- [ ] No physics formula or physical constant introduced here.
- [ ] Any reported physical quantity is a delegation to `accretion-core`.
- [ ] New game-affecting numbers were added to `accretion-core` (with citation
      and a golden test), not here.
