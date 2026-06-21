---
id: F004-home-depot-progression
title: Home Depot and Progression
status: implemented
layer: features
depends_on: [F002-tractor-cargo, resource-loop, locked-decisions]
blocks: [F005-seeded-sector-debris]
acceptance:
  - "Flying within deposit radius of origin beacon with cargo auto-deposits mass and empties hold"
  - "Banked total increases on deposit; HUD shows session banked mass"
  - "Speed penalty clears when hold empties after deposit"
  - "Player can purchase at least one upgrade from banked mass; effect is observable"
  - "Compass shows depot bearing and distance when cargo loaded; nearest debris when empty"
  - "Starting sector field mass exceeds 110% of base cargo cap so full hold is reachable"
implements:
  - "scripts/home_depot.gd"
  - "scripts/progression.gd"
  - "scripts/cargo_hold.gd"
  - "scripts/navigation_system.gd"
  - "scripts/ship_scene.gd"
  - "scenes/Ship.tscn"
  - "project.godot"
last_reviewed: 2026-06-21
---

# F004 — Home depot and progression

Loop keystone: convert collection demo into fly-out / haul-back / upgrade rhythm.

## Summary

Cyan **home beacon** at origin is the v1 collection sink. Auto-deposit within
range banks mass; banked mass buys ship upgrades. Compass switches between
**outbound** (nearest debris) and **inbound** (depot when loaded).

## Scope

**In scope:**

- `HomeDepot` — deposit radius check, clear cargo, add to bank
- `Progression` — upgrade levels, costs, apply modifiers
- HUD: banked total, upgrade purchase keys
- Navigation objective: depot vs nearest harvestable

**Out of scope:**

- Refinery, material tiers, mining laser
- Persistent save (session bank optional v1; `user://` deferred)
- Full upgrade menu UI

## Tuning (GDScript)

| Constant | Value | Script |
|---|---|---|
| `deposit_radius` | 80 | `home_depot.gd` |
| `base_cargo_mass` | 500 | `cargo_hold.gd` |
| `cargo_upgrade_mass` | +100 per level | `progression.gd` |
| `cargo_upgrade_cost` | 150 / 350 | `progression.gd` |
| `tractor_range_upgrade` | +40 u per level | `progression.gd` |
| `tractor_upgrade_cost` | 120 / 280 | `progression.gd` |
| `cruise_accel_upgrade` | +25% per level | `progression.gd` |
| `cruise_upgrade_cost` | 200 / 450 | `progression.gd` |
| Max upgrade level | 2 each axis | `progression.gd` |

Upgrade axis for tractor: **range** (not cone width).

## Controls

- **U** — cycle upgrade selection (cargo / tractor / cruise)
- **Y** — purchase selected upgrade if affordable

## Compass modes

| Cargo state | Objective |
|---|---|
| `current_mass > 0` | Home depot at origin |
| empty | Nearest harvestable in radar range |

## Implementation notes

- `scripts/home_depot.gd`
- `scripts/progression.gd`
- Updates: `cargo_hold.gd`, `navigation_system.gd`, `ship_scene.gd`, `Ship.tscn`
