//! Shakura–Sunyaev thin accretion-disk observables.
//!
//! This module implements the **bare** SS73 temperature profile (no inner-boundary
//! correction). The omitted factor `(1 - sqrt(r_in/r))^(1/4)` means the profile
//! is monotonic with no temperature peak at the inner edge; that correction is
//! a documented fast-follow.
//!
//! # Reference
//! Shakura & Sunyaev 1973, A&A 24, 337.

use crate::constants::{G, M_SUN};
use crate::derived::SIGMA_SB;

/// Disk temperature \[K\] at radius `r_cm` \[cm\].
///
/// Bare form: `T = (3 G M Mdot / (8 pi sigma_sb r^3))^(1/4)`.
pub fn disk_temperature(r_cm: f64, m_bh_msun: f64, mdot_gs: f64) -> f64 {
    let m_g = m_bh_msun * M_SUN;
    let t4 = 3.0 * G * m_g * mdot_gs / (8.0 * std::f64::consts::PI * SIGMA_SB * r_cm * r_cm * r_cm);
    t4.powf(0.25)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::eddington::{l_eddington, mdot_from_luminosity};
    use crate::kerr::r_s;

    const ETA: f64 = 0.1;
    const M: f64 = 10.0;
    const TOL: f64 = 0.000000001;

    fn mdot_edd() -> f64 {
        mdot_from_luminosity(l_eddington(M), ETA)
    }

    #[test]
    fn scaling_law_t2r_over_tr() {
        let mdot = mdot_edd();
        let r_in = 10.0 * r_s(M);
        let r_out = 20.0 * r_s(M);
        let ratio = disk_temperature(r_out, M, mdot) / disk_temperature(r_in, M, mdot);
        assert!((ratio - 2.0_f64.powf(-0.75)).abs() < TOL);
    }

    #[test]
    fn temperature_scales_as_mdot_one_quarter() {
        let r = 10.0 * r_s(M);
        let t1 = disk_temperature(r, M, mdot_edd());
        let t2 = disk_temperature(r, M, mdot_edd() * 16.0);
        assert!((t2 / t1 - 2.0).abs() < TOL);
    }

    #[test]
    fn temperature_scales_as_mass_one_quarter() {
        let mdot = mdot_edd();
        let r = 10.0 * r_s(M);
        let t1 = disk_temperature(r, M, mdot);
        let t2 = disk_temperature(r, 16.0 * M, mdot);
        assert!((t2 / t1 - 2.0).abs() < TOL);
    }
}
