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
  - "Static debris field (~12 pieces) placed in scenes/Ship.tscn without sector streaming"
  - "Loaded cargo slightly reduces max speed (gameplay tuning in GDScript)"
  - "No mining laser, refinery, or combat"
implements:
  - "scenes/Ship.tscn"
  - "scenes/harvestable_debris.tscn"
  - "scripts/cargo_hold.gd"
  - "scripts/tractor_beam.gd"
  - "scripts/harvestable_debris.gd"
  - "scripts/debris_field.gd"
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

- Sector streaming, scanner map, mining laser, refinery, upgrades

## Tuning (GDScript)

| Constant | Value | Script |
|---|---|---|
| `max_cargo_mass` | 500 | `cargo_hold.gd` |
| `cargo_speed_penalty` | 0.35 | `cargo_hold.gd` |
| `tractor_range` | 180 | `tractor_beam.gd` |
| `tractor_cone_deg` | 28 | `tractor_beam.gd` |
| `pull_accel` | 55 | `tractor_beam.gd` |
| `collect_radius` | 6 | `tractor_beam.gd` |
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
