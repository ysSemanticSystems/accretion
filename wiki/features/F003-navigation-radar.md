---
id: F003-navigation-radar
title: Navigation Radar and Compass
status: implemented
layer: features
depends_on: [F001-third-person-flight, distance-and-visibility, F004-home-depot-progression]
blocks: []
acceptance:
  - "HUD shows sector grid coordinates and ship position in km updating while flying"
  - "Compass tracks navigation objective: depot when cargo loaded, nearest debris when empty"
  - "Tactical radar displays harvestable blips with sqrt-scaled layout to 2500 km"
  - "Cyan depot beacon on radar; objective blip highlighted (depot when loaded, debris when empty)"
  - "Range rings at 33%, 66%, and 100% of radar radius"
  - "Radar blips show altitude stalks (signed Y offset from ship)"
  - "Radar disc is heading-up (ship local XZ projection rotated with ship yaw)"
  - "Debris shows mesh within 500 km and emissive beacon marker beyond until 8000 km"
  - "Home beacon at origin provides visual motion reference"
implements:
  - "scripts/world_scale.gd"
  - "scripts/navigation_system.gd"
  - "scripts/navigation_radar.gd"
  - "scripts/ship_scene.gd"
  - "scripts/harvestable_debris.gd"
  - "scenes/Ship.tscn"
last_reviewed: 2026-06-21
---

# F003 — Navigation radar and compass

## Summary

Map empty space for the player: know where you are, where debris is, and that
you are actually moving. Spec detail: [distance-and-visibility.md](../game-design/distance-and-visibility.md).

## Tuning

| Constant | Value | Script |
|---|---|---|
| `UNITS_PER_KM` | 1 | `world_scale.gd` |
| `SECTOR_EDGE_UNITS` | 1000 | `world_scale.gd` |
| `RADAR_RANGE_UNITS` | 2500 | `world_scale.gd` |
| `VISUAL_MESH_RADIUS_UNITS` | 500 | `world_scale.gd` |
| `MARKER_BEACON_RADIUS_UNITS` | 8000 | `world_scale.gd` |

## Radar v2

- **Altitude stalks:** vertical line from disc blip; length = signed Y / max range
- **Heading-up:** project POI offsets into ship local frame before drawing
- **Objective compass:** requires [F004](F004-home-depot-progression.md) depot target when loaded

Sqrt range compression and visibility rings unchanged.

## Controls

No new bindings — read nav HUD while flying ([F001](F001-third-person-flight.md)).
