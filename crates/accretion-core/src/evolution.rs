//! Time evolution of black-hole state under accretion.
//!
//! Mass grows by the rest-mass fraction `(1 - eta)` of the feed rate; spin evolves
//! from the specific angular momentum of gas arriving at the ISCO. The integrity
//! driver `1 - lambda` encodes radiation-pressure support (presentation scales it
//! into a gameplay meter).
//!
//! # References
//! - Frank, King & Raine 2002, Ch. 1 (mass growth).
//! - Salpeter 1964, ApJ 140, 796 (Eddington e-folding time).
//! - Eddington 1926 (radiation-pressure support).
//! - King & Raine 2002, Ch. 5 (Kerr spin-up).
//! - Bardeen 1970.

use crate::constants::M_SUN;
use crate::constants::{C_LIGHT, G, M_P};
use crate::derived::SIGMA_T;
use crate::kerr::{THORNE_SPIN_LIMIT, isco_specific_angular_momentum};

/// Advance black-hole mass \[M_sun\] by `dt_s` \[s\] at feed `mdot_gs` \[g/s\].
///
/// `dM/dt = (1 - eta) Mdot`; the radiated fraction `eta` does not add to the hole.
pub fn advance_mass(m_bh_msun: f64, mdot_gs: f64, eta: f64, dt_s: f64) -> f64 {
    let m_g = m_bh_msun * M_SUN + (1.0 - eta) * mdot_gs * dt_s;
    m_g / M_SUN
}

/// Salpeter (Eddington) e-folding time \[s\]: mass grows by a factor `e` when
/// accreting at the Eddington limit with efficiency `eta`.
///
/// `t_S = (eta/(1-eta)) sigma_T c / (4 pi G m_p)`. Mass-independent.
pub fn salpeter_time_s(eta: f64) -> f64 {
    (eta / (1.0 - eta)) * SIGMA_T * C_LIGHT / (4.0 * std::f64::consts::PI * G * M_P)
}

/// Net disk-support fraction `1 - lambda` (dimensionless).
///
/// Positive when sub-Eddington (disk bound); negative when super-Eddington.
pub fn integrity_rate(eddington_ratio: f64) -> f64 {
    1.0 - eddington_ratio
}

/// Advance Kerr spin parameter after accreting for `dt_s` \[s\].
///
/// `da/dt = (1 - eta) Mdot (l_isco - 2a) / M^2` in geometric units (King & Raine 2002).
pub fn advance_spin(spin: f64, m_bh_msun: f64, mdot_gs: f64, eta: f64, dt_s: f64) -> f64 {
    if m_bh_msun <= 0.0 || dt_s <= 0.0 || mdot_gs <= 0.0 {
        return spin;
    }
    let l = isco_specific_angular_momentum(spin);
    let dm = (1.0 - eta) * mdot_gs * dt_s;
    let da = dm * (l - 2.0 * spin) / (m_bh_msun * M_SUN);
    (spin + da).clamp(0.0, THORNE_SPIN_LIMIT)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::eddington::{l_eddington, mdot_from_luminosity};

    const ETA: f64 = 0.1;
    const TOL: f64 = 0.000000001;
    const RTOL: f64 = 0.000000001;

    #[test]
    fn advance_mass_retains_one_minus_eta() {
        const M0: f64 = 10.0;
        let mdot = mdot_from_luminosity(l_eddington(M0), ETA);
        let dt = salpeter_time_s(ETA);
        let m1 = advance_mass(M0, mdot, ETA, dt);
        let gained_g = (m1 - M0) * crate::constants::M_SUN;
        let expected_g = (1.0 - ETA) * mdot * dt;
        assert!((gained_g - expected_g).abs() <= RTOL * expected_g.abs());
    }

    #[test]
    fn advance_mass_zero_feed_is_static() {
        assert!((advance_mass(4_000_000.0, 0.0, ETA, 1000.0) - 4_000_000.0).abs() < TOL);
    }

    #[test]
    fn salpeter_time_is_mass_independent() {
        const M1: f64 = 10.0;
        const M2: f64 = 1_000_000_000.0;
        let t = salpeter_time_s(ETA);
        for m in [M1, M2] {
            let mdot = mdot_from_luminosity(l_eddington(m), ETA);
            let growth = (1.0 - ETA) * mdot;
            let efold = (m * crate::constants::M_SUN) / growth;
            assert!((efold - t).abs() <= RTOL * t);
        }
    }

    #[test]
    fn integrity_rate_signs() {
        assert!((integrity_rate(0.0) - 1.0).abs() < TOL);
        assert!(integrity_rate(1.0).abs() < TOL);
        assert!(integrity_rate(2.0) < 0.0);
    }

    #[test]
    fn advance_spin_increases_from_zero() {
        const M0: f64 = 10.0;
        let mdot = mdot_from_luminosity(l_eddington(M0), ETA);
        let dt = salpeter_time_s(ETA);
        let a1 = advance_spin(0.0, M0, mdot, ETA, dt);
        assert!(a1 > 0.0);
        assert!(a1 <= THORNE_SPIN_LIMIT);
    }

    #[test]
    fn advance_spin_never_exceeds_thorne_limit() {
        let mdot = mdot_from_luminosity(l_eddington(10.0), ETA);
        let a = advance_spin(0.0, 10.0, mdot, ETA, salpeter_time_s(ETA) * 1000.0);
        assert!(a <= THORNE_SPIN_LIMIT);
        assert!(a > 0.9);
    }
}
