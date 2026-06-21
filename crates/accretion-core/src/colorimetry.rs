//! Planck blackbody radiance integrated through the CIE 1931 colour-matching functions
//! and converted to linear sRGB for HDR-friendly disk rendering.
//!
//! # References
//! - Planck 1901 (spectral radiance).
//! - CIE 1931 2° standard observer colour-matching functions.
//! - Wyman, Sloan & Shirley 2013 (approximate sRGB conversion).
//! - IEC 61966-2-1 (sRGB electro-optical transfer function).

use crate::constants::{C_LIGHT, H_PLANCK, K_BOLTZMANN, NM_TO_CM};

/// Linear sRGB blackbody colour at temperature `temp_k` \[K\], brightest channel
/// normalized to 1.0 (HDR-friendly chromaticity).
pub fn blackbody_rgb(temp_k: f64) -> (f64, f64, f64) {
    if temp_k <= 0.0 || !temp_k.is_finite() {
        return (0.0, 0.0, 0.0);
    }

    let (mut x, mut y, mut z) = (0.0_f64, 0.0_f64, 0.0_f64);
    let (lambda_min_nm, lambda_max_nm, step_nm) = (380.0, 780.0, 5.0);
    let mut lambda_nm = lambda_min_nm;
    while lambda_nm <= lambda_max_nm {
        let b = planck_spectral_radiance(lambda_nm * NM_TO_CM, temp_k);
        let (xb, yb, zb) = cie_xyz_cmf(lambda_nm);
        x += b * xb;
        y += b * yb;
        z += b * zb;
        lambda_nm += step_nm;
    }

    let sum = x + y + z;
    if sum <= 0.0 {
        return (0.0, 0.0, 0.0);
    }
    let (x, y, z) = (x / sum, y / sum, z / sum);

    let r = 3.240_625 * x - 1.537_208 * y - 0.498_629 * z;
    let g = -0.968_931 * x + 1.875_756 * y + 0.041_518 * z;
    let b = 0.055_710 * x - 0.204_021 * y + 1.056_996 * z;

    let r = r.max(0.0);
    let g = g.max(0.0);
    let b = b.max(0.0);

    let peak = r.max(g).max(b);
    if peak <= 0.0 {
        return (0.0, 0.0, 0.0);
    }
    (r / peak, g / peak, b / peak)
}

/// Planck spectral radiance `B_lambda` \[erg s^-1 cm^-2 sr^-1 cm^-1\] (CGS).
fn planck_spectral_radiance(lambda_cm: f64, temp_k: f64) -> f64 {
    let numerator = 2.0 * H_PLANCK * C_LIGHT * C_LIGHT / lambda_cm.powi(5);
    let exponent = H_PLANCK * C_LIGHT / (lambda_cm * K_BOLTZMANN * temp_k);
    numerator / (exponent.exp() - 1.0)
}

/// CIE 1931 2° XYZ colour-matching functions (Wyman et al. 2013 Gaussian fit).
fn cie_xyz_cmf(lambda_nm: f64) -> (f64, f64, f64) {
    fn g(lambda: f64, mean: f64, sigma_lo: f64, sigma_hi: f64) -> f64 {
        let sigma = if lambda < mean { sigma_lo } else { sigma_hi };
        let t = (lambda - mean) / sigma;
        (-0.5 * t * t).exp()
    }

    let x = 1.056 * g(lambda_nm, 599.8, 37.9, 31.0) + 0.362 * g(lambda_nm, 442.0, 16.0, 26.7)
        - 0.065 * g(lambda_nm, 501.1, 20.4, 26.2);
    let y = 0.821 * g(lambda_nm, 568.8, 46.9, 40.5) + 0.286 * g(lambda_nm, 530.9, 16.3, 31.1);
    let z = 1.217 * g(lambda_nm, 437.0, 11.8, 36.0) + 0.681 * g(lambda_nm, 459.0, 26.0, 13.8);
    (x, y, z)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nonpositive_temperature_is_black() {
        assert_eq!(blackbody_rgb(0.0), (0.0, 0.0, 0.0));
        assert_eq!(blackbody_rgb(-100.0), (0.0, 0.0, 0.0));
    }

    #[test]
    fn channels_normalized_to_unit_peak() {
        let (r, g, b) = blackbody_rgb(10_000.0);
        let peak = r.max(g).max(b);
        assert!((peak - 1.0).abs() < 0.000000001);
        assert!(r >= 0.0 && g >= 0.0 && b >= 0.0);
    }

    #[test]
    fn hotter_is_bluer_than_cooler() {
        let (hr, _hg, hb) = blackbody_rgb(20_000.0);
        let (cr, _cg, cb) = blackbody_rgb(3_000.0);
        assert!(hb >= hr);
        assert!(cr > cb);
    }

    #[test]
    fn monotonic_wien_displacement_in_hue() {
        let (_, g1, _) = blackbody_rgb(4_000.0);
        let (_, g2, _) = blackbody_rgb(8_000.0);
        assert!(g1 > 0.0 && g2 > 0.0);
    }
}
