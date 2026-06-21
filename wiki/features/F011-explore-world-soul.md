---
id: F011-explore-world-soul
title: Explore World Soul — BH Skyline and Visible Debris
status: implemented
layer: features
depends_on: [locked-decisions, distance-and-visibility, F007-graphics-pipeline, F005-seeded-sector-debris]
blocks: []
acceptance:
  - "Inward sky reads as a luminous accretion core (sky-composited glow + enlarged disk); the BH is a near-constant skyline presence"
  - "Scene key light comes from a distinct host star; M87* disk is self-lit (shader) with a weak proximity rim only"
  - "Debris uses real PBR (no self-emission) so the key light sculpts the rock surface"
  - "Targets are framed by thin screen-space corner-tick brackets (nearest N), never a filled glyph stamped on the mesh"
  - "Debris rocks are bus-scale (target_size ~12 u) in dense sector clusters; radar merges dense clusters into one sized blip"
  - "Mid-field parallax dust always drifts near camera; nebula has fbm structure in the sky shader"
implements:
  - "scenes/DistantBlackHole.tscn"
  - "scenes/PrimaryStar.tscn"
  - "scripts/distant_black_hole.gd"
  - "scripts/primary_star.gd"
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

## Lighting

Host star and M87* are **separate** (NASA SVS / EHT: disk is self-luminous thermal
emission; local stars provide distinct illumination on debris and hull).

| Source | Node / shader | Role |
|---|---|---|
| **Host star key** | `PrimaryStar` billboard + `SpaceAmbience/StarLight` | G-type warm-white key from `PRIMARY_STAR_POSITION` |
| **Nebula fill** | `SpaceAmbience/FillLight` | Cool rim opposite the star |
| **BH disk rim** | `SpaceAmbience/BhRimLight` | Weak orange fill when close — disk shader carries the real look |
| **M87* mesh** | `blackhole.gdshader` | Self-lit accretion disk + EHT shadow (not the scene key) |
| **Sky** | `starfield_sky.gdshader` | Separate `primary_star_dir` and `disk_glow_dir` + `star_corona.png` |
| **Ambient** | environment, energy `0.12` | Low for contrast |

Debris use **real PBR** (no self-emission) so the **star** sculpts form.

## Skyline landmark

`starfield_sky.gdshader` composites **two bearings**: host star (`primary_star_dir`)
and M87* disk glow (`disk_glow_dir`). The raymarched disk mesh carries the EHT ring
when you look inward.

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
| `PRIMARY_STAR_POSITION` | `(14000, 8200, 10500)` km | `world_scale.gd` |
| `DISK_MESH_SCALE` | `2800` | `distant_black_hole.gd` |
| Beacon cross-fade | 600→400 km | `BEACON_FADE_*` |
| Debris `target_size` | ~12 km (AABB fit) | `debris_visual.gd` |
| Cluster radius | ~150 km | `sector_debris.gd` |
| Bracket cap / radar cap | 16 / 14 | `debris_brackets.gd`, `navigation_radar.gd` |
