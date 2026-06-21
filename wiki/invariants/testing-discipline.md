---
id: testing-discipline
title: Testing Discipline
status: active
layer: invariants
applies_to: ["crates/accretion-core/**/*.rs", "scripts/**/*.gd", "scenes/**/*.tscn"]
depends_on: [scientific-honesty]
last_reviewed: 2026-06-21
---

# Testing discipline

A regression-test net is a precondition for scaling this codebase. No physics
expands without its safety net. `cargo test` is the gate (the pytest of this
project). Presentation/shell regressions are caught by `make godot-presentation`.

## Test taxonomy

| Kind | Location | Purpose |
|---|---|---|
| **Unit** | `#[cfg(test)] mod tests` in the module | One per public function; synthetic inputs, hand-computed outputs. |
| **Golden / physics regression** | same | Reproduce a textbook value to a stated precision, with the citation in the test doc comment. |
| **Property** | same | Invariants that must hold for all inputs (monotonicity, round-trips, conservation). |
| **Presentation / shell** | `scripts/presentation_tests.gd` | Scene/script type pairs, autoload round-trips, shell navigation (settings back restores menu). |

## Required for every change

1. **A new public function** => a unit test exercising it with at least one
   hand-computed expected value.
2. **A new physics formula** => a golden test reproducing a textbook value to a
   stated precision, *and* a citation of the source in the test doc comment.
3. **A bug fix** => a failing test first, then the fix.
4. **A presentation/shell bug** (scene type mismatch, menu navigation) => add or extend
   `presentation_tests.gd` so CI cannot regress it.

## What a good golden test looks like

```rust
/// Golden test: Schwarzschild (spin 0) ISCO is exactly `6 GM/c^2`.
///
/// Reference: Bardeen, Press & Teukolsky 1972, ApJ 178, 347, Eq. (2.21).
#[test]
fn golden_isco_schwarzschild_is_six() {
    assert!((isco_radius(0.0) - 6.0).abs() < 1.0e-9);
}
```

## Precision honesty

State the tolerance and *why*. A textbook coefficient given to 3 significant
figures (e.g. `L_Edd = 1.26e38 erg/s`) cannot be asserted to 1e-6; assert to
the precision the source actually provides, and say so in the test. Exact
results (ISCO = 6 at spin 0) get tight tolerances.

## The current golden set (exit criteria for Slice 0)

- `golden.json` oracle cases for `l_eddington` and `disk_temperature` (astropy-generated).
- Schwarzschild ISCO ratio `r_isco / R_g == 6` (exact analytic).
- Shakura-Sunyaev scaling `T(2r)/T(r) == 2^(-3/4)` (exact analytic).

The gate is `make check` (or `cargo test` + `scripts/check_invariants.sh` + `make godot-presentation`) green plus
`cargo clippy --workspace -- -D warnings` clean.

## Physics-test radii (invariant)

- Radii in physics tests are named multiples of a physical scale via `r_s(m)` or
  `r_isco(m, a)`. Bare length literals are forbidden in `crates/accretion-core/tests/`.
  Check: `! grep -rEn '[0-9]+\.?[0-9]*[eE][+-]?[0-9]+' crates/accretion-core/tests --include='*.rs'`
- Any test radius MUST be ≥ `r_isco(m, a)` unless the test's purpose is the sub-ISCO
  regime, stated in a comment.

## Workspace boundary (invariant)

- `cargo tree -p accretion-core` MUST NOT contain `godot`. Enforced in `make check`.

## Things to avoid in tests

- Network or filesystem access. Tests are pure and offline.
- `assert_eq!` on floats. Use an explicit absolute/relative tolerance.
- Asserting on private internals; test the public surface.
- Randomness without a fixed seed.
