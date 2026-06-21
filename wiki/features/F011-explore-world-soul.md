---
id: F011-explore-world-soul
title: Explore World Soul — BH Skyline and Visible Debris
status: implemented
layer: features
depends_on: [locked-decisions, distance-and-visibility, F007-graphics-pipeline, F005-seeded-sector-debris]
blocks: []
acceptance:
  - "Inward sky reads as a luminous accretion core (sky-composited glow + enlarged disk); the BH is a near-constant skyline presence"
  - "Scene is lit with intent: warm BH-motivated key from the disk + cool rim, low ambient for contrast and form"
  - "Debris uses real PBR (no self-emission) so the key light sculpts the rock surface"
  - "Targets are framed by thin screen-space corner-tick brackets (nearest N), never a filled glyph stamped on the mesh"
  - "Debris rocks are bus-scale (target_size ~12 u) in dense sector clusters; radar merges dense clusters into one sized blip"
  - "Mid-field parallax dust always drifts near camera; nebula has fbm structure in the sky shader"
implements:
  - "scenes/DistantBlackHole.tscn"
  - "scripts/distant_black_hole.gd"
  - "scripts/ui/debris_brackets.gd"
  - "scripts/debris_visual.gd"
  - "scripts/space_ambience.gd"
  - "scripts/harvestable_debris.gd"
  - "scripts/sector_debris.gd"
  - "scripts/navigation_radar.gd"
  - "shaders/starfield_sky.gdshader"
  - "resources/space_environment.tres"
last_reviewed: 2026-06-21
---

# F011 — Explore world soul

## Summary

The explore slice orbits a distant supermassive black hole (visual landmark per
[locked-decisions](../game-design/locked-decisions.md)). Debris is readable at all
ranges via brackets, cross-fade, scale, and clustered belts.

## Scope

**In:** Distant BH scene in `Ship.tscn`, sky/lighting/ambience, debris visibility fix.

**Out:** BH insertion mechanics, radiation damage, wormhole prestige (future).

## Lighting (the drama pass)

Flat ambient was the single biggest "cheap" tell. The frame is now lit with intent:

| Light | Source | Role |
|---|---|---|
| **Warm key** | `SpaceAmbience/DiskLight`, oriented from the BH side (`space_ambience.gd`) | Hard orange rake across BH-facing hull/rocks |
| **Cool rim** | `SpaceAmbience/FillLight`, above/behind | Separates the dark side from the void |
| **Ambient** | environment, energy `0.12` | Deliberately low for contrast |

Debris are **real PBR** (`debris_visual.gd` → roughness ~0.92, metallic ~0.04, **no
emission**) so the key light carves form instead of a flat self-glow.

## Skyline landmark

A fixed-position object can only be seen when you look toward it, so the landmark is
also **composited into the sky**: `starfield_sky.gdshader` paints a broad warm halo +
hot core toward `disk_glow_dir`, so the inward hemisphere always glows. The disk mesh
is enlarged and pulled closer for a prominent on-screen disc when faced.

## Targets and radar readability

- **Brackets** — `scripts/ui/debris_brackets.gd` (HUD `Control`) projects the nearest
  ~16 harvestables to screen and draws hollow corner ticks that *frame* the target.
  Replaces the old `Label3D` "▣" glyph that stamped a grey box over close debris.
- **Radar declutter** — `navigation_radar.gd` merges blips within `CLUSTER_MERGE_PX`
  into one count-labelled blip sized by member count, capped at `MAX_BLIPS`.

## Tuning

| Constant | Value | Location |
|---|---|---|
| `BH_WORLD_POSITION` | `(0, 600, -9000)` km | `world_scale.gd` |
| `DISK_MESH_SCALE` | `2800` | `distant_black_hole.gd` |
| Beacon cross-fade | 600→400 km | `BEACON_FADE_*` |
| Debris `target_size` | ~12 km (AABB fit) | `debris_visual.gd` |
| Cluster radius | ~150 km | `sector_debris.gd` |
| Bracket cap / radar cap | 16 / 14 | `debris_brackets.gd`, `navigation_radar.gd` |
