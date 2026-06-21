---
id: F001-third-person-flight
title: Third Person Flight
status: implemented
layer: features
depends_on: [locked-decisions, architecture-overview, resource-loop]
blocks: []
acceptance:
  - "Playable 3rd person chase camera follows a ship in the starfield for 5+ minutes without nausea"
  - "6DOF arcade flight with capped momentum; WASD + mouse or equivalent"
  - "Optional auto-level; manual override always available"
  - "Speed bands: impulse maneuver vs cruise (tunable in GDScript, documented here)"
  - "Scene runnable standalone: scenes/Ship.tscn or equivalent entry point"
  - "No combat, harvesting, or BH interaction in this feature"
implements:
  - "scenes/Ship.tscn"
  - "scripts/ship_controller.gd"
  - "scripts/chase_camera.gd"
  - "scripts/ship_scene.gd"
last_reviewed: 2026-06-21
---

# F001 — Third person flight

First vertical slice after wiki lands. Proves controls and camera before any
collection systems.

## Summary

A flyable ship with 3rd person chase camera in the existing procedural
starfield. Arcade-assisted 6DOF flight feel is the deliverable — not realistic
orbital mechanics.

## Scope

**In scope:**

- `Ship` scene with `ShipController` GDScript
- Chase camera (spring-damped, collision-aware zoom TBD)
- Input: thrust, strafe, vertical, yaw/pitch (ship-relative)
- Starfield environment reuse from `Main.tscn` world setup

**Out of scope:**

- Tractor, laser, cargo, sectors, upgrades
- Black hole interaction (may remain visible as distant landmark later)
- Rust changes (unless exposing nothing new)

## Camera

Per [locked-decisions.md](../game-design/locked-decisions.md): **3rd person chase**

- Camera behind and above ship, spring-damped
- Hold-to-look: rotate camera without turning ship (for future targeting)
- Auto-zoom near geometry when added later

## Flight model (gameplay tuning — GDScript)

Arcade assist: capped velocity, auto-level on by default (toggle `L`).

| Constant | Value | Location |
|---|---|---|
| `impulse_max_speed` | 65 u/s (65 km/s display) | `ship_controller.gd` |
| `cruise_max_speed` | 250 u/s | `ship_controller.gd` |
| `acceleration` | 50 | `ship_controller.gd` |
| `linear_drag` | 1.15 | `ship_controller.gd` |
| `mouse_sensitivity` | 0.0022 | `ship_controller.gd` |
| `auto_level_strength` | 4.0 | `ship_controller.gd` |
| `roll_speed` | 1.6 rad/s | `ship_controller.gd` |
| `follow_distance` | 9.0 | `chase_camera.gd` |
| `follow_height` | 2.6 | `chase_camera.gd` |
| `position_smooth` | 9.0 | `chase_camera.gd` |

**Speed bands:** hold **Shift** for cruise; release for impulse.

## Implementation notes

- `scenes/Ship.tscn` — standalone entry (F5 with scene open, or run from editor)
- `scripts/ship_controller.gd` — 6DOF flight on `ShipBody`
- `scripts/chase_camera.gd` — spring chase + RMB orbit look
- `scripts/ship_scene.gd` — HUD, mouse capture, input helpers
- Input map: `project.godot` (`ship_*` actions)
