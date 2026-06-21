# accretion

**Explore, navigate, and collect** in space — or **ride the Eddington limit**
at a black hole. An accretion-disk game built like scientific software: every
formula cites a primary source, physical constants come from astropy, and the
physics core is independently testable in Rust. Godot 4.7 handles flight,
navigation, lensing, and presentation.

The default play scene is **`scenes/Ship.tscn`** (6DOF flight, tactical radar,
tractor cargo). The black-hole survival slice lives in **`scenes/Main.tscn`**.

Companion to
[BlackHoleResearch](https://github.com/ysSemanticSystems/BlackHoleResearch)
(the Streamlit FITS explorer); this repo is the game-side port of its accretion
physics discipline into Rust + Godot.

**Design spec:** [wiki/README.md](wiki/README.md) is the source of truth.

[![CI](https://github.com/ysSemanticSystems/accretion/actions/workflows/ci.yml/badge.svg)](https://github.com/ysSemanticSystems/accretion/actions/workflows/ci.yml)
![Godot 4.7](https://img.shields.io/badge/Godot-4.7-blue)
![Rust](https://img.shields.io/badge/Rust-stable-orange)
![License MPL-2.0](https://img.shields.io/badge/license-MPL--2.0-green)

---

## What you get

| Layer | Crate / path | Role |
|---|---|---|
| **Physics core** | [`crates/accretion-core`](crates/accretion-core/) | Eddington luminosity, Shakura–Sunyaev `T(r)`, Kerr ISCO, blackbody color. CGS, zero Godot deps, `cargo test`. |
| **Engine binding** | [`crates/godot-ext`](crates/godot-ext/) | Thin gdext cdylib: exposes the core to the scene tree. **No physics here.** |
| **Presentation** | `shaders/`, `scenes/`, `scripts/` | Lensing disk (Tyler Kennedy, MIT), starfield sky, HUD, controls. |

Constants and golden expected values are **generated from astropy** — not
hand-typed. See [AGENTS.md](AGENTS.md) and rule `11-constants-provenance`.

```
  Player input (mass, Ṁ, spin)
           │
           ▼
  ┌─────────────────┐     ┌──────────────────┐
  │  godot-ext      │────▶│  accretion-core  │  ← astropy-generated constants
  │  (BlackHole)    │     │  (pure Rust)     │  ← golden.json oracle tests
  └────────┬────────┘     └──────────────────┘
           │ disk color, T, λ_Edd
           ▼
  ┌─────────────────┐
  │  lensing shader │  HDR + bloom
  └─────────────────┘
```

---

## Documentation

**[wiki/README.md](wiki/README.md)** is the source of truth for game design,
architecture, physics invariants, and feature specs. Agents and contributors
start there. [AGENTS.md](AGENTS.md) covers setup and workflow bootstrap.

---

## Quick start

**Requirements:** Rust (stable, Edition 2024), Python 3.11+ with astropy, Godot
**4.7**, macOS arm64 (primary native target; others listed in
[`accretion.gdextension`](accretion.gdextension)).

```bash
git clone https://github.com/ysSemanticSystems/accretion.git
cd accretion

./scripts/setup-hooks.sh          # once per clone — AI-attribution strip hooks
pip install -r scripts/requirements.txt

make check                        # generators, invariants, test, clippy, build, Godot smoke
# Open the project in Godot 4.7 and run scenes/Main.tscn (F5)
# Explore slice (default): scenes/Ship.tscn is the main scene — flight, nav, tractor
```

**Before opening Godot**, run `make build` (or `make godot-smoke`). The native
library is copied to `bin/libgodot_ext.dylib` (macOS) or `bin/libgodot_ext.so`
(Linux) — that is what `accretion.gdextension` loads. Do not point Godot at a
stale `target/debug/` artifact from an old build.

`make godot-smoke` headlessly instantiates `BlackHole` and calls every Rust API
used by the game (`salpeter_time_s`, `advance_mass`, …). On macOS the Makefile
defaults to `/Applications/Godot.app/Contents/MacOS/Godot`; override with
`GODOT_BIN=...` if needed.

---

## Controls

### Black-hole slice (`scenes/Main.tscn`)

| Input | Action |
|---|---|
| **Mass slider** / `Q` `E` | Black-hole mass (log₁₀ M☉) — disk color comes from Rust `blackbody_rgb(T_inner)` |
| **Feed slider** / `Z` `X` | Accretion rate (log₁₀ g/s) — drive λ_Edd toward the loss ceiling |
| **Spin slider** / `A` `D` | Dimensionless spin a/M — ISCO shrinks, disk tightens |
| `1` `2` `3` | Presets: **Cyg X-1** (21 M☉), **Sgr A\*** (4×10⁶ M☉), **M87\*** (6.5×10⁹ M☉) |
| **Drag** / **scroll** | Orbit camera / zoom |

### Ship flight (`scenes/Ship.tscn` — F001)

| Input | Action |
|---|---|
| **W** **S** | Thrust forward / back |
| **A** **D** | Strafe |
| **Space** **C** | Up / down |
| **Q** **E** | Roll |
| **Mouse** | Steer (captured) |
| **Hold RMB** | Look orbit (camera only) |
| **Shift** | Cruise speed band |
| **Hold F** | Tractor beam (aim at debris) |
| **L** | Toggle auto-level |
| **Esc** | Release / capture mouse |

**Navigation:** sector + position (top-left HUD), compass bearing to nearest debris,
tactical radar (bottom-right). Cyan **home beacon** at origin — fly toward orange
blips / compass bearing to reach debris (~100–400 km out). Hold **Shift** for cruise.

The black-hole survival slice remains at `scenes/Main.tscn`.

---

## Physics (verifiable scope)

Every public function in `accretion-core` documents its primary source in the
doc comment. Current Slice 0 coverage:

| Quantity | Function | Reference |
|---|---|---|
| Eddington luminosity | `l_eddington` | Eddington 1926 |
| Disk temperature (bare SS73) | `disk_temperature` | Shakura & Sunyaev 1973 |
| ISCO radius | `isco_radius`, `r_isco` | Bardeen, Press & Teukolsky 1972 |
| Blackbody → sRGB | `blackbody_rgb` | Planck 1901; CIE 1931 |

**Known limitation:** `disk_temperature` uses the bare Shakura–Sunyaev profile
(`T ∝ r^(-3/4)`) without the inner-boundary factor — no temperature peak or dark
inner gap yet. Tracked as a fast-follow in [CHANGELOG.md](CHANGELOG.md).

---

## Development

```bash
make check          # full gate (preferred before every PR)
cargo test -p accretion-core
cargo clippy --workspace -- -D warnings
cargo fmt --check
```

Regenerate derived artifacts (must be byte-identical or CI fails):

```bash
python3 scripts/gen_constants.py   # → crates/accretion-core/src/constants.rs
python3 scripts/gen_golden.py      # → crates/accretion-core/tests/fixtures/golden.json
```

Contributor guide: [AGENTS.md](AGENTS.md). Persistent AI/human rules:
[`.cursor/rules/`](.cursor/rules/). See [CONTRIBUTING.md](CONTRIBUTING.md) for the PR checklist.

---

## Repository map

```
accretion/
├── crates/
│   ├── accretion-core/     # physics (CGS, astropy-sourced constants)
│   └── godot-ext/          # gdext binding (presentation only)
├── scripts/                # generators, invariant checks, setup-hooks
├── scenes/Main.tscn        # playable vertical slice
├── shaders/                # blackhole (MIT) + starfield
├── accretion.gdextension   # native lib wiring (api-4-6 → Godot 4.7)
├── AGENTS.md                 # operational guide
├── CHANGELOG.md
└── CITATION.cff              # machine-readable citation metadata
```

---

## Citation

See [CITATION.cff](CITATION.cff) for metadata. If you use this software, cite the
repository and the primary papers referenced in the physics doc comments.

---

## License

[MPL-2.0](LICENSE). Shader: Tyler Kennedy black-hole article (MIT) — see
[`shaders/blackhole.gdshader`](shaders/blackhole.gdshader) header.
