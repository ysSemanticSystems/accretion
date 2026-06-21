# accretion

**Fly, collect, bank, upgrade** — a third-person explore baseline set around a
distant accretion black hole. Built like scientific software: every formula cites a
primary source, physical constants come from astropy, and the physics core is
independently testable in Rust. Godot 4.7 handles flight, navigation, lensing, and
presentation.

Press **New Run** from the main menu to spawn into open space: 6DOF arcade flight,
sector debris belts, tractor cargo, a home depot loop, and a warm disk glowing on
the inward skyline. The black-hole **survival lab** (Eddington limit, disk tuning) is
still available from the menu.

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

## Play today (baseline)

| Mode | Entry | What you do |
|---|---|---|
| **Explore run** | `scenes/Main.tscn` → **New Run** | Fly outward from home, tractor orange debris into your hold, return to the cyan beacon to bank mass, buy upgrades, push to richer sector rings. Distant BH on the skyline; compass + radar guide you. |
| **BH Lab** | Main menu → **BH Lab** | Tune mass, accretion rate, and spin; watch the lensed disk respond. Classic survival slice (`BhSurvival.tscn`). |
| **Dev slice** | `scenes/Ship.tscn` (F5) | Ship scene only — flight, nav, tractor, depot — without the menu shell. |

The shipped loop is intentionally small but end-to-end: **fly → collect → bank →
upgrade → explore outward**. Presentation is tuned for readable targets (screen-space
brackets, decluttered radar, motivated lighting) rather than final art polish.

---

## What you get

| Layer | Crate / path | Role |
|---|---|---|
| **Physics core** | [`crates/accretion-core`](crates/accretion-core/) | Eddington luminosity, Shakura–Sunyaev `T(r)`, Kerr ISCO, blackbody color. CGS, zero Godot deps, `cargo test`. |
| **Engine binding** | [`crates/godot-ext`](crates/godot-ext/) | Thin gdext cdylib: exposes the core to the scene tree. **No physics here.** |
| **Presentation** | `shaders/`, `scenes/`, `scripts/` | Lensing disk (Tyler Kennedy, MIT), procedural starfield, game shell, HUD, controls. |

Constants and golden expected values are **generated from astropy** — not
hand-typed. See [AGENTS.md](AGENTS.md) and rule `11-constants-provenance`.

```
  Player input (mass, Ṁ, spin)          Explore run (WASD, tractor, depot)
           │                                        │
           ▼                                        ▼
  ┌─────────────────┐     ┌──────────────────┐   ┌──────────────────┐
  │  godot-ext      │────▶│  accretion-core  │   │  Game shell +    │
  │  (BlackHole)    │     │  (pure Rust)     │   │  Ship.tscn loop  │
  └────────┬────────┘     └──────────────────┘   └────────┬─────────┘
           │ disk color, T, λ_Edd                       │ flight, nav, cargo
           ▼                                            ▼
  ┌─────────────────┐                          ┌──────────────────┐
  │  lensing shader │  HDR + bloom             │  starfield sky,  │
  └─────────────────┘                          │  distant BH glow │
                                               └──────────────────┘
```

---

## Documentation

**[wiki/README.md](wiki/README.md)** is the source of truth for game design,
architecture, physics invariants, and feature specs (`F001`–`F011`). Agents and
contributors start there. [AGENTS.md](AGENTS.md) covers setup and workflow bootstrap.

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

make check                        # generators, invariants, wiki, test, clippy, build, Godot smoke + presentation
# Open the project in Godot 4.7 and run scenes/Main.tscn (F5) → New Run
```

**Before opening Godot**, run `make build` (or `make godot-smoke`). The native
library is copied to `bin/libgodot_ext.dylib` (macOS) or `bin/libgodot_ext.so`
(Linux) — that is what `accretion.gdextension` loads. Do not point Godot at a
stale `target/debug/` artifact from an old build.

`make godot-smoke` headlessly instantiates `BlackHole` and calls every Rust API
used by the game. `make godot-presentation` runs shell/HUD/scene compatibility
regressions headlessly. On macOS the Makefile defaults to
`/Applications/Godot.app/Contents/MacOS/Godot`; override with `GODOT_BIN=...` if
needed.

---

## Controls

### Explore run (main menu → **New Run**)

| Input | Action |
|---|---|
| **W** **S** | Thrust forward / back |
| **A** **D** | Strafe |
| **Space** **C** | Up / down |
| **Q** **E** | Roll |
| **Mouse** | Steer ship (captured) |
| **Hold RMB** | Orbit camera without turning ship |
| **Shift** | Cruise speed band |
| **Hold F** | Tractor beam (pull debris into hold) |
| **L** | Toggle auto-level (roll-only — keeps your pitch/yaw aim) |
| **Esc** | Pause menu |

**Navigation:** mission line + cargo bar (top-left), compass to nearest debris or
home beacon, waypoint chevron, tactical radar (bottom-right). Fly to **orange debris**
fields, return to the **cyan home beacon** at origin to unload and upgrade.

### BH Lab (main menu → **BH Lab**)

| Input | Action |
|---|---|
| **Mass slider** / `Q` `E` | Black-hole mass (log₁₀ M☉) |
| **Feed slider** / `Z` `X` | Accretion rate (log₁₀ g/s) |
| **Spin slider** / `A` `D` | Dimensionless spin a/M |
| `1` `2` `3` | Presets: **Cyg X-1**, **Sgr A\***, **M87\*** |
| **Drag** / **scroll** | Orbit camera / zoom |
| **Esc** | Back to main menu |

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
inner gap yet. Tracked in [CHANGELOG.md](CHANGELOG.md).

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
├── scenes/
│   ├── Main.tscn           # game shell (menu → explore / BH Lab)
│   ├── Ship.tscn           # explore gameplay scene
│   └── BhSurvival.tscn     # Eddington survival lab
├── shaders/                # blackhole (MIT) + starfield
├── accretion.gdextension   # native lib wiring (api-4-6 → Godot 4.7)
├── wiki/                   # design source of truth
├── AGENTS.md
├── CHANGELOG.md
└── CITATION.cff
```

---

## Citation

See [CITATION.cff](CITATION.cff) for metadata. If you use this software, cite the
repository and the primary papers referenced in the physics doc comments.

---

## License

[MPL-2.0](LICENSE). Shader: Tyler Kennedy black-hole article (MIT) — see
[`shaders/blackhole.gdshader`](shaders/blackhole.gdshader) header.
