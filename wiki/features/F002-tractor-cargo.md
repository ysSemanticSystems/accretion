---
id: F002-tractor-cargo
title: Tractor Beam and Cargo
status: implemented
layer: features
depends_on: [F001-third-person-flight, resource-loop, locked-decisions]
blocks: []
acceptance:
  - "Hold F to tractor nearest debris in forward cone; debris pulls toward ship"
  - "Debris auto-collects into cargo when within collection radius and cargo has capacity"
  - "HUD shows cargo mass / capacity and active tractor target"
  - "Collection emits soft visual feedback; sound disabled by default"
  - "Loaded cargo slightly reduces max speed (gameplay tuning in GDScript)"
  - "No dead Area3D collision on debris (explorer no-collision mode)"
  - "Deposit at home depot owned by F004; F002 owns collect verb only"
  - "No mining laser, refinery, or combat"
implements:
  - "scenes/Ship.tscn"
  - "scenes/harvestable_debris.tscn"
  - "scripts/cargo_hold.gd"
  - "scripts/tractor_beam.gd"
  - "scripts/harvestable_debris.gd"
  - "scripts/sector_debris.gd"
  - "scripts/collect_feedback.gd"
  - "scripts/ship_scene.gd"
  - "scripts/ship_controller.gd"
last_reviewed: 2026-06-21
---

# F002 — Tractor beam and cargo

Second vertical slice: prove harvest loop with a fixed debris field before
sector streaming ([sector-streaming.md](../architecture/sector-streaming.md)).

## Summary

Hold **F** to pull loose debris from a forward cone into the ship. Cargo holds
bulk volatiles (mass units). Collection is automatic at close range.

## Scope

**In scope:**

- `CargoHold` — capacity, mass tracking, speed penalty
- `TractorBeam` — cone targeting, pull, collect
- `HarvestableDebris` — scene + script, group `harvestable`
- Debris field spawner in `Ship.tscn`
- HUD cargo + tractor status

**Out of scope:**

- Sector streaming ([F005](F005-seeded-sector-debris.md)), scanner map, mining laser, refinery
- Deposit and upgrades ([F004](F004-home-depot-progression.md))

## Collection feedback

At `collected.emit`:

- Soft particle burst and small +mass floater
- Cargo bar pulse (no loud audio — `enable_sound := false` by default)

Remove unused `Area3D` / `CollisionShape3D` from `harvestable_debris.tscn` — collection is distance-based.

## Tuning (GDScript)

| Constant | Value | Script |
|---|---|---|
| `max_cargo_mass` | 500 | `cargo_hold.gd` |
| `cargo_speed_penalty` | 0.35 | `cargo_hold.gd` |
| `tractor_range` | 180 (+40/level) | `tractor_beam.gd` |
| `tractor_cone_deg` | 42 | `tractor_beam.gd` |
| `vacuum_range` | 70 | `tractor_beam.gd` |
| `pull_accel` | 85 | `tractor_beam.gd` |
| `collect_radius` | 45 | `tractor_beam.gd` |
| Debris mass | 15–45 each | `debris_field.gd` spawn specs |
| Debris count | 12 | `debris_field.gd` |

## Controls

- **Hold F** — tractor beam (requires mouse captured)

## Implementation notes

- `scripts/cargo_hold.gd`
- `scripts/tractor_beam.gd`
- `scripts/harvestable_debris.gd`
- `scripts/debris_field.gd`
- `scenes/harvestable_debris.tscn`
- Updates to `scenes/Ship.tscn`, `scripts/ship_scene.gd`, `project.godot`
