---
id: mechanical-gates
title: Mechanical Quality Gates
status: active
layer: invariants
depends_on: [testing-discipline, presentation-boundary]
last_reviewed: 2026-06-21
---

# Mechanical quality gates

`make check` enforces the following. Human review covers what scripts cannot
(reasoning, UX, design locks).

## Rust / repo (check_invariants.sh)

| ID | Check |
|---|---|
| C1 | `constants.rs` generated and byte-stable |
| C2 | No `e`-notation literals outside `constants.rs` in core `src/` |
| C3 | `golden.json` generated and byte-stable |
| C4 | No `e`-notation in integration tests |
| C5 | gdext API pin matches `compatibility_minimum` |
| C6 | `accretion-core` has zero `godot` in dependency tree |
| C7 | No banned physics patterns in `scripts/**/*.gd` or `shaders/**/*.gdshader` |

## Wiki (check_wiki.sh)

| ID | Check |
|---|---|
| W1 | Required frontmatter on wiki pages |
| W2 | `manifest.yaml` matches wiki pages |
| W3 | Internal wiki links resolve |
| W4 | `depends_on` / `blocks` reference valid ids |
| W5 | `status: implemented` requires non-empty `implements` |
| W6 | `locked-decisions.md` active with `last_reviewed` |
| W7 | `.cursor/rules` are thin pointers |
| W8 | Root docs link to `wiki/README.md` |
| W9 | Every `implements` path on implemented features exists in the repo |

## Rust toolchain (Makefile)

- `cargo test --workspace`
- `cargo clippy --workspace --all-targets -- -D warnings`
- `cargo fmt --check`

## Godot (Makefile)

- `make godot-smoke` — GDExtension API surface
- `make godot-presentation` — scene/script compat + shell regressions

## Local-only

- `./scripts/setup-hooks.sh` (`make setup`) — AI attribution strip on commits; not part of CI signal.
