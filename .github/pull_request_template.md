## Summary

<!-- 1–3 sentences: what changed and why. -->

## Exit criteria

- [ ] `make check` passes locally (generators byte-stable, invariants, test, clippy, build).
- [ ] Physics changes include primary-source citations and astropy-oracle / analytic tests.
- [ ] No physics leaked into `godot-ext`, shaders, or GDScript (rule 10).
- [ ] `CHANGELOG.md` updated under `[Unreleased]` if user-facing.

## How to test

```bash
./scripts/setup-hooks.sh   # if fresh clone
make check
# Godot 4.7 → run scenes/Main.tscn
```

## AI assistance

This PR was assisted by an AI agent (**yes** / **no**). This is the single point
of AI disclosure — not per-commit trailers.
