---
id: architecture-layers
title: Architecture Layers
status: active
layer: architecture
depends_on: [architecture-overview]
last_reviewed: 2026-06-21
---

# Architecture layers

| Layer | Path | Responsibility | Physics? |
|---|---|---|---|
| **Wiki** | `wiki/` | Specs, invariants, design locks, RFCs | Documents only |
| **Core** | `crates/accretion-core/` | All physical formulas, constants, tests | Yes — cited |
| **Binding** | `crates/godot-ext/` | One-line delegation to core | No |
| **Presentation** | `shaders/`, `scripts/`, `scenes/` | Input, camera, HUD, VFX | No formulas |
| **Game systems** | `scripts/`, future `scenes/Ship.tscn` | Flight, harvest, sectors, upgrades | Tuning only in GDScript |

## When to add Rust vs GDScript

| Need | Where |
|---|---|
| Eddington limit, ISCO, disk T, blackbody color | `accretion-core` (exists) |
| Nucleosynthesis yields, r-process tables (future) | `accretion-core` + golden test |
| Camera smoothing, spawn caps, upgrade costs | GDScript + wiki feature spec |
| Ship thrust feel, tractor range | GDScript tuning; document in RFC |
| Lensing appearance | Shader stylization; radii/colors from Rust |

## Extension points (planned)

- `ShipController` — 3rd person flight ([F001](../features/F001-third-person-flight.md))
- `SectorManager` — streaming + anti-farm ([sector-streaming.md](sector-streaming.md))
- `HarvestSystem` — tractor, laser mining, refinery (future RFCs)
