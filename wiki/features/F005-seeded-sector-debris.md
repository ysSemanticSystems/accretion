---
id: F005-seeded-sector-debris
title: Seeded Sector Debris (Lite)
status: implemented
layer: features
depends_on: [F004-home-depot-progression, sector-streaming, distance-and-visibility]
blocks: []
acceptance:
  - "Debris spawns deterministically per sector from run_seed + sector coords"
  - "Entering a new sector generates 8–14 harvestables if sector not depleted"
  - "Collecting all debris in a sector marks it depleted for the session"
  - "Re-entering a depleted sector shows no harvestables until new run"
  - "Sectors farther from origin yield higher mass multiplier"
  - "Starting sector total mass exceeds 110% of base cargo cap"
implements:
  - "scripts/sector_debris.gd"
  - "scripts/run_state.gd"
  - "scenes/Ship.tscn"
  - "scenes/harvestable_debris.tscn"
last_reviewed: 2026-06-21
---

# F005 — Seeded sector debris (lite)

Replay without full `SectorManager`. Deterministic sectors keyed by
`WorldScale.sector_coords()`; session depletion map; path to
[sector-streaming.md](../architecture/sector-streaming.md).

## Summary

Replace static 12-spec debris list with per-sector procedural generation.
Fly outward for richer fields; return to depot; depleted sectors stay empty
for the session.

## Scope

**In scope:**

- `SectorDebris` — generate on sector entry, track depletion
- `run_seed` on scene start
- Mass multiplier by Chebyshev distance from origin sector

**Out of scope:**

- `SectorManager` autoload
- Grace-period respawn (v2 per sector-streaming doc)
- Save/load depletion state
- Object pooling

## Tuning (GDScript)

| Constant | Value | Script |
|---|---|---|
| `debris_per_sector_min` | 8 | `sector_debris.gd` |
| `debris_per_sector_max` | 14 | `sector_debris.gd` |
| `debris_mass_min` | 15 | `sector_debris.gd` |
| `debris_mass_max` | 55 | `sector_debris.gd` |
| `sector_margin` | 80 | `sector_debris.gd` |
| `mass_dist_multiplier` | 0.15 per sector step | `sector_debris.gd` |

## Generation

```
seed = hash(run_seed, sector_x, sector_y, sector_z)
count = randi_range(min, max) from seeded RNG
position = random within sector cube minus margin
mass = randf_range(min, max) * (1 + multiplier * chebyshev_dist)
```

Static 12-spec array in old `debris_field.gd` retained in wiki as fixture example only.

## Implementation notes

- `scripts/sector_debris.gd` replaces `scripts/debris_field.gd`
- `scripts/run_state.gd` — run seed, depletion set
- Updates: `Ship.tscn`, `ship_scene.gd`
