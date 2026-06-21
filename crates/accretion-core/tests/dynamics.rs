//! Analytic identities for the time-evolution / gameplay dynamics.

use accretion_core as phys;

const EFFICIENCY: f64 = 0.1;
const TOL: f64 = 0.000000001;
const RTOL: f64 = 0.000000001;

/// Mass growth keeps the radiated fraction out of the hole:
/// `M(t + dt) - M(t) = (1 - eta) * Mdot * dt` exactly (in grams).
///
/// Reference: Frank, King & Raine 2002, Ch. 1.
#[test]
fn advance_mass_retains_one_minus_eta() {
    const M0: f64 = 10.0;
    let mdot = phys::mdot_from_luminosity(phys::l_eddington(M0), EFFICIENCY);
    // Step one Salpeter time so the mass gain is comparable to M0 (well
    // conditioned); a tiny step would lose the gain to float cancellation.
    let dt = phys::salpeter_time_s(EFFICIENCY);
    let m1 = phys::advance_mass(M0, mdot, EFFICIENCY, dt);
    let gained_g = (m1 - M0) * phys::constants::M_SUN;
    let expected_g = (1.0 - EFFICIENCY) * mdot * dt;
    assert!((gained_g - expected_g).abs() <= RTOL * expected_g.abs());
}

/// Zero feed leaves the mass unchanged regardless of efficiency.
#[test]
fn advance_mass_zero_feed_is_static() {
    const M0: f64 = 4_000_000.0;
    assert!((phys::advance_mass(M0, 0.0, EFFICIENCY, 1000.0) - M0).abs() < TOL);
}

/// The Salpeter time equals `M / (dM/dt)` when accreting at the Eddington rate,
/// using an independent path through `l_eddington` / `mdot_from_luminosity`.
///
/// Reference: Salpeter 1964, ApJ 140, 796.
#[test]
fn salpeter_time_is_eddington_efolding() {
    const M: f64 = 100_000_000.0;
    let mdot_edd = phys::mdot_from_luminosity(phys::l_eddington(M), EFFICIENCY);
    let growth_rate_gs = (1.0 - EFFICIENCY) * mdot_edd;
    let efold_s = (M * phys::constants::M_SUN) / growth_rate_gs;
    let got = phys::salpeter_time_s(EFFICIENCY);
    assert!((got - efold_s).abs() <= RTOL * efold_s.abs());
}

/// Integrity driver is the radiation-modified support fraction `1 - lambda`.
#[test]
fn integrity_rate_sign_and_marginal() {
    assert!((phys::integrity_rate(0.0) - 1.0).abs() < TOL);
    assert!(phys::integrity_rate(1.0).abs() < TOL);
    assert!(phys::integrity_rate(2.0) < 0.0);
    assert!(phys::integrity_rate(0.5) > 0.0);
}

/// Schwarzschild radiative efficiency is exactly `1 - sqrt(8/9) ~= 0.0572`.
///
/// Reference: Bardeen, Press & Teukolsky 1972; Novikov & Thorne 1973.
#[test]
fn efficiency_schwarzschild_is_one_minus_sqrt_8_9() {
    let expected = 1.0 - (8.0_f64 / 9.0).sqrt();
    assert!((phys::efficiency_from_spin(0.0) - expected).abs() < TOL);
}

/// Near-maximal spin (Thorne limit) lands in the canonical ~0.30-0.33 band and
/// efficiency increases monotonically with spin.
#[test]
fn efficiency_rises_with_spin() {
    let eta0 = phys::efficiency_from_spin(0.0);
    let eta_mid = phys::efficiency_from_spin(0.9);
    let eta_thorne = phys::efficiency_from_spin(0.998);
    assert!(eta0 < eta_mid);
    assert!(eta_mid < eta_thorne);
    assert!(eta_thorne > 0.30 && eta_thorne < 0.33);
}

/// Orbital frequency scales as `1 / M` and is positive.
///
/// Reference: Bardeen, Press & Teukolsky 1972.
#[test]
fn orbital_frequency_scales_inverse_mass() {
    const M: f64 = 10.0;
    let f1 = phys::orbital_frequency_hz(M, 6.0, 0.0);
    let f2 = phys::orbital_frequency_hz(2.0 * M, 6.0, 0.0);
    assert!(f1 > 0.0);
    assert!((f2 - f1 / 2.0).abs() <= RTOL * (f1 / 2.0));
}

/// Schwarzschild ISCO specific angular momentum is `6 sqrt(2)` in the BPT
/// dimensionless convention used by `advance_spin`.
///
/// Reference: Bardeen, Press & Teukolsky 1972, Eq. (2.15) at `r = 6`, `a = 0`.
#[test]
fn isco_angular_momentum_schwarzschild() {
    let expected = 6.0 * 2.0_f64.sqrt();
    assert!((phys::isco_specific_angular_momentum(0.0) - expected).abs() < TOL);
    assert!((phys::specific_angular_momentum(6.0, 0.0) - expected).abs() < TOL);
}

/// Prograde accretion spins the hole up when `l_isco > 2 a`.
#[test]
fn advance_spin_increases_from_zero() {
    const M0: f64 = 10.0;
    let mdot = phys::mdot_from_luminosity(phys::l_eddington(M0), EFFICIENCY);
    let dt = phys::salpeter_time_s(EFFICIENCY);
    let a1 = phys::advance_spin(0.0, M0, mdot, EFFICIENCY, dt);
    assert!(a1 > 0.0);
    assert!(a1 <= phys::THORNE_SPIN_LIMIT);
}

/// Eddington feed rate reproduces `lambda = 1`.
#[test]
fn mdot_at_eddington_is_unit_lambda() {
    const M: f64 = 42.0;
    let mdot = phys::mdot_at_eddington(M, EFFICIENCY);
    assert!((phys::eddington_ratio(M, mdot, EFFICIENCY) - 1.0).abs() < RTOL);
}
