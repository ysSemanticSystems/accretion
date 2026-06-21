---
id: scientific-honesty
title: Scientific Honesty
status: active
layer: invariants
applies_to: ["crates/accretion-core/**/*.rs"]
depends_on: [project-context]
last_reviewed: 2026-06-21
---

# Scientific honesty

The most important rule in this repo. A game built on physics quietly becomes
physically nonsensical the moment a number is faked. Numbers are honest or they
do not exist.

## 1. Never invent a value

If a quantity cannot be computed, a function returns one of:

- a documented sentinel (`0.0` for "no emission inside the inner edge",
  `f64::NAN` with a documented meaning);
- `Option::None` for a genuinely optional output;
- it does NOT silently return a plausible-looking number, a typical literature
  value, or zero-without-meaning.

## 2. Units are explicit and documented

Every public physics function documents the unit of every input and output in
its doc comment. SI is used internally end-to-end (kg, m, s, W, K). The only
unit conversions happen at clearly marked boundaries (e.g. erg/s <-> W, g/s
<-> kg/s), each with a named constant.

```rust
// GOOD: unit in the name / doc, conversion via a named constant.
/// Eddington luminosity `L_Edd` [erg/s] for a black hole of `mass_msun`.
pub fn l_eddington(mass_msun: f64) -> f64 { /* ... */ }

// BAD: what unit is this? erg/s? W? per gram?
pub fn ledd(m: f64) -> f64 { /* ... */ }
```

## 3. Every formula cites its primary source

A new physics function or physical constant without a primary-source citation
in its doc comment is rejected. Use the original paper where possible:

- Eddington luminosity → Eddington 1926.
- Radiative efficiency / thin disk → Novikov & Thorne 1973.
- Disk temperature profile → Shakura & Sunyaev 1973.
- ISCO → Bardeen, Press & Teukolsky 1972.
- Colorimetry → Planck 1901; CIE 1931; Wyman-Sloan-Shirley 2013; IEC 61966-2-1.

## 4. Constants are single-sourced and cited

Physical constants live once, in `accretion-core`, each tagged with its source.
Fundamentals (`G`, `c`, `M_sun`, `m_p`, `m_e`, `h`, `k_B`, `alpha`, ...) are
generated from astropy into `constants.rs` (CODATA / IAU). Composite constants
that are exact functions of fundamentals (`sigma_sb`, `sigma_T`) are DERIVED in
`derived.rs` with their formula + citation and pinned by a golden test — never
tabulated as a second independent copy (see [constants-provenance.md](constants-provenance.md)).
Do not redefine any of them anywhere else (not in `godot-ext`, not in a shader,
not in GDScript).

## 5. Hardcoded literature numbers are tech debt outside two places

| Location | Allowed? |
|---|---|
| `accretion-core` constants (with citation) | yes |
| test modules (as expected values for assertions) | yes |
| `godot-ext`, shaders, GDScript | no |

## 6. Surface game-affecting assumptions

When a default choice changes results (radiative efficiency `eta`, spin,
accretion rate), it is an explicit, documented parameter — not a magic number
buried in a calculation.

## 7. Document deliberately-missing physics

If a ported formula omits a term, say so in the doc comment, name the term, and
state the consequence. Current example: `disk_temperature` uses the bare
Shakura-Sunyaev form and omits the inner-boundary factor
`(1 - sqrt(r_in/r))^(1/4)`, so it is monotonic with no temperature peak. That
omission is documented in the function and tracked as a fast-follow; do not
silently "fix" it without a golden test for the new peak behavior.

## Checklist before merging a number-producing change

- [ ] Output unit documented (or explicitly dimensionless).
- [ ] Primary-source citation present in the doc comment.
- [ ] No invented / placeholder value on any code path.
- [ ] No physical constant duplicated outside `accretion-core`.
- [ ] A golden test asserts against the astropy oracle or an analytic identity ([testing-discipline.md](testing-discipline.md)).

## Golden values (invariant)

- Every numeric golden test value comes from an independent oracle: `scripts/gen_golden.py`
  computing the quantity with astropy. Never assert against a value produced by the Rust
  code under test (tautological), and never hand-type a magnitude.
- `crates/accretion-core/tests/fixtures/golden.json` is generated; regeneration is
  byte-identical or the build fails.
- Tolerance is explicit and stated in the test (`<= 1e-9 * |expected|`). Analytic
  identities (e.g. T(2r)/T(r) = 2^-3/4) are tested exactly, with no oracle.
