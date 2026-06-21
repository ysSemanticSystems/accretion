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
  - "Speed bands: impulse maneuver vs cruise change force budget not clamp only"
  - "Cruise spool ramp ~0.4 s on Shift hold before full cruise accel/drag"
  - "Q/E roll works with auto-level ON except during RMB look mode"
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
| `mouse_sensitivity` | 0.0045 (Settings default) | `ship_controller.gd`, `settings.gd` |
| `auto_level_strength` | 3.0 (roll-only) | `ship_controller.gd` |
| `cruise_accel_mult` | 4.0 | `ship_controller.gd` |
| `cruise_drag_mult` | 0.4 | `ship_controller.gd` |
| `cruise_spool_sec` | 0.4 | `ship_controller.gd` |
| `roll_speed` | 1.8 rad/s | `ship_controller.gd` |
| `bank_factor` | 0.32 (visual hull lean) | `ship_controller.gd` |
| `follow_distance` | 9.0 | `chase_camera.gd` |
| `follow_height` | 2.6 | `chase_camera.gd` |
| `position_smooth` | 9.0 | `chase_camera.gd` |

**Speed bands:** hold **Shift** for cruise; release for impulse. Cruise changes
**acceleration and drag**, not only the speed cap.

## Flight model v2

Cruise band force budget (not clamp-only):

- `_band_accel()`: `acceleration * cruise_accel_mult` in CRUISE else `acceleration`
- `_band_drag()`: `linear_drag * cruise_drag_mult` in CRUISE else `linear_drag`
- Target terminal cruise ≈ **430 km/s** before cap; cap **250 km/s** bites — gear feel
- **Cruise spool:** `cruise_spool_sec` ramp on Shift hold before full multipliers apply

Roll vs auto-level (v3 — fixes "can't turn around"):

- Auto-level is **roll-only**: it preserves the player's `forward` (pitch + yaw)
  exactly and relaxes only the roll toward upright. The previous version reprojected
  `forward` perpendicular to world-up every frame, which slowly decayed any pitch the
  player applied — the nose drifted back to the horizon, making it feel impossible to
  aim up/down or hold a heading toward home. Skipped when the nose is near-vertical
  (roll undefined).
- Manual roll (Q/E) always allowed.
- Mouse steering is accumulated in `_input` and applied in `_process`; default
  sensitivity raised to `0.0045` so turning is responsive.
- A subtle visual bank leans the **hull mesh only** into yaw (`bank_factor`); the
  physics body orientation is unchanged.

## Implementation notes

- `scenes/Ship.tscn` — standalone entry (F5 with scene open, or run from editor)
- `scripts/ship_controller.gd` — 6DOF flight on `ShipBody`
- `scripts/chase_camera.gd` — spring chase + RMB orbit look
- `scripts/ship_scene.gd` — HUD, mouse capture, input helpers
- Input map: `project.godot` (`ship_*` actions)
