---
id: F011-explore-world-soul
title: Explore World Soul — BH Skyline and Visible Debris
status: implemented
layer: features
depends_on: [locked-decisions, distance-and-visibility, F007-graphics-pipeline, F005-seeded-sector-debris]
blocks: []
acceptance:
  - "Explore run always shows distant accretion BH on the inward skyline (visual landmark only)"
  - "Disk warm light tints the ship; sky shows counter-glow toward BH direction"
  - "Debris uses screen-space target bracket + cross-fade beacon→rock (no 53× pop)"
  - "Debris rocks are bus-scale (target_size ~12 u) in dense sector clusters"
  - "Mid-field parallax dust always drifts near camera; nebula bands in sky shader"
implements:
  - "scenes/DistantBlackHole.tscn"
  - "scripts/distant_black_hole.gd"
  - "scripts/debris_target_bracket.gd"
  - "scripts/space_ambience.gd"
  - "scripts/harvestable_debris.gd"
  - "scripts/sector_debris.gd"
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

## Tuning

| Constant | Value | Location |
|---|---|---|
| `BH_WORLD_POSITION` | `(0, 0, -12000)` km | `world_scale.gd` |
| Beacon cross-fade | 600→400 km | `BEACON_FADE_*` |
| Debris `target_size` | ~12 km (AABB fit) | `debris_visual.gd` |
| Cluster radius | ~150 km | `sector_debris.gd` |
