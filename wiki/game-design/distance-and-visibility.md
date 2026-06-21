---
id: distance-and-visibility
title: Distance Scale and Visibility
status: active
layer: game-design
depends_on: [navigation, locked-decisions]
last_reviewed: 2026-06-21
---

# Distance scale and visibility

Bridges **realistic space distances** with **playable traversal** and **readable
navigation**. Presentation tuning only (GDScript + wiki); no physics formulas.

## Scale model

| Concept | Value | Notes |
|---|---|---|
| Game unit | **1 km** displayed | `WorldScale.UNITS_PER_KM = 1` |
| Sector cube | **1000 km** edge | Aligns with [sector-streaming.md](../architecture/sector-streaming.md) |
| Impulse band | **65 km/s** feel | Tight maneuver near POIs |
| Cruise band | **250 km/s** feel | Crossing debris field (~400 km) in ~2 s |
| Home beacon | Origin `(0,0,0)` | Cyan pillar — parallax reference for motion |

True distances drive **compass**, **cargo timing**, and **tractor range**.
The **radar disc** uses **sqrt compression** so far blips stay on-screen without
lying about compass distance.

## Visibility rings

| Ring | Radius | What the player sees |
|---|---|---|
| **Mesh** | ≤ 500 km | Full debris sphere |
| **Beacon** | 500–8000 km | Large emissive marker only |
| **Radar only** | ≤ 2500 km | Blip on tactical radar + compass bearing |
| **Off-radar** | > 2500 km | Hidden until streaming adds sectors (future) |

## Navigation outputs (F003)

- **Sector grid** — `Sector (x, y, z)` from ship position
- **Position** — `(x, y, z) km` live readout (proves movement in empty space)
- **Compass** — nearest harvestable, true km, bearing degrees
- **Radar** — top-down blips, sqrt-scaled layout, true range in compass/HUD

## Future hooks

- Wormhole / BH landmarks register as `nav_poi` group with distinct blip color
- Sector streaming swaps mesh/beacon rings per [sector-streaming.md](../architecture/sector-streaming.md)
