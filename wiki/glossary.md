---
id: glossary
title: Glossary
status: active
layer: workflow
depends_on: []
last_reviewed: 2026-06-21
---

# Glossary

| Term | Meaning |
|---|---|
| **accretion-core** | Pure Rust physics library (CGS). Zero Godot dependency. |
| **gdext / godot-ext** | Thin cdylib binding; one-line delegation to core. |
| **Presentation layer** | `godot-ext`, shaders, GDScript, scenes — no physics formulas. |
| **Golden test** | Regression test against astropy oracle or analytic identity. |
| **RFC / feature** | Spec in `wiki/features/F###-*.md` with acceptance criteria. |
| **Locked decision** | Design choice in `locked-decisions.md`; do not contradict without wiki update. |
| **Sector** | Spatial chunk (1000 km edge) for procedural harvestable placement ([F005](features/F005-seeded-sector-debris.md)). |
| **Depot** | Home beacon at origin; auto-deposits cargo when ship in range ([F004](features/F004-home-depot-progression.md)). |
| **Banked mass** | Session total deposited at depot; spent on upgrades. |
| **Run seed** | Deterministic seed for sector debris generation ([F005](features/F005-seeded-sector-debris.md)). |
| **Navigation objective** | Compass target: depot when loaded, nearest debris when empty. |
| **Prestige** | Future one-way black-hole traversal resetting local progress (deferred). |
