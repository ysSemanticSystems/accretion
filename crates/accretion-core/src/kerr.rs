//! Kerr geometry: gravitational radii, ISCO, binding energy, angular momentum,
//! and orbital frequency.
//!
//! All radii in this module are expressed either in centimetres or in multiples
//! of the gravitational radius `R_g = GM/c^2`. The dimensionless spin parameter
//! `a` (denoted `spin` in the API) is the Kerr parameter `a/M` in geometric units.
//!
//! # References
//! - Bardeen, Press & Teukolsky 1972, ApJ 178, 347 (Eqs. 2.12–2.21).
//! - Novikov & Thorne 1973 (thin-disk radiative efficiency).
//! - Thorne 1974, ApJ 191, 507 (maximum prograde spin from thin-disk accretion).

use crate::constants::{C_LIGHT, G, M_SUN};

/// Thorne (1974) maximum prograde spin of a thin disk (`a/M ~= 0.998`).
pub const THORNE_SPIN_LIMIT: f64 = 0.998;

/// Gravitational radius `R_g = GM/c^2` \[cm\].
pub fn gravitational_radius_cm(m_bh_msun: f64) -> f64 {
    G * (m_bh_msun * M_SUN) / (C_LIGHT * C_LIGHT)
}

/// Schwarzschild radius `r_s = 2 GM/c^2 = 2 R_g` \[cm\].
pub fn r_s(m_bh_msun: f64) -> f64 {
    2.0 * gravitational_radius_cm(m_bh_msun)
}

/// ISCO radius in units of `R_g = GM/c^2` (dimensionless spin parameter `a`).
///
/// Prograde ISCO from the Bardeen–Press–Teukolsky (1972) Eq. (2.21) closed form.
/// Schwarzschild limit: `r_isco = 6 R_g` at `a = 0`.
pub fn isco_radius(spin: f64) -> f64 {
    let a = spin;
    let z1 = 1.0 + (1.0 - a * a).cbrt() * ((1.0 + a).cbrt() + (1.0 - a).cbrt());
    let z2 = (3.0 * a * a + z1 * z1).sqrt();
    3.0 + z2 - ((3.0 - z1) * (3.0 + z1 + 2.0 * z2)).sqrt()
}

/// ISCO radius \[cm\] for mass `m_bh_msun` and spin `spin`.
pub fn r_isco(m_bh_msun: f64, spin: f64) -> f64 {
    isco_radius(spin) * gravitational_radius_cm(m_bh_msun)
}

/// Specific energy `E/(mu c^2)` (dimensionless) of the prograde ISCO circular orbit.
///
/// BPT (1972) Eq. (2.12)–(2.13) evaluated at `r = r_isco(a)`.
pub fn isco_specific_energy(spin: f64) -> f64 {
    let a = spin;
    let r = isco_radius(spin);
    let sqrt_r = r.sqrt();
    let r32 = r * sqrt_r;
    let r34 = r32.sqrt();
    let numerator = r32 - 2.0 * sqrt_r + a;
    let denominator = r34 * (r32 - 3.0 * sqrt_r + 2.0 * a).sqrt();
    numerator / denominator
}

/// Radiative efficiency `eta = 1 - E_isco` of a thin disk around a Kerr hole.
///
/// Schwarzschild value: `eta = 1 - sqrt(8/9) ~= 0.0572`.
pub fn efficiency_from_spin(spin: f64) -> f64 {
    1.0 - isco_specific_energy(spin)
}

/// Dimensionless specific angular momentum of a prograde circular orbit at
/// `r_over_rg` (in `R_g`) around a Kerr hole of spin `spin`.
///
/// BPT (1972) Eq. (2.15):
/// `l = (r^2 - 2 a r^(1/2) + a^2) / (r^(1/2) (r - 3 + 2 a r^(-1/2))^(1/2))`.
pub fn specific_angular_momentum(r_over_rg: f64, spin: f64) -> f64 {
    let a = spin;
    let r = r_over_rg;
    let sqrt_r = r.sqrt();
    let numerator = r * r - 2.0 * a * sqrt_r + a * a;
    let denominator = sqrt_r * (r - 3.0 + 2.0 * a / sqrt_r).sqrt();
    numerator / denominator
}

/// ISCO specific angular momentum `l_isco(a)`.
pub fn isco_specific_angular_momentum(spin: f64) -> f64 {
    specific_angular_momentum(isco_radius(spin), spin)
}

/// Coordinate orbital frequency \[Hz\] at radius `r_over_rg` (in `R_g`).
///
/// BPT (1972) Eq. (2.16): `Omega = c^3/(G M) * 1/(r^(3/2) + a)`; `f = Omega/(2 pi)`.
/// Scales as `1/M` at fixed `r/R_g`.
pub fn orbital_frequency_hz(m_bh_msun: f64, r_over_rg: f64, spin: f64) -> f64 {
    let omega = C_LIGHT.powi(3) / (G * m_bh_msun * M_SUN) / (r_over_rg.powf(1.5) + spin);
    omega / (2.0 * std::f64::consts::PI)
}

#[cfg(test)]
mod tests {
    use super::*;

    const TOL: f64 = 0.000000001;
    const RTOL: f64 = 0.000001;

    #[test]
    fn schwarzschild_radii_relation() {
        const M: f64 = 12.3;
        let r_g = gravitational_radius_cm(M);
        assert!((r_s(M) / r_g - 2.0).abs() < TOL);
    }

    #[test]
    fn isco_schwarzschild_is_six_rg() {
        assert!((isco_radius(0.0) - 6.0).abs() < TOL);
        const M: f64 = 12.3;
        let r_g = gravitational_radius_cm(M);
        assert!((r_isco(M, 0.0) / r_g - 6.0).abs() < TOL);
    }

    #[test]
    fn efficiency_schwarzschild_analytic() {
        let expected = 1.0 - (8.0_f64 / 9.0).sqrt();
        assert!((efficiency_from_spin(0.0) - expected).abs() < TOL);
    }

    #[test]
    fn isco_shrinks_with_prograde_spin() {
        assert!(isco_radius(0.9) < isco_radius(0.0));
        assert!(isco_radius(0.998) < isco_radius(0.9));
    }

    #[test]
    fn efficiency_increases_with_spin() {
        let eta0 = efficiency_from_spin(0.0);
        let eta_mid = efficiency_from_spin(0.9);
        let eta_thorne = efficiency_from_spin(THORNE_SPIN_LIMIT);
        assert!(eta0 < eta_mid);
        assert!(eta_mid < eta_thorne);
        assert!(eta_thorne > 0.30 && eta_thorne < 0.33);
    }

    #[test]
    fn isco_angular_momentum_schwarzschild() {
        let expected = 6.0 * 2.0_f64.sqrt();
        assert!((isco_specific_angular_momentum(0.0) - expected).abs() < TOL);
    }

    #[test]
    fn orbital_frequency_scales_inversely_with_mass() {
        const M: f64 = 10.0;
        let f1 = orbital_frequency_hz(M, 6.0, 0.0);
        let f2 = orbital_frequency_hz(2.0 * M, 6.0, 0.0);
        assert!(f1 > 0.0);
        assert!((f2 - f1 / 2.0).abs() <= RTOL * (f1 / 2.0));
    }
}
