---
id: playability-roadmap
title: Playability Integration Roadmap
status: active
layer: game-design
depends_on: [vision, resource-loop, F001-third-person-flight, F002-tractor-cargo, F003-navigation-radar]
last_reviewed: 2026-06-21
---

# Playability integration roadmap

Master plan integrating external playability critique into wiki-first RFCs and
implementation waves. **Consequences before features** — close the loop, fix real
bugs, add feel, then enable replay.

## Validated findings

| Finding | Code anchor | Wave |
|---|---|---|
| Cruise band dead (cap-only, terminal ~43 km/s) | `ship_controller.gd` thrust/drag | F001 v2 (PR2) |
| Roll cancelled by auto-level | `Basis.looking_at` in `_apply_auto_level` | F001 v2 (PR2) |
| Wiki/code tuning drift | F001 table vs `mouse_sensitivity`, `auto_level_strength` | F001 v2 (PR2) |
| No speed cues; position km as motion proof | `distance-and-visibility.md`, `chase_camera.gd` | F006 (PR3) |
| Flat radar drops Y; world-fixed not heading-up | `navigation_radar.gd` | F003 amend (PR5) |
| Field mass 336 < 500 cap; no sink | `debris_field.gd`, `cargo_hold.gd` | F004 + F005 (PR1, PR6) |
| Silent collection; dead Area3D | `tractor_beam.gd`, `harvestable_debris.tscn` | F002 amend (PR4) |
| Static finite field | `debris_field.gd` spawn once | F005 (PR6) |

## Feature map

| RFC | Title | PR |
|---|---|---|
| [F004](../features/F004-home-depot-progression.md) | Home depot and progression | PR1 |
| [F001](../features/F001-third-person-flight.md) | Flight model v2 | PR2 |
| [F006](../features/F006-speed-camera-feel.md) | Speed and camera feel | PR3 |
| [F002](../features/F002-tractor-cargo.md) | Collection feedback | PR4 |
| [F003](../features/F003-navigation-radar.md) | Heading-up radar + stalks | PR5 |
| [F005](../features/F005-seeded-sector-debris.md) | Seeded sector debris (lite) | PR6 |

## PR sequencing

| PR | Scope | Blocks |
|---|---|---|
| PR0 | Wiki only | everything |
| PR1 | F004 loop closure | F005, compass objective |
| PR2 | F001 flight fixes | F006 cruise spool FOV |
| PR3 | F006 speed feel | — |
| PR4 | F002 juice + cleanup | — |
| PR5 | F003 nav radar | — |
| PR6 | F005 sector debris | replay |
| PR7 | Onboarding + perf | polish |

## Success criteria

After PR1+PR2+PR3+PR6:

1. Fly, feel cruise engage, sense speed without HUD numbers
2. Collect debris, fill hold, return to depot, bank mass, buy upgrade
3. Fly to a new sector, collect more, repeat — **one more run**

## Explicit defer list

- Scanner discovery verb
- Mining laser, onboard refinery
- Full `SectorManager` autoload + save persistence
- World collision / Jolt usage
- Rust / golden test changes
- BH survival loop wiring
- Audio library beyond minimal SFX stubs
