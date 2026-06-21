# accretion wiki — source of truth

This directory is the **single authoritative specification** for accretion:
physics invariants, architecture, game design, feature scope, and workflow.
Humans and AI agents must read and obey it. When code or chat contradicts the
wiki, **update the wiki in the same change set** — then implement.

## Cold start (read this first)

1. [`manifest.yaml`](manifest.yaml) — machine index of every page
2. [`game-design/locked-decisions.md`](game-design/locked-decisions.md) — non-negotiable design locks
3. [`architecture/overview.md`](architecture/overview.md) — layer diagram and file map
4. Task-relevant pages via `layer`, `applies_to`, or feature `id` in frontmatter

Agents: follow [`workflow/cold-start-agents.md`](workflow/cold-start-agents.md).

Humans: follow [`workflow/concept-to-implementation.md`](workflow/concept-to-implementation.md).

## Authority layers

| Layer | Path | What it governs |
|---|---|---|
| Invariants | [`invariants/`](invariants/) | Physics honesty, tests, presentation boundary, CI |
| Architecture | [`architecture/`](architecture/) | Code layers, streaming, system design |
| Game design | [`game-design/`](game-design/) | Vision, locked decisions, navigation, loops |
| Features | [`features/`](features/) | RFC specs with acceptance criteria (`F###`) |
| Workflow | [`workflow/`](workflow/) | Concept → code → wiki sync |

## Quick links

- [Glossary](glossary.md)
- [Locked decisions](game-design/locked-decisions.md)
- [Feature template](features/_template.md)
- [Commit and PR rules](invariants/commit-and-pr.md)

## Outside the wiki

Generated oracles (`constants.rs`, `golden.json`), Rust inline citations, and
[`CHANGELOG.md`](../CHANGELOG.md) (user-facing release notes) stay outside.
Design truth lives here.
