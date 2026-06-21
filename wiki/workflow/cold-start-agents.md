---
id: cold-start-agents
title: Cold-Start Agents
status: active
layer: workflow
depends_on: [concept-to-implementation, wiki-maintenance]
last_reviewed: 2026-06-21
---

# Cold-start agents

Mandatory boot sequence for AI agents with no prior chat context.

## Boot sequence

1. Read [`wiki/README.md`](../README.md) and [`wiki/manifest.yaml`](../manifest.yaml).
2. Read [`game-design/locked-decisions.md`](../game-design/locked-decisions.md).
3. Load task-relevant pages:
   - Editing Rust physics → `invariants/scientific-honesty.md`, `testing-discipline.md`
   - Editing Godot presentation → `invariants/presentation-boundary.md`, `locked-decisions.md`
   - Implementing a feature → matching `features/F###-*.md` (must be `accepted` or later)
4. Before ending a session that changed scope or code:
   - Update affected wiki pages
   - Update `manifest.yaml` if pages were added
   - Set `last_reviewed` on every touched page

## Hard rules

- Do not contradict [`locked-decisions.md`](../game-design/locked-decisions.md) unless
  the user explicitly revises a lock **and** the wiki is updated in the same session/PR.
- Do not implement `proposed` or `deferred` features without explicit user override.
- Do not add physics formulas outside `accretion-core` (see
  [`presentation-boundary.md`](../invariants/presentation-boundary.md)).
- Never ship a behavior change without a wiki update in the same change set.

## Pointer rules

[`.cursor/rules/13-wiki-governance.mdc`](../../.cursor/rules/13-wiki-governance.mdc) loads
this boot sequence via `alwaysApply`. Other rules point to `wiki/invariants/` by topic.
