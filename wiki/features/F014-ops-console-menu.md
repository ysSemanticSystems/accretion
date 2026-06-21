---
id: F014-ops-console-menu
title: Ops Console Menu System
status: implemented
layer: features
depends_on: [F008-game-shell, F012-milestone-ladder-victory, F004-home-depot-progression]
blocks: []
acceptance:
  - "Tab during PLAYING opens full-screen Ops Console; Tab or Esc closes back to flight"
  - "Chart tab renders M87* approach nodes (Warframe star-chart pattern) with cleared/current/locked states"
  - "Arsenal tab shows upgrade tracks; purchases only when docked at home (F004 lock)"
  - "Intel tab shows live run readout (seed, sectors, BH distance, objective)"
  - "Cmd tab links Resume, Settings, Pause menu, Abandon without leaving shell"
  - "Ops Console pauses simulation like pause menu; depot UpgradeScreen remains separate dock flow"
implements:
  - "scripts/autoload/game_state.gd"
  - "scripts/app_shell.gd"
  - "scripts/screens/ops_console.gd"
  - "scripts/ui/ops_star_chart.gd"
  - "scripts/ui/ops_loadout_panel.gd"
  - "scripts/ui/ops_intel_panel.gd"
  - "scripts/ui/ops_cmd_panel.gd"
  - "scenes/screens/OpsConsole.tscn"
last_reviewed: 2026-06-21
---

# F014 — Ops console menu system

## Summary

In-flight **command console** (Helldivers galactic war-table sensibility) that fuses
progression, loadout, and navigation into one diegetic surface. The **Chart** tab is
the Warframe-style star chart: home beacon → four M87* approach gates → accretion
core. **Arsenal**, **Intel**, and **Cmd** tabs layer loadout, run telemetry, and
shell actions on the same ops board.

## Design references (presentation only)

| Reference | What we borrow |
|---|---|
| Warframe star chart | Node graph where traversal = progression; single surface for map + advancement |
| Helldivers 2 galactic table | Dark ops-board chrome, amber/cyan readouts, command-tab layout |
| Destiny Director | Clean tab hierarchy and low-friction open/close (Tab toggle) |

Not copied: multiplayer stratagem drops, gear mod depth, full galaxy simulation.

## Scope

**In:** `GameState.OPS`, `OpsConsole` screen, four tabs, Tab input, pause-menu link.

**Out:** Persistent meta unlocks across runs, wormhole map nodes, controller rebinding UI.

## Tabs

| Tab | Role |
|---|---|
| **Chart** | M87* approach ladder as connected nodes; live ship distance + cleared zones |
| **Arsenal** | Cargo / Tractor / Cruise tracks (same costs as depot shop) |
| **Intel** | Seed, elapsed time, banked mass, sectors, BH proximity, compass objective |
| **Cmd** | Resume flight, Settings, Pause menu, Abandon run |

## Input

| Action | Binding | Effect |
|---|---|---|
| `ops_console` | Tab | PLAYING ↔ OPS |
| `ui_cancel` | Esc | OPS → PLAYING |
| `1`–`4` | number keys | Switch tab while OPS open |

Depot auto-opens `UpgradeScreen` unchanged (F008). Arsenal duplicates purchase UI for
access anywhere; buys still require `HomeDepot.is_at_depot()`.

## Acceptance criteria

See frontmatter list. Chart nodes use `WorldScale.APPROACH_ZONE_*` and
`RunObjectives.max_approach_zone` — no duplicate thresholds in UI code.
