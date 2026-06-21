//! Shared helpers for integration tests.

#![allow(dead_code)]

/// Relative tolerance for oracle comparison (one part per billion).
pub const ORACLE_RTOL: f64 = 0.000000001;

/// Tight absolute tolerance for analytic identities.
pub const TOL: f64 = 0.000000001;

/// Relative tolerance for analytic identities at large magnitudes.
pub const RTOL: f64 = 0.000001;

/// Standard radiative efficiency used in many identity tests.
pub const ETA: f64 = 0.1;

/// Assert `got` matches `expected` within relative tolerance `rtol * |expected|`.
pub fn assert_relative_eq(got: f64, expected: f64, rtol: f64) {
    assert!(
        (got - expected).abs() <= rtol * expected.abs(),
        "got={got} expected={expected} rtol={rtol}"
    );
}

/// Assert `got` matches `expected` within absolute tolerance `tol`.
pub fn assert_abs_eq(got: f64, expected: f64, tol: f64) {
    assert!(
        (got - expected).abs() <= tol,
        "got={got} expected={expected} tol={tol}"
    );
}
