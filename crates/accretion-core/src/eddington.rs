//! Eddington-limited accretion: luminosity, accretion rate, and the dimensionless
//! Eddington ratio `lambda = L / L_Edd`.
//!
//! The Eddington limit is the luminosity at which electron-scattering radiation
//! pressure balances gravity on a fully ionized hydrogen atmosphere:
//! `L_Edd = 4 pi G M m_p c / sigma_T`.
//!
//! # References
//! - Eddington, A. S. 1926, *The Internal Constitution of the Stars*.
//! - Frank, King & Raine 2002, *Accretion Power in Astrophysics*, Eq. (1.5).
//! - Novikov & Thorne 1973, thin-disk radiative efficiency.

use crate::constants::{C_LIGHT, G, M_P, M_SUN};
use crate::derived::SIGMA_T;

/// Eddington luminosity `L_Edd` \[erg/s\] for a black hole of mass `m_bh_msun` \[M_sun\].
///
/// Scales linearly with mass: doubling `M` doubles `L_Edd`.
pub fn l_eddington(m_bh_msun: f64) -> f64 {
    let m_g = m_bh_msun * M_SUN;
    4.0 * std::f64::consts::PI * G * m_g * M_P * C_LIGHT / SIGMA_T
}

/// Bolometric luminosity \[erg/s\] from accretion rate `mdot_gs` \[g/s\] at
/// radiative efficiency `eta`: `L = eta Mdot c^2`.
pub fn luminosity_from_mdot(mdot_gs: f64, eta: f64) -> f64 {
    eta * mdot_gs * C_LIGHT * C_LIGHT
}

/// Eddington ratio `lambda = L / L_Edd` (dimensionless).
pub fn eddington_ratio(m_bh_msun: f64, mdot_gs: f64, eta: f64) -> f64 {
    luminosity_from_mdot(mdot_gs, eta) / l_eddington(m_bh_msun)
}

/// Accretion rate \[g/s\] from bolometric luminosity \[erg/s\] at efficiency `eta`.
pub fn mdot_from_luminosity(l: f64, eta: f64) -> f64 {
    l / (eta * C_LIGHT * C_LIGHT)
}

/// Accretion rate \[g/s\] that yields `lambda = 1` at mass `m_bh_msun` and `eta`.
pub fn mdot_at_eddington(m_bh_msun: f64, eta: f64) -> f64 {
    mdot_from_luminosity(l_eddington(m_bh_msun), eta)
}

#[cfg(test)]
mod tests {
    use super::*;

    const ETA: f64 = 0.1;
    const TOL: f64 = 0.000000001;
    const RTOL: f64 = 0.000001;

    #[test]
    fn luminosity_mdot_round_trip() {
        let l = l_eddington(100.0);
        let mdot = mdot_from_luminosity(l, ETA);
        let l2 = luminosity_from_mdot(mdot, ETA);
        assert!((l2 - l).abs() <= RTOL * l.abs());
    }

    #[test]
    fn mdot_at_eddington_gives_unit_lambda() {
        const M: f64 = 42.0;
        let mdot = mdot_at_eddington(M, ETA);
        assert!((eddington_ratio(M, mdot, ETA) - 1.0).abs() < RTOL);
    }

    #[test]
    fn l_eddington_scales_linearly_with_mass() {
        let l1 = l_eddington(10.0);
        let l2 = l_eddington(20.0);
        assert!((l2 / l1 - 2.0).abs() < TOL);
    }

    #[test]
    fn lambda_scales_linearly_with_mdot_at_fixed_mass() {
        const M: f64 = 10.0;
        let mdot = mdot_at_eddington(M, ETA);
        let lam_half = eddington_ratio(M, mdot * 0.5, ETA);
        assert!((lam_half - 0.5).abs() < RTOL);
    }
}
