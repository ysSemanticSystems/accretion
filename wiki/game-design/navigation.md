---
id: navigation
title: Navigation Mechanics
status: active
layer: game-design
depends_on: [locked-decisions, vision, distance-and-visibility]
last_reviewed: 2026-06-21
---

# Navigation mechanics

Black holes and wormholes are **different navigation verbs**, not two names for
the same portal.

See [distance-and-visibility.md](distance-and-visibility.md) for the scale model
(1 unit = 1 km, visibility rings, radar compression).

## Wormhole — corridor travel (future)

**Player fantasy:** A rare, mapped shortcut between two known places.

**Verb:** *Locate throat → align → transit*

- Discover endpoints via scanning (SNR regions, anomaly pings)
- Requires **exotic matter / stabilizer** (r-process loot from supernova sites)
- **Repeatable** within a run; does not reset progression
- Visual: elongated throat, subtle lensing — **no accretion disk**

**Build when:** Map is large enough that flying between distant POIs feels tedious
without shortcuts. Not in current slice.

## Black hole — commitment gate (future prestige)

**Player fantasy:** Controlled insertion into a Kerr system you have studied.

**Verb:** *Approach → stabilize orbit → insertion burn*

- Requires map knowledge (disk plane, spin axis, ISCO distance)
- Requires ship stats (hardening, thrust, fuel) from collection
- **One-way** when prestige exists
- Visual: existing lensing shader, disk colors from Rust

**Build when:** Collection upgrade tree has a clear ceiling. Not in current slice.

## Current slice (implemented + integration)

- **3rd person flight** ([F001](../features/F001-third-person-flight.md))
- **Tractor + cargo** ([F002](../features/F002-tractor-cargo.md))
- **Home depot + upgrades** ([F004](../features/F004-home-depot-progression.md))
- **Seeded sector debris** ([F005](../features/F005-seeded-sector-debris.md))
- **Navigation HUD** ([F003](../features/F003-navigation-radar.md)):
  sector grid, **objective compass**, heading-up tactical radar, M87* approach ladder ([F012](../features/F012-milestone-ladder-victory.md))
- **Home beacon** at origin — depot sink + motion parallax reference
- **Distant accretion BH** on inward skyline ([F011](../features/F011-explore-world-soul.md)) — visual landmark in `Ship.tscn`
- **Debris visibility rings** — mesh / beacon / radar-only per distance
- No wormhole or BH transit mechanics

### Compass modes (F004)

| Cargo | Objective |
|---|---|
| Loaded | Home depot at origin — inbound |
| Empty | Nearest harvestable in radar range — outbound |

## One-line summary

**Wormholes move you around this universe; black holes move you out of it.**
