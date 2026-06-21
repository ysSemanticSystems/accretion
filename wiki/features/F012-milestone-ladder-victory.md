---
id: F012-milestone-ladder-victory
title: Exploration Milestones and Session Continue
status: implemented
layer: features
depends_on: [resource-loop, F004-home-depot-progression, F008-game-shell, F010-hud-component, F011-explore-world-soul]
blocks: []
acceptance:
  - "HUD shows M87* approach zone ladder (4 distance bands) — exploration feedback only, no win state"
  - "Reaching inner zones does not end or interrupt the run"
  - "Abandon from pause opens Exploration Log with closest M87* distance and deepest approach zone"
  - "Main menu shows closest M87* distance and Continue when an active run snapshot exists"
  - "Quit to Menu from pause saves run snapshot; Continue restores banked mass, upgrades, position"
  - "Upgrade dock shows approach ladder and upgrade progress (X/6)"
implements:
  - "scripts/autoload/session_save.gd"
  - "scripts/run_objectives.gd"
  - "scripts/ui/game_hud.gd"
  - "scripts/screens/upgrade_screen.gd"
  - "scripts/screens/main_menu.gd"
  - "scripts/screens/run_summary.gd"
  - "scripts/app_shell.gd"
  - "scripts/world_scale.gd"
last_reviewed: 2026-06-21
---

# F012 — Exploration milestones and session continue

## Summary

Visible **approach ladder toward M87*** and session Continue. There is **no win
condition** in the explore slice — only distance milestones, sector feedback, and
an exploration log when the player chooses to leave.

## Scope

**In:** Approach zone UI, `SessionSave`, Continue, profile closest-distance stats,
Exploration Log on abandon.

**Out:** Victory screens, forced run completion, prestige gates, cloud saves.

## Tuning

| Constant | Value | Location |
|---|---|---|
| `APPROACH_ZONE_DISTANCES` | 7500, 5200, 3400, 1400 km | `world_scale.gd` |
| `APPROACH_ZONE_COUNT` | 4 | `world_scale.gd` |

## Approach zones (not wins)

When distance to `BH_WORLD_POSITION` crosses a threshold, toast the zone label
(outer wake → disk plane). The run **never** auto-ends. Deepest zone and closest
distance appear on the Exploration Log when the player abandons or quits.

## Continue

`user://active_run.cfg` stores seed, progression, cargo, ship transform, approach
progress, elapsed time. Cleared on fresh New Run; preserved through Quit to Menu.
