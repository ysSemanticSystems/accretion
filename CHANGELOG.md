# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-20

Slice 0: prove the architecture end to end — pure Rust physics core, thin gdext
binding, Godot 4.7 lensing scene whose disk color is computed in Rust.

### Added

- Governance: tracked AI-attribution strip hooks (`.githooks/strip-ai-attribution.sh`,
  `prepare-commit-msg`, `commit-msg`) and per-clone `scripts/setup-hooks.sh`
  wiring `core.hooksPath`.
- `crates/accretion-core` (pure physics, CGS, zero Godot deps), ported from
  `BlackHoleResearch/blackhole/physics/accretion.py` with primary-source
  citations:
  - `l_eddington` (Eddington 1926)
  - `mdot_from_luminosity` (Novikov & Thorne 1973)
  - `disk_temperature` — bare Shakura-Sunyaev `T ∝ r^(-3/4)` (Shakura & Sunyaev 1973)
  - `isco_radius` — full Bardeen-Press-Teukolsky 1972 expression
  - `gravitational_radius_cm`, and `blackbody_rgb` (Planck 1901; CIE 1931;
    Wyman-Sloan-Shirley 2013; IEC 61966-2-1)
- Golden tests: `l_eddington(10 M_sun) ≈ 1.26e39` (1%), Schwarzschild ISCO ratio
  `== 6`, SS73 scaling `T(2r)/T(r) == 2^(-3/4)`, and a pinned `disk_temperature`
  value.
- `crates/godot-ext` cdylib: `BlackHole` node exposing `mass_solar` / `mdot_gs`
  / `spin`, with `disk_inner_temp`, `l_eddington`, `inner_radius_cm`, and
  `disk_inner_color` — all one-line delegations to `accretion-core`.
- `accretion.gdextension` (api-4-6 bindings, loads under Godot 4.7).
- Godot scene: Tyler Kennedy lensing shader (MIT) + procedural starfield sky,
  HDR/glow enabled, mass slider driving the Rust-computed inner-edge color.
- `.cursor/rules/`: `00-project-context`, `02-scientific-honesty`,
  `05-testing-discipline`, `09-commit-and-pr`, and new `10-presentation-boundary`.
- `AGENTS.md`, `CITATION.cff`.

### Known limitations

- `disk_temperature` omits the inner-boundary factor `(1 - sqrt(r_in/r))^(1/4)`,
  so there is no temperature peak / dark inner gap yet (fast-follow).
- `isco_radius` spin term is implemented but the frame-dragging visual is not.

[0.1.0]: https://github.com/ysSemanticSystems/accretion/releases/tag/v0.1.0
