---
id: F007-graphics-pipeline
title: Graphics Pipeline (Ship Slice)
status: implemented
layer: features
depends_on: [presentation-boundary, distance-and-visibility]
blocks: []
acceptance:
  - "Ship.tscn uses HDRI environment with SSAO/glow, not procedural starfield"
  - "Player ship is a PBR GLB with engine glow, not a capsule placeholder"
  - "Harvestable debris uses rock GLB variants with emissive tint"
  - "All external assets logged in assets/ASSETS.md with license"
implements: [Ship.tscn, harvestable_debris.tscn, ship_visual.gd, debris_visual.gd]
last_reviewed: 2026-06-21
---

# F007 — Graphics pipeline (ship slice)

## Summary

Replace placeholder primitives in the ship play slice with CC0 PBR assets: procedural
starfield sky (not ground HDRIs), Quaternius ship GLB for the player hull, and
low-poly rock meshes for harvestable debris.

## Scope

**In:** `Ship.tscn`, `harvestable_debris.tscn`, `resources/space_environment.tres`,
visual scripts, `assets/` provenance, `project.godot` default environment.

**Out:** Main.tscn black-hole slice visuals, UI theming, audio, Rust/shader physics.

## Acceptance criteria

1. **Environment** — `WorldEnvironment` references `space_environment.tres` (procedural starfield).
2. **Player ship** — `ship_visual.gd` instances `player_ship.glb` at tuned scale; cyan engine `OmniLight3D`.
3. **Debris** — `debris_visual.gd` picks `debris_01` or `debris_02` GLB with warm emission.
4. **Provenance** — `assets/ASSETS.md` lists every committed external file + license URL.

## Tuning (presentation)

| Knob | Location | Default |
|---|---|---|
| HDRI energy | `space_environment.tres` | n/a (procedural sky) |
| Ship scale | `ship_visual.gd` `target_length` | 1.7 (AABB fit; GLB has embedded 100× node) |
| Debris scale | `debris_visual.gd` `target_size` | 0.45 |
| Glow threshold | `space_environment.tres` | 0.78 |

## Open questions

- Swap to Quaternius Challenger mesh once Godot 4 scene import is cleaned up.
- Engine exhaust particles (reuse `assets/ships/exhaust/`).
