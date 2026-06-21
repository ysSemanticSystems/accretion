---
id: F008-game-shell
title: Game Shell and Menus
status: implemented
layer: features
depends_on: [game-shell, F004-home-depot-progression]
blocks: [F009-settings-audio, F010-hud-component]
acceptance:
  - "main_scene is scenes/Main.tscn with BOOT→MENU→PLAYING→PAUSED→OPS→UPGRADE→SUMMARY→LAB"
  - "Esc in PLAYING opens pause menu; Tab opens Ops Console; Esc/Tab in OPS resumes flight"
  - "Depot upgrade dock enters GameState.UPGRADE (paused); Esc closes back to PLAYING"
  - "Main menu BH Lab opens BhSurvival.tscn; Esc returns to menu"
  - "Upgrade purchase gated to depot radius; docked UpgradeScreen replaces U/Y HUD shop"
  - "Run summary shows seed, banked mass, sectors, upgrades, max distance, time"
implements:
  - "scripts/autoload/game_state.gd"
  - "scripts/autoload/game_events.gd"
  - "scripts/app_shell.gd"
  - "scenes/Main.tscn"
  - "scenes/screens/"
  - "scripts/autoload/game_shell.gd"
  - "scripts/screens/ops_console.gd"
  - "scenes/screens/OpsConsole.tscn"
last_reviewed: 2026-06-21
---

# F008 — Game shell and menus

## Summary

Root state machine + screen stack. Ship slice is instanced only in `PLAYING`.
Menus, pause, upgrade dock, and run summary have a home. `GameShell` autoload
holds a typed reference to `AppShell` for settings, upgrade dock, and save helpers.

## State flow

```
BOOT → MENU → PLAYING ⇄ PAUSED | OPS | UPGRADE → SUMMARY → LAB
```

`PLAYING`, `PAUSED`, `OPS`, and `UPGRADE` pause the scene tree. Esc from pause
returns to flight; Tab toggles the ops console; depot upgrade dock uses `UPGRADE`.

## Scope

**In:** `GameState`, `GameEvents`, `AppShell`, main/pause/settings/upgrade/summary
screens, `BhMenuBackdrop`, move legacy BH slice to `BhSurvival.tscn`.

**Out:** Continue/save slots, key rebinding UI (second pass), controller support.

## Depot seam fix

| Before | After |
|---|---|
| HUD upgrade hint at 120 km | Removed — single `DEPOT_RADIUS_UNITS = 80` |
| `try_purchase()` anywhere on Y | Only from `UpgradeScreen` at depot |
| Deposit at 80 km | Unchanged; opens upgrade dock when banked mass > 0 |

## Run summary fields

Seed, banked mass, sectors visited, upgrades bought, max Chebyshev distance, elapsed time.
