---
id: sector-streaming
title: Sector Streaming
status: deferred
layer: architecture
depends_on: [architecture-overview, resource-loop]
last_reviewed: 2026-06-21
---

# Sector streaming (deferred)

Spec for procedural object loading. **Not implemented** until after harvest loop
(F001–F005 approximate). Captured here so architecture is documented before code.

## Goals

- Stable FPS with many harvestables
- No orbit-farming exploit (spawn without traveling)
- Deterministic sectors for solo save consistency

## Sector model

- Space divided into **sectors** (cube chunks; size TBD at implementation, e.g. 10–50 km).
- Seed: `hash(universe_id, sector_x, sector_y, sector_z)` — deterministic content.
- Generated on first entry; depletion state persisted per sector.

## Distance rings

| Ring | Distance | Behavior |
|---|---|---|
| **Active** | 0 – ~2 km | Full mesh, collision, harvestable |
| **LOD** | 2 – ~10 km | Impostor / MultiMesh; no collision |
| **Dormant** | > ~10 km | Hidden; logical instance retained |

## Anti-farming grace period

When the player leaves a sector:

- Instances remain in dormant pool for **60 s** OR until ship is **> N km** away
  (whichever comes first).
- Re-entry within grace: same objects, same depletion — no respawn.
- After grace: sector stays depleted until long cooldown or run reset.

## Hard caps (tuning constants — GDScript)

- Max active harvestables: ~50–200
- Max dormant instances: ~500
- Object pool for debris fragments — no per-shot `instantiate()`

## Godot tools

- `VisibleOnScreenNotifier3D` for culling
- `MultiMeshInstance3D` for debris swarms
- `SectorManager` autoload (future)
