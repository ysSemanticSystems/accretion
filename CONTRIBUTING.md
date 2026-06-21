# Contributing to accretion

Thank you for helping build a rigorous accretion-disk game.

**Source of truth:** **[wiki/README.md](wiki/README.md)** — read it before your first PR.
Operational bootstrap: **[AGENTS.md](AGENTS.md)**.

## Quick checklist

1. **Clone setup:** `./scripts/setup-hooks.sh` (once per clone) or `make setup`.
2. **Dependencies:** `pip install -r scripts/requirements.txt`, Rust stable, Godot 4.7.
3. **Before push:** `make check` must pass (includes wiki validation).
4. **Wiki:** update for any scope/behavior change; cite feature `id:` if applicable.
5. **Physics:** formulas in `crates/accretion-core` only, with citations + tests.
6. **Changelog:** update `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
7. **PR template:** fill the AI assistance line once (not in commit trailers).

## Architecture invariant

```
wiki/             →  source of truth (design, invariants, feature RFCs)
accretion-core    →  numbers (physics, CGS, astropy-sourced constants)
godot-ext         →  one-line delegation to the core
shaders/scripts   →  presentation only
```

Full spec: [wiki/architecture/overview.md](wiki/architecture/overview.md).
Breaking the presentation boundary ([wiki/invariants/presentation-boundary.md](wiki/invariants/presentation-boundary.md)) will get a PR rejected.

## Questions

Open a [discussion](https://github.com/ysSemanticSystems/accretion/discussions) or
an issue using the templates in `.github/ISSUE_TEMPLATE/`.
