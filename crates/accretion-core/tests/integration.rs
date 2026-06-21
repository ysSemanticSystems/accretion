//! Cross-module integration checks (Eddington + Kerr + disk + evolution).

mod common;

use accretion_core as phys;

use common::{ETA, RTOL, TOL, assert_abs_eq, assert_relative_eq};

#[test]
fn eddington_luminosity_mass_scaling() {
    let l1 = phys::l_eddington(10.0);
    let l2 = phys::l_eddington(20.0);
    assert_abs_eq(l2 / l1, 2.0, TOL);
}

#[test]
fn mdot_luminosity_round_trip_at_eddington() {
    let l = phys::l_eddington(100_000_000.0);
    let mdot = phys::mdot_from_luminosity(l, ETA);
    assert_relative_eq(phys::luminosity_from_mdot(mdot, ETA), l, RTOL);
}

#[test]
fn schwarzschild_isco_chain() {
    const M: f64 = 12.3;
    let r_g = phys::gravitational_radius_cm(M);
    assert_abs_eq(phys::r_isco(M, 0.0) / r_g, 6.0, TOL);
    assert_abs_eq(phys::isco_radius(0.0), 6.0, TOL);
    assert_abs_eq(phys::r_s(M) / r_g, 2.0, TOL);
}

#[test]
fn disk_temperature_ss73_scaling() {
    const M: f64 = 10.0;
    let mdot = phys::mdot_from_luminosity(phys::l_eddington(M), ETA);
    let r_in = 10.0 * phys::r_s(M);
    let r_out = 20.0 * phys::r_s(M);
    let ratio = phys::disk_temperature(r_out, M, mdot) / phys::disk_temperature(r_in, M, mdot);
    assert_abs_eq(ratio, 2.0_f64.powf(-0.75), TOL);
}

#[test]
fn salpeter_time_matches_mass_efolding_at_eddington() {
    const M: f64 = 100_000_000.0;
    let mdot_edd = phys::mdot_from_luminosity(phys::l_eddington(M), ETA);
    let growth_rate_gs = (1.0 - ETA) * mdot_edd;
    let efold_s = (M * phys::constants::M_SUN) / growth_rate_gs;
    assert_relative_eq(phys::salpeter_time_s(ETA), efold_s, RTOL);
}

#[test]
fn spin_up_and_efficiency_coupling() {
    const M0: f64 = 10.0;
    let mdot = phys::mdot_from_luminosity(phys::l_eddington(M0), ETA);
    let dt = phys::salpeter_time_s(ETA);
    let spin = phys::advance_spin(0.0, M0, mdot, ETA, dt);
    let eta = phys::efficiency_from_spin(spin);
    assert!(spin > 0.0);
    assert!(eta > phys::efficiency_from_spin(0.0));
}

#[test]
fn blackbody_colour_ordering() {
    let (hr, _hg, hb) = phys::blackbody_rgb(20_000.0);
    let (cr, _cg, cb) = phys::blackbody_rgb(3_000.0);
    assert!(hb >= hr);
    assert!(cr > cb);
}

#[test]
fn derived_sigma_sb_matches_stefan_boltzmann_formula() {
    use phys::constants::{C_LIGHT, H_PLANCK, K_BOLTZMANN};
    const PI: f64 = std::f64::consts::PI;
    let expected =
        2.0 * PI.powi(5) * K_BOLTZMANN.powi(4) / (15.0 * C_LIGHT.powi(2) * H_PLANCK.powi(3));
    assert_relative_eq(phys::SIGMA_SB, expected, 0.000000000001);
}
