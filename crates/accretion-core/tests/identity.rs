//! Analytic physics identities (no oracle required).

use accretion_core as phys;

const EFFICIENCY: f64 = 0.1;
const M_MSUN: f64 = 10.0;
const R_IN_R_S: f64 = 10.0;
const R_OUT_R_S: f64 = 20.0;
const TOL: f64 = 0.000000001;
const RTOL: f64 = 0.000001;

/// Shakura-Sunyaev scaling: `T(2r) / T(r) = 2^(-3/4)`.
///
/// Reference: Shakura & Sunyaev 1973, A&A 24, 337.
#[test]
fn disk_temperature_scaling_law() {
    let mdot = phys::mdot_from_luminosity(phys::l_eddington(M_MSUN), EFFICIENCY);
    let r_in = R_IN_R_S * phys::r_s(M_MSUN);
    let r_out = R_OUT_R_S * phys::r_s(M_MSUN);
    let ratio =
        phys::disk_temperature(r_out, M_MSUN, mdot) / phys::disk_temperature(r_in, M_MSUN, mdot);
    assert!((ratio - 2.0_f64.powf(-0.75)).abs() < TOL);
}

/// Schwarzschild ISCO: `r_isco / R_g == 6`.
///
/// Reference: Bardeen, Press & Teukolsky 1972, ApJ 178, 347.
#[test]
fn isco_schwarzschild_ratio_is_six() {
    const M: f64 = 12.3;
    let r_g = phys::gravitational_radius_cm(M);
    assert!((phys::r_isco(M, 0.0) / r_g - 6.0).abs() < TOL);
    assert!((phys::isco_radius(0.0) - 6.0).abs() < TOL);
}

#[test]
fn mdot_luminosity_round_trip() {
    const M: f64 = 100_000_000.0;
    let l = phys::l_eddington(M);
    let mdot = phys::mdot_from_luminosity(l, EFFICIENCY);
    assert!((phys::luminosity_from_mdot(mdot, EFFICIENCY) - l).abs() < RTOL * l.abs());
}

#[test]
fn blackbody_color_temperature_ordering() {
    let (hr, _hg, hb) = phys::blackbody_rgb(20_000.0);
    let (cr, _cg, cb) = phys::blackbody_rgb(3_000.0);
    assert!(hb >= hr);
    assert!(cr > cb);
}
