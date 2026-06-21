---
id: gdext-api-pinning
title: gdext API Pinning
status: active
layer: invariants
applies_to: ["crates/godot-ext/**", "accretion.gdextension"]
depends_on: [project-context]
last_reviewed: 2026-06-21
---

# gdext API pinning (invariant)

- `crates/godot-ext/Cargo.toml` MUST enable exactly one explicit `api-4-N` feature.
  Default (no `api-*` feature) is forbidden — it is non-reproducible.
- N is the highest `api-4-N` gdext publishes that is ≤ the installed Godot minor.
- `accretion.gdextension` `compatibility_minimum` MUST equal `4.N`.
  Check: feature `api-4-N` ⇔ `compatibility_minimum = 4.N`.
- The `godot` dependency is pinned to an exact version (`=X.Y.Z`); `Cargo.lock` is committed.
