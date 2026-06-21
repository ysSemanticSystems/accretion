# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Run lifecycle and replay value.** Each run starts at Cyg X-1 scale with a
  clear win (reach M87*) and lose (three super-Eddington disk disruptions).
  Live score, persisted high score (`user://accretion_best.run`), end-of-run
  overlay, and `R`/Enter restart. Challenge presets 1/2/3 start at different
  mass/feed/spin. λ-safe Ṁ ceiling shown in the HUD.
- **Kerr spin-up from accretion.** `advance_spin` and ISCO specific angular
  momentum (Bardeen-Press-Teukolsky 1972; King & Raine 2002); spin now evolves
  during play, raising η and tightening the ISCO.
- **QPO hotspot animation.** Shader `qpo_phase_rate` driven from the Rust ISCO
  orbital frequency so the inner disk flickers at a physically scaled rate.
- **Survival/progression loop.** Mass now evolves in (compressed) time via
  `advance_mass` (`dM/dt = (1 - eta) Mdot`, Frank/King/Raine 2002); a disk-integrity
  meter drains when super-Eddington and rebuilds when sub-Eddington, and reaching
  zero triggers a disruption that blows the disk apart and resets the feed. Growth
  reclassifies the hole (stellar → IMBH → SMBH) with milestone banners and a
  next-goal progress bar.
- **New physics in `accretion-core`** (each cited + golden/identity tested):
  `salpeter_time_s` (Salpeter 1964), `integrity_rate` (Eddington 1926 effective
  gravity `1 - lambda`), `isco_specific_energy` / `efficiency_from_spin` (Bardeen-
  Press-Teukolsky 1972; Thorne 1974), `orbital_frequency_hz` (BPT 1972 QPO scale).
- **Derived constants module** `derived.rs`: `SIGMA_SB = 2 pi^5 k_B^4 / (15 c^2 h^3)`
  (exact under 2019 SI) and `SIGMA_T = (8 pi / 3)(alpha hbar / m_e c)^2`, computed
  from fundamentals instead of tabulated, pinned by astropy-oracle golden tests.
- Cinematic camera: damped orbit/zoom, idle auto-orbit, intro dolly.
- Graphics driven from Rust: radial blackbody gradient (inner + outer color),
  bounded HDR bloom tone-mapped from the inner-edge temperature, and spin-driven
  inner-edge / event-horizon tightening; disk grows with mass class.
- **README.md** — public landing page with architecture, controls, quick start, CI badge.
- **LICENSE** (MPL-2.0), **CONTRIBUTING.md**, GitHub CI workflow, PR and issue templates.
- Astropy-oracle pipeline: `scripts/gen_constants.py` → `constants.rs`,
  `scripts/gen_golden.py` → `golden.json`; `scripts/check_invariants.sh` and
  `make check` gate (C1–C6).
- Rules `11-constants-provenance`, `12-gdext-api-pinning`.
- Playable controls: keyboard (Q/E mass, Z/X feed, A/D spin, 1/2/3 presets),
  mouse orbit + scroll zoom, RichText telemetry HUD, super-Eddington warning.
- `r_s()`, `r_isco()`, `luminosity_from_mdot()`, `eddington_ratio()` in core.

### Changed

- **Modular `accretion-core` architecture.** Split the monolithic `lib.rs` into
  focused modules (`eddington`, `kerr`, `disk`, `evolution`, `colorimetry`)
  with crate-root re-exports preserving the public API. Added extensive unit tests
  in each module, shared integration-test helpers, and a cross-module
  `tests/integration.rs` suite.
- `constants.rs` now holds only FUNDAMENTAL constants (added `M_E`, `ALPHA`;
  dropped tabulated `SIGMA_SB`/`SIGMA_T`); composites are derived in `derived.rs`.
  Rule 11 / rule 02 updated for the two-layer (fundamental vs derived) provenance.
- Fixed the disk shader sampling an unassigned `disc_texture` (now a procedural
  `NoiseTexture2D`) so the accretion disk renders.
- Reworded "honest" marketing phrasing to "rigorous / first-principles /
  verifiable" in user-facing docs (the scientific-honesty rule and prime directive
  are unchanged).
- Physical constants are generated from astropy (no hand-written M_sun).
- Golden tests use astropy oracle fixtures, not hand-pinned magnitudes.
- `compatibility_minimum = 4.6` matches `api-4-6` gdext feature.
- HUD shows human-readable masses, luminosities, temperatures (not raw `%e`).

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
