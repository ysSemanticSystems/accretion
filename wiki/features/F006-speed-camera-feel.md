---
id: F006-speed-camera-feel
title: Speed and Camera Feel
status: implemented
layer: features
depends_on: [F001-third-person-flight, distance-and-visibility]
blocks: []
acceptance:
  - "Camera FOV lerps from ~70° at rest toward ~90° at max speed"
  - "Extra FOV widen during cruise spool (F001)"
  - "Near-field streak particles scale density with ship speed"
  - "rotation_smooth independently tunes camera basis lag vs position lag"
  - "RMB look uses InputEventMouseMotion not get_last_mouse_velocity"
  - "Player can sense motion in empty space without reading position km"
implements:
  - "scripts/chase_camera.gd"
  - "scenes/Ship.tscn"
last_reviewed: 2026-06-21
---

# F006 — Speed and camera feel

Cheapest high-impact feel levers for empty-space flight.

## Summary

Speed-proportional FOV, camera-parented streak particles, wired
`rotation_smooth`, and crisp RMB mouse look. Position km readout demoted to
debug — motion sold by eye, not numbers.

## Scope

**In scope:**

- Camera FOV lerp on `ChaseCamera` (render-frame `_process`, synced with ship)
- `GPUParticles3D` streak field parented to camera
- Optional follow-distance kick under acceleration
- RMB look via `_input` mouse motion

**Out of scope:**

- Collision-aware zoom
- Full motion blur post-process

## Tuning (GDScript)

| Constant | Value | Script |
|---|---|---|
| `fov_rest` | 70 | `chase_camera.gd` |
| `fov_max` | 86 | `chase_camera.gd` |
| `fov_cruise_bonus` | 4 | `chase_camera.gd` |
| `fov_smooth` | 10 | `chase_camera.gd` |
| `position_smooth` | 14 | `chase_camera.gd` |
| `rotation_smooth` | 16 | `chase_camera.gd` |

## Implementation notes

- `scripts/chase_camera.gd`
- `scenes/Ship.tscn` — particle node under camera
- Reads `ship.velocity` and cruise spool from `ship_controller.gd`
