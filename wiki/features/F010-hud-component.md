---
id: F010-hud-component
title: HUD Component
status: implemented
layer: features
depends_on: [game-shell, F008-game-shell, F003-navigation-radar, F002-tractor-cargo]
blocks: []
acceptance:
  - "GameHud.tscn listens to GameEvents; no _process polling on ship_scene root"
  - "Waypoint chevron clamps off-screen objective to viewport edge"
  - "Center reticle shows idle / in-cone / pulling / full states"
  - "Toast queue (3 slots) driven by GameEvents.toast"
  - "First-frame ship bearing uses look_at; matches atan2(x, -z) convention"
implements:
  - "scenes/ui/GameHud.tscn"
  - "scripts/ui/game_hud.gd"
  - "scripts/ui/waypoint_chevron.gd"
  - "scripts/ui/tractor_reticle.gd"
  - "scripts/ui/toast_queue.gd"
last_reviewed: 2026-06-21
---

# F010 — HUD component

## Summary

Extract HUD from `ship_scene.gd` into a dedicated scene fed by `GameEvents`.
Adds waypoint chevron, tractor reticle, and toast queue — the navigation legibility
layer Elite/NMS-style games expect.

## Widget updates

Each widget updates only when its signal fires — no unconditional string rebuild
every frame.
