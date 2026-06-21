---
id: F013-black-hole-visual-physics
title: Black Hole Visual Physics Pass
status: draft
layer: features
depends_on: [F011-explore-world-soul, F007-graphics-pipeline, presentation-boundary]
blocks: []
acceptance:
  - "Distant inward view reads as an EHT-like ring (dark shadow + bright photon ring), not a solid orange wall"
  - "Sky glow and mesh disk are balanced — no double-stacked warm fill on the inward hemisphere"
  - "Full Tyler Kennedy raymarch (shadow + lensing) ramps in as player enters BH inner zone"
  - "Disk colors and radii still driven from accretion_core via BlackHole gdext (no physics in shader)"
  - "Unused ship texture orphans removed; assets/ASSETS.md matches repo"
  - "Interior crossing remains out of scope per locked-decisions (visual landmark only)"
  - "Crossing the capture sphere triggers stylized infall shader (presentation only); debris/brackets/radar hidden inside volume"
implements:
  - "shaders/blackhole.gdshader"
  - "shaders/starfield_sky.gdshader"
  - "scripts/distant_black_hole.gd"
  - "scripts/bh_disk_driver.gd"
  - "resources/space_environment.tres"
last_reviewed: 2026-06-21
---

# F013 — Black hole visual physics pass

## Summary

Upgrade the explore-slice black hole from a **warm orange billboard** into a
**research-informed silhouette**: dark shadow, asymmetric photon ring, gravitational
lensing that scales with proximity. Physics numbers stay in Rust; shaders consume
uniforms only ([presentation-boundary](../invariants/presentation-boundary.md)).

## Reference material (primary sources)

| Source | What we take |
|---|---|
| [EHT M87* Paper I (2019)](https://iopscience.iop.org/article/10.3847/2041-8213/ab0ec7) | **Shadow** — dark region from photon capture at horizon; **ring** — gravitationally lensed emission; diameter ~42 μas |
| [EHT M87* Paper IV (2019)](https://ui.adsabs.harvard.edu/abs/2019ApJ...875L...4E/abstract) | Ring diameter stable across methods; **asymmetric brightness** (Doppler beaming) |
| [Nature 2023 — 3.5 mm ring](https://www.nature.com/articles/s41586-023-05843-w) | Ring size ~50% larger at longer wavelength; motivates radial falloff tuning |
| [MNRAS 2021 — lensing + simple disc model](https://academic.oup.com/mnras/article/507/4/5974/6352345) | Salient EHT features reproducible with strong lensing + thin disc |
| Tyler Kennedy Godot shader (MIT) | Existing raymarch base — extend, do not replace wholesale |

**Not in scope:** GRMHD simulation, VLBI data fitting, Rust formula changes without
golden tests.

## What it looks like *inside* a black hole (design note)

General relativity: crossing the event horizon is a **one-way boundary**. External
observers never see you fall in — you redshift toward invisibility. Inside, classical
GR predicts inevitable spacetime curvature toward the singularity; there is no stable
“interior vista” in the usual sense. Rotating (Kerr) holes add an inner **Cauchy
horizon** and mass inflation (still unsettled physically).

**Game lock:** [locked-decisions](../game-design/locked-decisions.md) — BH is a
**visual landmark only**; no prestige insertion in this pass. Crossing the **capture
sphere** (mesh radius, presentation-only) triggers a **stylized infall view**: screen
warp, redshift tint, photon-ring echo — not a GR interior sim. Debris, brackets, and
radar blips are hidden inside that volume (nothing to harvest in the capture shell).

## Root cause — “orange wall”

1. **Sky double-stack** — `starfield_sky.gdshader` paints a strong warm core toward
   `-Z` *and* `DistantBlackHole` renders a huge emissive disc at the same bearing.
2. **Missing far shadow** — `blackhole.gdshader` only accumulates `black_hole_mask`
   when rays penetrate near the horizon; at 8000+ km the disc plane fills the view
   without an EHT-style central hole.
3. **Scale** — `DISK_MESH_SCALE = 2800` subtends ~17° at 9 Mm — reads as a wall.

## Phased implementation

### Phase 1 — Silhouette fix (this branch)

- Angular **EHT shadow profile** on disc hits (dark center + photon ring boost)
- **Tone down sky glow**; mesh carries the landmark when in view
- **Distance LOD** in `distant_black_hole.gd` — fade mesh alpha / emission far out
- `BhDiskDriver` passes `shadow_angular` from horizon / outer disc ratio

### Phase 2 — Lensing fidelity

- Screen-space photon ring even when raymarch shallow
- Disk **inclination** uniform (M87-like ~17° from jet axis) for asymmetric ring
- Improve `lens_blend` so center-screen lensing works at distance
- **Smoother disc turbulence** — reduced hot-spot gain, adaptive ray steps near horizon
- **Stylized interior** — `interior_strength` + `render_interior()` when ship inside capture sphere

### Phase 3 — Textures & assets

- Procedural disc noise → shared `NoiseTexture2D` resource
- Debris PBR: optional albedo/normal from Poly Haven CC0 rock scans
- Remove orphans: `assets/ships/challenger/*` (broken addon paths), duplicate atlases,
  unused `resources/visual/space_environment.tres` if unreferenced

### Phase 4 — Research-backed polish (optional)

- Compare stills against EHT synthetic images (presentation QA only)
- BH Lab (`BhSurvival`) shares shader improvements with explore slice

## Tuning (presentation)

| Constant | Initial | Location |
|---|---|---|
| `EHT_SHADOW_SCALE` | 2.6 × horizon/disc | shader stylized |
| Sky `disk_glow_strength` | 0.35 (was 0.95) | `space_environment.tres` |
| Mesh fade start/end | 12 Mm / 4 Mm | `distant_black_hole.gd` |
| Capture sphere radius | 1100 km (mesh scale 2200) | `world_scale.gd` |
| Ray steps (close) | 448 | `bh_disk_driver.gd` |
