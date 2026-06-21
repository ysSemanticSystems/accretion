---
id: project-context
title: Project Context
status: active
layer: invariants
applies_to: []
depends_on: []
last_reviewed: 2026-06-21
---

# accretion — project context

This is an **accretion-disk game** evolving toward **solo spaceship exploration
and resource collection** in a scientifically honest universe. You fly a ship,
gather and refine materials, and upgrade your vessel — with black-hole
accretion physics as the long-term capstone (deferred in current slice).

The existing vertical slice is a black-hole survival sim (feed matter, ride the
Eddington limit, grow mass). New work prioritizes **100% explore + collection**
per [`locked-decisions.md`](../game-design/locked-decisions.md).

It is built like *scientific software*: numbers are honest, every formula cites
a primary source, and the physics is independently testable. Ported from the
discipline of the BlackHoleResearch project (`app.py` presentation-only;
physics in pure modules), relocated to Rust + Godot.

## Architecture (the invariant that makes this work)

```
crates/accretion-core/  pure Rust lib (CGS), ZERO Godot dependency, cargo-testable.
                        All physics: l_eddington, mdot_from_luminosity,
                        disk_temperature (Shakura-Sunyaev), isco_radius
                        (Bardeen+1972), gravitational_radius_cm,
                        blackbody_rgb (Planck -> CIE -> sRGB).
crates/godot-ext/       thin gdext cdylib. Presentation binding ONLY, no physics.
                        Exposes accretion-core to the scene tree (BlackHole node).
*.gdshader              Tyler Kennedy lensing shader (MIT) + procedural sky.
scenes/, scripts/       Godot scene + GDScript glue (presentation only).
```

## Prime directives (memorize)

1. **Honesty over completeness** — never invent a value, unit, or uncertainty.
2. **Cite every formula** — primary-source reference in every physics doc comment.
3. **Physics lives in `accretion-core`** — `godot-ext`, shaders, and GDScript
   present numbers; they do not compute them. See [presentation-boundary.md](presentation-boundary.md).
4. **Tests precede expansion** — a new physics formula lands with a golden test
   reproducing a textbook value to stated precision. See [testing-discipline.md](testing-discipline.md).
5. **Single source of truth** — physical constants live once, in
   `accretion-core` (CODATA / IAU), and are cited there.

## Quick-reference map

| Need | Path |
|---|---|
| New physics formula | `crates/accretion-core/src/lib.rs` (with citation + golden test) |
| Expose a number to Godot | `crates/godot-ext/src/lib.rs` (one-line delegation) |
| Visual / shader change | `shaders/*.gdshader` |
| Scene / UI wiring | `scenes/*.tscn`, `scripts/*.gd` |
| Native lib wiring | `accretion.gdextension` |
| Game design / feature spec | `wiki/game-design/`, `wiki/features/` |

## Toolchain

`cargo test` (was pytest), `cargo clippy` + `cargo fmt` (were ruff/mypy).
Godot 4.7, gdext (godot crate 0.5.x, MPL-2.0). Build the native library with
`cargo build` before opening the Godot editor.

## Known deferred physics (stated plainly)

- `disk_temperature` uses the **bare** Shakura-Sunyaev form (`T ∝ r^(-3/4)`,
  no inner-boundary factor), so there is no temperature peak / dark inner gap
  yet. The inner-boundary correction is a logged fast-follow.
- Accretion survival loop integration with ship collection is deferred per
  [`locked-decisions.md`](../game-design/locked-decisions.md).
