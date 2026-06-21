# AGENTS.md — Contributor & AI-Agent Guide

> Read this **before** writing or modifying any code. The rules below apply to
> humans and AI agents equally. Cursor loads this file and `.cursor/rules/`
> automatically.

`accretion` is an accretion-disk survival/management game built like scientific
software: the physics is honest, every formula cites a primary source, and the
core is independently testable. It is the game-side companion to
[`ysSemanticSystems/BlackHoleResearch`](https://github.com/ysSemanticSystems/BlackHoleResearch),
and inherits its discipline — relocated from Python/Streamlit to Rust/Godot.

**Docs:** [README.md](README.md) (public face) · [CONTRIBUTING.md](CONTRIBUTING.md) · [CITATION.cff](CITATION.cff)

## Setup

**After cloning, run `./scripts/setup-hooks.sh` once.** It sets
`core.hooksPath` (local config, *not* carried by a clone) and marks the hooks
executable. The hooks strip AI-tool attribution trailers from commit messages.
AI assistance is disclosed once, via the PR template's Provenance line — not
per-commit, and not inflated into the GitHub co-author graph.

Build the native library before opening the editor:

```sh
make check            # full gate: generators, invariants, test, clippy, build
# or manually:
cargo test            # physics golden tests (astropy oracle + analytic)
cargo build           # produces target/debug/libgodot_ext.dylib
# then open the Godot 4.7 project and run scenes/Main.tscn
```

Physical constants and golden fixtures are **generated** from astropy:
`python3 scripts/gen_constants.py` and `python3 scripts/gen_golden.py`.
Do not hand-edit `constants.rs` or `golden.json`.

## Prime directives (memorize)

1. **Honesty over completeness** — never invent a value, unit, or uncertainty.
2. **Cite every formula** — primary-source reference in every physics doc comment.
3. **Physics lives in `crates/accretion-core`** — `godot-ext`, shaders, and
   GDScript present numbers; they do not compute them (rule 10).
4. **Tests precede expansion** — a new physics formula lands with a golden test
   reproducing a textbook value to a stated precision (rule 05).
5. **Single source of truth** — physical constants live once, in
   `accretion-core` (CGS, CODATA/IAU), each cited.

## Repository map

```
accretion/                      # repo root (Godot 4.7 project lives here)
├── Cargo.toml                  # [workspace]
├── crates/
│   ├── accretion-core/         # pure physics lib (CGS), cargo-testable
│   └── godot-ext/              # cdylib gdext binding — presentation only
├── accretion.gdextension       # native lib wiring (api-4-6, loads under 4.7)
├── project.godot, icon.svg     # Godot project
├── scenes/Main.tscn            # scene: lensing BH + disk + mass slider
├── scripts/main.gd             # GDScript glue (presentation only)
├── shaders/                    # blackhole (Tyler Kennedy, MIT) + starfield sky
├── .githooks/                  # tracked AI-attribution strip hooks
├── scripts/setup-hooks.sh      # per-clone hook wiring
├── .cursor/rules/              # persistent AI guidance (5 rules)
├── CHANGELOG.md, CITATION.cff  # repro metadata
├── README.md, CONTRIBUTING.md, LICENSE
└── .github/                    # CI workflow, PR + issue templates
```

## Workflow

1. Write (or update) the golden test alongside the implementation.
2. Run locally before pushing: `cargo test`, `cargo clippy --workspace -- -D
   warnings`, `cargo fmt --check`.
3. Update `CHANGELOG.md` under the appropriate version heading.
4. Open one PR; fill the Provenance line (the single point of AI disclosure).

## What gets a change rejected

- A new physics formula or constant without a primary-source citation.
- A physical constant or formula in `godot-ext`, a shader, or GDScript (rule 10).
- A physics change without a golden test.
- `cargo clippy --workspace -- -D warnings` regresses.

## GitHub visibility (maintainers)

When publishing the repository, set the **About** description to:

> Accretion-disk survival game — honest Rust physics, Godot 4.7 HDR lensing. Companion to BlackHoleResearch.

Suggested **Topics:** `black-hole`, `accretion-disk`, `godot`, `rust`, `astrophysics`,
`shakura-sunyaev`, `gravitational-lensing`, `game`, `scientific-software`.

Enable **Issues** and **Discussions** if you want community feedback. CI badge in
README assumes the default branch is `main` and workflow file is
`.github/workflows/ci.yml`.

## Known deferred physics (be honest about it)

- `disk_temperature` uses the **bare** Shakura-Sunyaev form (`T ∝ r^(-3/4)`,
  no inner-boundary factor), so there is no temperature peak / dark inner gap
  yet. The inner-boundary correction is a logged fast-follow.
