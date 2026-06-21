---
id: graphics-pipeline
title: Graphics Pipeline
status: active
layer: architecture
depends_on: [presentation-boundary, architecture-overview]
last_reviewed: 2026-06-21
---

# Graphics pipeline

Presentation-only visuals for the ship slice. No physics formulas or game constants
live in meshes, materials, or shaders beyond display tuning.

## Layers

| Layer | Location | Role |
|---|---|---|
| **Environment** | `resources/space_environment.tres` | Procedural starfield sky, ACES tonemap, SSAO, glow |
| **Ship mesh** | `assets/ships/player_ship.glb` + `scripts/ship_visual.gd` | PBR player hull, scale/axis fix, engine glow |
| **Debris mesh** | `assets/debris/debris_*.glb` + `scripts/debris_visual.gd` | Random rock variant + warm emissive tint |
| **Procedural sky** | `shaders/starfield_sky.gdshader` | Fallback for `Main.tscn` (BH survival slice) |
| **VFX** | GPUParticles in `Ship.tscn`, `collect_feedback.gd` | Speed streaks, collection pulse |

## Scene wiring

- **`Ship.tscn`** — `WorldEnvironment` → `space_environment.tres`; `Hull` → `ship_visual.gd`.
- **`harvestable_debris.tscn`** — `DebrisVisual` → `debris_visual.gd` (spawns rock GLB at runtime).
- **`Main.tscn`** — keeps procedural starfield + black-hole shader (unchanged).

## Asset rules

1. Record every external file in [`assets/ASSETS.md`](../../assets/ASSETS.md).
2. Prefer **CC0**; CC-BY requires attribution in ASSETS.md.
3. Ship/debris scale is tuned in GDScript (`model_scale`, `scale_multiplier`), not in physics.
4. Distance-based LOD for debris meshes follows [`distance-and-visibility.md`](../game-design/distance-and-visibility.md).

## Adding a new mesh

1. Drop `.glb` under `assets/` with license note in `assets/licenses/`.
2. Add row to `ASSETS.md`.
3. Preload in a small visual script or instance in scene.
4. Run Godot once so `.import` sidecars are generated.
5. Update this page if the pipeline changes.

See feature spec [F007 — Graphics pipeline](../features/F007-graphics-pipeline.md).
