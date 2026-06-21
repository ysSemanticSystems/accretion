---
id: F009-settings-audio
title: Settings and Audio
status: implemented
layer: features
depends_on: [game-shell, F008-game-shell, F001-third-person-flight]
blocks: []
acceptance:
  - "Settings autoload persists user://settings.cfg"
  - "Settings menu exposes sensitivity, invert-Y, auto-level default, FOV rest/max, volumes, HUD scale, vsync"
  - "ship_controller and chase_camera read Settings on change (live preview in settings menu)"
  - "Master/SFX/Music buses; ambient loop in PLAYING; thrust and tractor procedural loops"
  - "UI feedback uses soft click/confirm/deny/deposit procedural SFX — no piercing menu beeps"
  - "Settings shows read-only control reference from InputMap"
implements:
  - "scripts/autoload/settings.gd"
  - "scripts/autoload/audio_manager.gd"
  - "scenes/screens/SettingsMenu.tscn"
last_reviewed: 2026-06-21
---

# F009 — Settings and audio

## Summary

Table-stakes mouse-flight settings and a minimal SFX bus layout. Sound defaults
on at 50% — collection chime re-enabled; procedural loops for thrust and tractor.

## Scope

**In:** Settings autoload, settings screen, audio buses, wired gameplay values.

**Out:** Full key rebinding UI, sourced music library (placeholder stream slot).

## Tuning defaults

| Key | Default |
|---|---|
| `mouse_sensitivity` | 0.0028 |
| `invert_y` | false |
| `fov_rest` / `fov_max` | 70 / 86 |
| `master_volume` / `sfx_volume` / `music_volume` | 0.5 |
| `hud_scale` | 1.0 |
| `vsync` | true |
