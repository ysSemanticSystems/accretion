---
id: locked-decisions
title: Locked Game Design Decisions
status: active
layer: game-design
depends_on: [vision]
last_reviewed: 2026-06-21
---

# Locked decisions

These choices are **active** until explicitly revised in chat **and** this page
is updated in the same session/PR. Agents and implementers must not contradict them.

## Camera and controls

| Decision | Lock |
|---|---|
| Camera | **3rd person chase** (not cockpit-first) |
| Multiplayer | **Solo only** — no netcode, no replication |

## Combat and tools

| Decision | Lock |
|---|---|
| Combat | **None** until resource collection loop is fully established |
| Lasers | **Mining tool only** — break rocks/debris, not weapons |

## Current scope

| Decision | Lock |
|---|---|
| BH phase ratio | **100% explore + resource collection** for now |
| Accretion survival | **Deferred** — do not wire disk feeding / Eddington loop into ship gameplay yet |
| Black hole interaction | **Visual landmark only** — distant lensing disk, no traversal mechanics yet |
| Universe count | **TBD** — do not design multi-universe prestige until BH/wormhole navigation requires it |
| **Home depot** | **Origin beacon is v1 collection sink** until onboard refinery ships ([F004](../features/F004-home-depot-progression.md)) |

## Navigation (future — spec only)

| Mechanism | Role | Build when |
|---|---|---|
| **Wormhole** | In-universe corridor travel (repeatable, exotic-matter cost) | Map scale makes walking tedious |
| **Black hole** | One-way commitment / future prestige gate | Collection upgrade ceiling exists |

See [navigation.md](navigation.md) for verb definitions.

## Revision protocol

To change a lock: user approves → update this page → set `last_reviewed` →
implement in same or follow-up PR.
