---
id: architecture-overview
title: Architecture Overview
status: active
layer: architecture
depends_on: [project-context]
last_reviewed: 2026-06-21
---

# Architecture overview

```mermaid
flowchart TB
  subgraph wikiLayer [Wiki source of truth]
    Wiki[wiki/]
  end
  subgraph coreLayer [accretion-core]
    Physics[Physics formulas CGS]
    Constants[constants.rs generated]
    Tests[golden tests]
  end
  subgraph binding [godot-ext]
    BlackHole[BlackHole node delegates]
  end
  subgraph presentation [Presentation]
    GDScript[scripts/ scenes/]
    Shaders[shaders/]
  end
  subgraph gameSystems [Game systems deferred]
    Ship[Ship controller]
    Sectors[Sector streaming]
    Harvest[Harvest refine upgrade]
  end
  Wiki --> coreLayer
  Wiki --> presentation
  Wiki --> gameSystems
  Physics --> BlackHole
  BlackHole --> GDScript
  BlackHole --> Shaders
  GDScript --> Ship
  GDScript --> Sectors
  GDScript --> Harvest
```

## Repository map

```
accretion/
├── wiki/                       # Source of truth (this tree)
├── crates/
│   ├── accretion-core/         # Pure physics (CGS), cargo-testable
│   └── godot-ext/              # Thin gdext binding
├── scenes/                     # Godot scenes
├── scripts/                    # GDScript glue
├── shaders/                    # Lensing + sky
├── accretion.gdextension       # Native lib wiring
└── scripts/check_*.sh          # Mechanical invariant + wiki checks
```

## Data flow (physics)

```
Player input → godot-ext (BlackHole) → accretion-core → numbers out → shader/HUD
```

Game-system loops (ship flight, harvesting) live in GDScript for now; any formula
that must be physically honest goes to `accretion-core` with citation + golden test.

See [layers.md](layers.md) for layer responsibilities.
