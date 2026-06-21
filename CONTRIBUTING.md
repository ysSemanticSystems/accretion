# Contributing to accretion

Thank you for helping build an honest accretion-disk game. The full operational
guide is **[AGENTS.md](AGENTS.md)** — read it before your first PR.

## Quick checklist

1. **Clone setup:** `./scripts/setup-hooks.sh` (once per clone).
2. **Dependencies:** `pip install -r scripts/requirements.txt`, Rust stable, Godot 4.7.
3. **Before push:** `make check` must pass.
4. **Physics:** formulas in `crates/accretion-core` only, with citations + tests.
5. **Changelog:** update `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
6. **PR template:** fill the AI assistance line once (not in commit trailers).

## Architecture invariant

```
accretion-core  →  numbers (physics, CGS, astropy-sourced constants)
godot-ext       →  one-line delegation to the core
shaders/scripts →  presentation only
```

Breaking this boundary (rule `10-presentation-boundary`) will get a PR rejected.

## Questions

Open a [discussion](https://github.com/ysSemanticSystems/accretion/discussions) or
an issue using the templates in `.github/ISSUE_TEMPLATE/`.
