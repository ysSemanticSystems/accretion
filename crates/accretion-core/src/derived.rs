//! Composite physical constants, computed from the fundamentals in
//! [`crate::constants`].
//!
//! These are exact mathematical relations among fundamental constants, not
//! independent measurements. Deriving them here (rather than tabulating a second
//! copy) keeps a single source of truth and makes the relation auditable. Each
//! value carries its formula and a primary-source citation, and is pinned by a
//! golden test against the astropy oracle (`scripts/gen_golden.py`).
//!
//! Const evaluation note: `f64::powi`/`powf` are not `const fn` on stable Rust,
//! so integer powers are written as explicit products.

use crate::constants::{ALPHA, C_LIGHT, H_PLANCK, K_BOLTZMANN, M_E};

const PI: f64 = std::f64::consts::PI;

/// Reduced Planck constant `hbar = h / (2 pi)` \[erg s\].
pub const H_BAR: f64 = H_PLANCK / (2.0 * PI);

/// Stefan-Boltzmann constant `sigma = 2 pi^5 k_B^4 / (15 c^2 h^3)`
/// \[erg cm^-2 s^-1 K^-4\].
///
/// Exact under the 2019 SI redefinition, in which `k_B`, `h`, and `c` are fixed
/// exactly; the value is then a pure mathematical constant.
///
/// # Reference
/// Stefan 1879; Boltzmann 1884; derivation via the Bose-Einstein integral
/// `Gamma(4) zeta(4) = pi^4 / 15` (e.g. Rybicki & Lightman 1979, Eq. 1.43).
pub const SIGMA_SB: f64 =
    2.0 * (PI * PI * PI * PI * PI) * (K_BOLTZMANN * K_BOLTZMANN * K_BOLTZMANN * K_BOLTZMANN)
        / (15.0 * (C_LIGHT * C_LIGHT) * (H_PLANCK * H_PLANCK * H_PLANCK));

/// Reduced Compton wavelength of the electron `lambdabar_C = hbar / (m_e c)` \[cm\].
const COMPTON_REDUCED_E: f64 = H_BAR / (M_E * C_LIGHT);

/// Thomson cross-section `sigma_T = (8 pi / 3) (alpha hbar / (m_e c))^2` \[cm^2\].
///
/// Equivalent to `(8 pi / 3) r_e^2` with the classical electron radius
/// `r_e = alpha * hbar / (m_e c)`. Expressed through the (dimensionless)
/// fine-structure constant `alpha` to avoid the esu/emu ambiguity of the
/// elementary charge in CGS.
///
/// # Reference
/// Thomson 1906; Jackson 1998, Classical Electrodynamics, Eq. (14.117);
/// CODATA 2018.
pub const SIGMA_T: f64 =
    (8.0 * PI / 3.0) * (ALPHA * ALPHA) * (COMPTON_REDUCED_E * COMPTON_REDUCED_E);

#[cfg(test)]
mod tests {
    use super::*;
    use crate::constants::{ALPHA, C_LIGHT, H_PLANCK, K_BOLTZMANN, M_E};

    const RTOL: f64 = 0.000000001;

    #[test]
    fn sigma_sb_matches_closed_form() {
        let expected =
            2.0 * PI.powi(5) * K_BOLTZMANN.powi(4) / (15.0 * C_LIGHT.powi(2) * H_PLANCK.powi(3));
        assert!((SIGMA_SB - expected).abs() <= RTOL * expected.abs());
    }

    #[test]
    fn sigma_t_matches_thomson_formula() {
        let compton = H_BAR / (M_E * C_LIGHT);
        let expected = (8.0 * PI / 3.0) * (ALPHA * ALPHA) * (compton * compton);
        assert!((SIGMA_T - expected).abs() <= RTOL * expected.abs());
    }
}
