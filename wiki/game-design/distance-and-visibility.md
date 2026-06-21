---
id: distance-and-visibility
title: Distance Scale and Visibility
status: active
layer: game-design
depends_on: [navigation, locked-decisions, F001-third-person-flight, F006-speed-camera-feel]
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
| Impulse band | **65 km/s** cap | Terminal ~43 km/s at base tuning |
| Cruise band | **250 km/s** cap | F001 v2 force budget; ~400 km crossing in ~2 s |
| Home beacon | Origin `(0,0,0)` | Cyan pillar — depot + parallax reference |

True distances drive **compass**, **cargo timing**, and **tractor range**.
The **radar disc** uses **sqrt compression** so far blips stay on-screen without
lying about compass distance.

## Speed perception (F006)

Primary motion cues (not HUD numbers):

- FOV widens with speed (70° → 90°)
- Near-field streak particles on camera
- Optional chase distance kick under thrust

Position `(x, y, z) km` readout remains for debug; not the primary motion sell.

## Visibility rings

| Ring | Radius | What the player sees |
|---|---|---|
| **Mesh** | ≤ 500 km | Full debris sphere |
| **Beacon** | 500–8000 km | Large emissive marker only |
| **Radar only** | ≤ 2500 km | Blip on tactical radar + compass bearing |
| **Off-radar** | > 2500 km | Hidden until adjacent sector entered (F005) |

## Navigation outputs (F003)

- **Sector grid** — `Sector (x, y, z)` from ship position
- **Position** — `(x, y, z) km` debug readout
- **Compass** — navigation objective (depot or nearest debris), true km, bearing
- **Radar** — heading-up blips with altitude stalks, sqrt-scaled layout

## Future hooks

- Wormhole / BH landmarks register as `nav_poi` group with distinct blip color
- Full sector streaming per [sector-streaming.md](../architecture/sector-streaming.md)
