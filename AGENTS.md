# AGENTS.md — Contributor & AI-Agent Guide

> **Wiki is the source of truth.** Start at **[wiki/README.md](wiki/README.md)** before
> any design or code change. This file is operational bootstrap only.

`accretion` is an accretion-disk game evolving toward solo spaceship exploration
and resource collection — built like scientific software with rigorous physics in
Rust and presentation in Godot 4.7.

**Docs:** [wiki/README.md](wiki/README.md) (canonical) · [README.md](README.md) (public) · [CONTRIBUTING.md](CONTRIBUTING.md)

## Cold start

1. Read [wiki/README.md](wiki/README.md) and [wiki/manifest.yaml](wiki/manifest.yaml)
2. Read [wiki/game-design/locked-decisions.md](wiki/game-design/locked-decisions.md)
3. Follow [wiki/workflow/cold-start-agents.md](wiki/workflow/cold-start-agents.md)
4. Load task-relevant pages from the manifest (`layer`, `applies_to`, feature `id`)

**Invariants** (full text in wiki, not here): [wiki/invariants/](wiki/invariants/)

## Setup

**After cloning, run `./scripts/setup-hooks.sh` once.** It sets
`core.hooksPath` (local config, *not* carried by a clone) and marks the hooks
executable. The hooks strip AI-tool attribution trailers from commit messages.
AI assistance is disclosed once, via the PR template's Provenance line — not
per-commit, and not inflated into the GitHub co-author graph.

Build the native library before opening the editor:

```sh
make check            # full gate: generators, invariants, wiki, test, clippy, build
# or manually:
cargo test            # physics golden tests (astropy oracle + analytic)
cargo build           # produces target/debug/libgodot_ext.dylib
# then open the Godot 4.7 project and run scenes/Main.tscn
```

Physical constants and golden fixtures are **generated** from astropy:
`python3 scripts/gen_constants.py` and `python3 scripts/gen_golden.py`.
Do not hand-edit `constants.rs` or `golden.json`.

## Repository map

```
accretion/
├── wiki/                       # Source of truth (design, invariants, RFCs)
├── crates/
│   ├── accretion-core/         # pure physics lib (CGS), cargo-testable
│   └── godot-ext/              # cdylib gdext binding — presentation only
├── accretion.gdextension       # native lib wiring (api-4-6, loads under 4.7)
├── project.godot, icon.svg     # Godot project
├── scenes/Main.tscn            # current BH survival slice
├── scripts/                    # GDScript glue (presentation only)
├── shaders/                    # blackhole (Tyler Kennedy, MIT) + starfield sky
├── .githooks/                  # tracked AI-attribution strip hooks
├── scripts/setup-hooks.sh      # per-clone hook wiring
├── .cursor/rules/              # thin pointers to wiki/
├── CHANGELOG.md, CITATION.cff  # repro metadata
├── README.md, CONTRIBUTING.md, LICENSE
└── .github/                    # CI workflow, PR + issue templates
```

## Workflow

1. Spec in wiki first ([wiki/workflow/concept-to-implementation.md](wiki/workflow/concept-to-implementation.md)).
2. Write (or update) golden tests alongside physics implementation.
3. Run locally before pushing: `make check`.
4. Update wiki + `manifest.yaml` + `last_reviewed` for any scope/behavior change.
5. Update `CHANGELOG.md` under `[Unreleased]` for user-visible changes.
6. Open one PR; fill the Provenance line (the single point of AI disclosure).

## What gets a change rejected

See [wiki/invariants/](wiki/invariants/) for full rules. Summary:

- A new physics formula or constant without a primary-source citation.
- A physical constant or formula in `godot-ext`, a shader, or GDScript.
- A physics change without a golden test.
- Scope/behavior change without a wiki update.
- Contradiction with [wiki/game-design/locked-decisions.md](wiki/game-design/locked-decisions.md).
- `make check` regresses.

## GitHub visibility (maintainers)

When publishing the repository, set the **About** description to:

> Accretion-disk explore game — ship flight, nav radar, tractor cargo; honest Rust physics, Godot 4.7 HDR. Companion to BlackHoleResearch.

Suggested **Topics:** `black-hole`, `accretion-disk`, `godot`, `rust`, `astrophysics`,
`shakura-sunyaev`, `gravitational-lensing`, `game`, `scientific-software`.

Enable **Issues** and **Discussions** if you want community feedback. CI badge in
README assumes the default branch is `main` and workflow file is
`.github/workflows/ci.yml`.
