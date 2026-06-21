---
id: distance-and-visibility
title: Distance Scale and Visibility
status: active
layer: game-design
depends_on: [navigation, locked-decisions, F001-third-person-flight, F006-speed-camera-feel, F011-explore-world-soul]
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
| Cruise band | **250 km/s** cap | F001 v2 force budget |
| Home beacon | Origin `(0,0,0)` | Cyan pillar — depot reference |
| Skyline BH | `(0, 0, -12000)` km | Distant accretion disk — visual landmark (F011) |

## Debris visibility (F011)

| Element | Behavior |
|---|---|
| **Target bracket** | Screen-stable `Label3D` billboard — always on out to 8000 km |
| **Nav beacon** | Soft emissive sphere; **cross-fades out** 600→400 km |
| **Rock mesh** | Bus-scale (~12 km AABB); ramps in as beacon fades |
| **Clusters** | 4–7 belts × 8–16 rocks per sector, ~150 km cluster radius |

No hard pop at 500 km — transition band overlaps mesh and beacon.

## Speed perception (F006)

Primary motion cues (not HUD numbers):

- FOV widens with speed (70° → 86°)
- Near-field streak particles on camera
- Always-on parallax dust (F011)

## Visibility rings (legacy labels)

| Ring | Radius | What the player sees |
|---|---|---|
| **Mesh + bracket** | ≤ ~550 km (+ overlap) | Rock + bracket |
| **Beacon fade** | 400–600 km | Beacon alpha ↓, rock ↑ |
| **Bracket only** | ≤ 8000 km | Target bracket (+ fading beacon far) |
| **Radar** | ≤ 2500 km | Tactical blip + compass |

## Navigation outputs (F003)

- **Sector grid** — `Sector (x, y, z)` from ship position
- **Compass** — depot when cargo loaded, nearest debris when empty
- **Radar** — heading-up blips, depot cyan, objective highlight

## Future hooks

- Inner-sector radiation hazard tied to BH proximity (gameplay, not yet implemented)
- Wormhole / insertion prestige at disk (navigation.md)
