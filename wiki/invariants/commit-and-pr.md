---
id: commit-and-pr
title: Commits and Pull Requests
status: active
layer: invariants
depends_on: [project-context]
last_reviewed: 2026-06-21
---

# Commits and PRs

## AI attribution is suppressed by policy

This repo deliberately keeps AI/agent attribution OUT of commit trailers and
the contributor graph. Tracked hooks (`.githooks/prepare-commit-msg` and
`.githooks/commit-msg`, both delegating to `.githooks/strip-ai-attribution.sh`)
strip `Co-authored-by:` lines naming Cursor and "Generated with ... Cursor"
attribution. The strip script always exits 0, so it can never block a commit.
AI assistance is disclosed ONCE, in the PR description's Provenance line, not
smeared across every commit.

After cloning, run once: `./scripts/setup-hooks.sh` (sets `core.hooksPath`,
which lives in `.git/config` and is not carried by a clone).

## Commit messages

- Imperative mood: "Add ISCO radius," not "Added" or "Adds."
- Subject line <= 72 chars, no trailing period.
- Body wrapped at ~80 columns, separated from the subject by a blank line.
- One logical change per commit.
- Do NOT add `Co-authored-by:` trailers (the hook removes them anyway).

### Good

```
Add Bardeen+1972 ISCO radius with golden test

isco_radius(spin) returns the prograde Kerr ISCO in gravitational radii
via the Bardeen-Press-Teukolsky Z1/Z2 expression. Golden test pins the
Schwarzschild value to exactly 6 GM/c^2.
```

### Bad

```
fixed stuff
```

## Pull requests

A PR is mergeable when:

1. **Title** summarizes the change in imperative mood.
2. **CI / local checks** are green: `make check` (`cargo test`, clippy, wiki checks, Godot smoke).
3. **Physics changes** carry a primary-source citation and a golden test.
4. **No physics leaked into `godot-ext`/shaders/GDScript** ([presentation-boundary.md](presentation-boundary.md)).
5. The **AI-assistance disclosure** line is filled in (once, here).
6. **Wiki updated** for any scope or behavior change (cite feature `id:` if applicable);
   `manifest.yaml` and `last_reviewed` updated on touched pages; no contradiction with
   [`locked-decisions.md`](../game-design/locked-decisions.md).

## PR description template

```markdown
## Summary
1-3 sentences on what changes and why.

## Exit criteria
- [ ] `make check` passes (generators byte-stable, invariants, wiki, test, clippy, build).
- [ ] Physics changes include primary-source citations and astropy-oracle / analytic tests.
- [ ] No physics leaked into `godot-ext`, shaders, or GDScript.
- [ ] Wiki updated for any scope/behavior change (cite feature `id:` if applicable).
- [ ] `manifest.yaml` and `last_reviewed` updated on touched pages.
- [ ] No contradiction with wiki/game-design/locked-decisions.md.
- [ ] `CHANGELOG.md` updated under `[Unreleased]` if user-facing.

## How to test locally
```bash
make check
# Godot 4.7 → run relevant scene
```

## AI assistance
This PR was assisted by an AI agent (yes/no).
```
