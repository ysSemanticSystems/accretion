## Summary

<!-- 1–3 sentences: what changed and why. Cite wiki feature id: if applicable (e.g. F001). -->

## Exit criteria

- [ ] `make check` passes locally (generators byte-stable, invariants, wiki, test, clippy, build).
- [ ] Physics changes include primary-source citations and astropy-oracle / analytic tests.
- [ ] No physics leaked into `godot-ext`, shaders, or GDScript (wiki/invariants/presentation-boundary.md).
- [ ] Wiki updated for any scope/behavior change (cite feature `id:` if applicable).
- [ ] `manifest.yaml` and `last_reviewed` updated on touched wiki pages.
- [ ] No contradiction with wiki/game-design/locked-decisions.md.
- [ ] `CHANGELOG.md` updated under `[Unreleased]` if user-facing.

## How to test

```bash
./scripts/setup-hooks.sh   # if fresh clone
make check
# Godot 4.7 → run relevant scene
```

## AI assistance

This PR was assisted by an AI agent (**yes** / **no**). This is the single point
of AI disclosure — not per-commit trailers.
