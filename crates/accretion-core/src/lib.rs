//! # accretion-core
//!
//! Pure-Rust accretion-disk physics for the `accretion` game. This crate has
//! **zero** Godot dependency and is `cargo test`-able in isolation. It is
//! `BlackHoleResearch/blackhole/physics/accretion.py` relocated to Rust: every
//! constant and formula cites its primary source in its doc comment, exactly as
//! the Python docstrings do.
//!
//! Presentation boundary: this crate produces numbers. It never touches a scene
//! tree. The `godot-ext` crate binds these numbers to Godot.
//!
//! ## Units
//!
//! **CGS internally and at the public API** (g, cm, s, erg, K), matching the
//! astrophysics literature and the ported source: luminosities in erg/s,
//! accretion rates in g/s, radii in cm. There is no `astropy.units` equivalent
//! in Rust, so unit safety (rule 02) is enforced by convention: units are in
//! the function names/docs, and conversions are explicit.

/// Newtonian gravitational constant `G` \[cm^3 g^-1 s^-2\]. CODATA 2018.
pub const G: f64 = 6.674_30e-8;
/// Speed of light in vacuum `c` \[cm s^-1\]. Exact (SI definition).
pub const C: f64 = 2.997_924_58e10;
/// Proton mass `m_p` \[g\]. CODATA 2018.
pub const M_PROTON: f64 = 1.672_621_923_69e-24;
/// Thomson scattering cross-section `sigma_T` \[cm^2\]. CODATA 2018.
pub const SIGMA_THOMSON: f64 = 6.652_458_732_1e-25;
/// Stefan-Boltzmann constant `sigma_sb` \[erg cm^-2 s^-1 K^-4\]. CODATA 2018.
pub const SIGMA_SB: f64 = 5.670_374_419e-5;
/// Planck constant `h` \[erg s\]. Exact (SI definition).
pub const H_PLANCK: f64 = 6.626_070_15e-27;
/// Boltzmann constant `k_B` \[erg K^-1\]. Exact (SI definition).
pub const K_BOLTZMANN: f64 = 1.380_649e-16;
/// Nominal solar mass `M_sun` \[g\]. IAU 2015 B3 nominal value.
pub const M_SUN: f64 = 1.988_92e33;

/// Eddington luminosity `L_Edd` \[erg/s\] for a black hole of mass `m_bh_msun`
/// (in solar masses).
///
/// `L_Edd = 4 pi G M m_p c / sigma_T`, the maximum steady-state luminosity at
/// which radiation pressure on free electrons balances gravity on protons for
/// fully ionized hydrogen. Numerically `~1.26e38 (M/M_sun) erg/s`.
///
/// In the game this sets the fail ceiling: drive the accretion rate past
/// `L_Edd / (eta c^2)` and radiation pressure blows the disk apart.
///
/// # Reference
/// Eddington 1926, *The Internal Constitution of the Stars*. Coefficient e.g.
/// Frank, King & Raine 2002, *Accretion Power in Astrophysics*, 3rd ed., Eq. (1.5).
pub fn l_eddington(m_bh_msun: f64) -> f64 {
    let m_g = m_bh_msun * M_SUN;
    4.0 * std::f64::consts::PI * G * m_g * M_PROTON * C / SIGMA_THOMSON
}

/// Accretion rate `Mdot` \[g/s\] from bolometric luminosity `l` \[erg/s\],
/// assuming radiative efficiency `eta`.
///
/// `L = eta Mdot c^2  =>  Mdot = L / (eta c^2)`. The standard thin-disk value
/// is `eta ~ 0.1` (Schwarzschild `~0.057`, maximal Kerr `~0.42`).
///
/// # Reference
/// Standard accretion relation; relativistic thin-disk efficiency from
/// Novikov & Thorne 1973, in *Black Holes (Les Astres Occlus)*, eds. DeWitt.
pub fn mdot_from_luminosity(l: f64, eta: f64) -> f64 {
    l / (eta * C * C)
}

/// Shakura-Sunyaev disk effective temperature `T` \[K\] at radius `r_cm` \[cm\]
/// for a black hole of mass `m_bh_msun` accreting at `mdot_gs` \[g/s\].
///
/// `T = (3 G M Mdot / (8 pi sigma_sb r^3))^(1/4)`
///
/// This is the exact bare form from the reference source. It omits the inner-
/// boundary (zero-torque) factor `(1 - sqrt(r_in/r))^(1/4)`, so it is monotonic
/// `T ∝ r^(-3/4)` with **no temperature peak** and **no dark inner gap**. That
/// is correct as ported; the inner-boundary correction (which produces the
/// iconic bright ring and dark gap) is the first fast-follow. See rule 02.
///
/// # Reference
/// Shakura & Sunyaev 1973, A&A 24, 337 (the alpha-disk framework).
pub fn disk_temperature(r_cm: f64, m_bh_msun: f64, mdot_gs: f64) -> f64 {
    let m_g = m_bh_msun * M_SUN;
    let t4 = 3.0 * G * m_g * mdot_gs / (8.0 * std::f64::consts::PI * SIGMA_SB * r_cm * r_cm * r_cm);
    t4.powf(0.25)
}

/// Gravitational radius `R_g = GM/c^2` \[cm\] for a black hole of mass
/// `m_bh_msun` (in solar masses). The natural length scale of the spacetime;
/// ISCO and disk radii are conventionally quoted in multiples of `R_g`.
///
/// # Reference
/// Definitional (e.g. Misner, Thorne & Wheeler 1973, *Gravitation*).
pub fn gravitational_radius_cm(m_bh_msun: f64) -> f64 {
    G * (m_bh_msun * M_SUN) / (C * C)
}

/// Radius of the innermost stable circular orbit (ISCO) for a Kerr black hole
/// of dimensionless spin `spin` (a/M in [-1, 1]), in units of the gravitational
/// radius `R_g = GM/c^2`. Positive `spin` is prograde.
///
/// `Z1 = 1 + (1 - a^2)^(1/3) [ (1 + a)^(1/3) + (1 - a)^(1/3) ]`
/// `Z2 = sqrt(3 a^2 + Z1^2)`
/// `r_isco / M = 3 + Z2 - sqrt[ (3 - Z1)(3 + Z1 + 2 Z2) ]`  (prograde)
///
/// At `spin = 0` this returns exactly `6` (Schwarzschild ISCO = `6 GM/c^2`); at
/// maximal prograde spin (`a -> 1`) it approaches `1`. Multiply by
/// [`gravitational_radius_cm`] to get the radius in cm.
///
/// # Reference
/// Bardeen, Press & Teukolsky 1972, ApJ 178, 347, Eq. (2.21).
pub fn isco_radius(spin: f64) -> f64 {
    let a = spin;
    let z1 = 1.0 + (1.0 - a * a).cbrt() * ((1.0 + a).cbrt() + (1.0 - a).cbrt());
    let z2 = (3.0 * a * a + z1 * z1).sqrt();
    // Prograde branch (minus sign). For retrograde orbits use `+ sqrt(...)`.
    3.0 + z2 - ((3.0 - z1) * (3.0 + z1 + 2.0 * z2)).sqrt()
}

/// Linear (un-gamma-corrected), HDR-friendly sRGB color of a blackbody at
/// temperature `temp_k` \[K\], returned as `(r, g, b)` with the brightest
/// channel normalized to 1.0 (chromaticity preserved; the caller applies
/// overall HDR intensity).
///
/// Pipeline: Planck spectral radiance `B_lambda(T)` integrated against the CIE
/// 1931 2-degree color-matching functions (Wyman-Sloan-Shirley analytic
/// multi-lobe approximation) over 380-780 nm to get CIE XYZ, then the standard
/// sRGB/D65 matrix to linear RGB, out-of-gamut negatives clamped to 0.
///
/// This is the function that satisfies the project invariant "disk color is
/// computed in Rust, not in the shader" (rule 10): the temperature comes from
/// [`disk_temperature`], the color comes from here, and the shader merely
/// receives the result as a uniform.
///
/// # References
/// - Planck 1901, Ann. Phys. 309, 553 (spectral radiance law).
/// - CIE 1931 standard colorimetric observer.
/// - Wyman, Sloan & Shirley 2013, JCGT 2(2), "Simple Analytic Approximations
///   to the CIE XYZ Color Matching Functions."
/// - IEC 61966-2-1:1999 (sRGB; D65 primaries, XYZ->RGB matrix).
pub fn blackbody_rgb(temp_k: f64) -> (f64, f64, f64) {
    if temp_k <= 0.0 || !temp_k.is_finite() {
        return (0.0, 0.0, 0.0);
    }

    let (mut x, mut y, mut z) = (0.0_f64, 0.0_f64, 0.0_f64);
    let (lambda_min_nm, lambda_max_nm, step_nm) = (380.0, 780.0, 5.0);
    let mut lambda_nm = lambda_min_nm;
    while lambda_nm <= lambda_max_nm {
        let b = planck_spectral_radiance(lambda_nm * 1e-7, temp_k); // nm -> cm
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
    // Normalize to chromaticity so the result depends on hue, not spectral scale.
    let (x, y, z) = (x / sum, y / sum, z / sum);

    // CIE XYZ -> linear sRGB (D65), IEC 61966-2-1.
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

/// Planck spectral radiance `B_lambda(lambda, T)` (CGS). Used only for its
/// spectral *shape* in [`blackbody_rgb`]; absolute scale cancels.
///
/// `B_lambda = (2 h c^2 / lambda^5) / (exp(h c / (lambda k_B T)) - 1)`
///
/// # Reference
/// Planck 1901, Ann. Phys. 309, 553.
fn planck_spectral_radiance(lambda_cm: f64, temp_k: f64) -> f64 {
    let numerator = 2.0 * H_PLANCK * C * C / lambda_cm.powi(5);
    let exponent = H_PLANCK * C / (lambda_cm * K_BOLTZMANN * temp_k);
    numerator / (exponent.exp() - 1.0)
}

/// CIE 1931 2-degree color-matching functions `(x_bar, y_bar, z_bar)` at
/// wavelength `lambda_nm` \[nm\] via the Wyman-Sloan-Shirley 2013 multi-lobe
/// piecewise-Gaussian approximation.
///
/// # Reference
/// Wyman, Sloan & Shirley 2013, JCGT 2(2), Eqs. (2)-(4).
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

    fn rel(a: f64, b: f64) -> f64 {
        (a - b).abs() / b.abs()
    }

    /// Golden test: Eddington luminosity for 10 M_sun reproduces the textbook
    /// value `~1.26e39 erg/s` (tolerance 1%; the coefficient is 3 sig figs).
    ///
    /// Reference: Frank, King & Raine 2002, *Accretion Power in Astrophysics*,
    /// 3rd ed., Eq. (1.5): `L_Edd = 1.26e38 erg/s` per solar mass.
    #[test]
    fn golden_l_eddington_10_msun() {
        assert!(rel(l_eddington(10.0), 1.26e39) < 1.0e-2);
        // Linearity in mass is exact.
        assert!(rel(l_eddington(20.0), 2.0 * l_eddington(10.0)) < 1.0e-12);
    }

    /// Golden test: Schwarzschild (spin 0) ISCO equals `6 GM/c^2`, asserted as
    /// the exact ratio `r_isco / (GM/c^2) == 6`.
    ///
    /// Reference: Bardeen, Press & Teukolsky 1972, ApJ 178, 347, Eq. (2.21).
    #[test]
    fn golden_isco_schwarzschild_ratio_is_six() {
        let m = 12.3; // any mass: the ratio is mass-independent.
        let r_isco_cm = isco_radius(0.0) * gravitational_radius_cm(m);
        assert!((r_isco_cm / gravitational_radius_cm(m) - 6.0).abs() < 1.0e-9);
        assert!((isco_radius(0.0) - 6.0).abs() < 1.0e-9);
    }

    /// Golden test: the Shakura-Sunyaev scaling law `T ∝ r^(-3/4)`, verified
    /// directly as `T(2r) / T(r) == 2^(-3/4)`.
    ///
    /// Reference: Shakura & Sunyaev 1973, A&A 24, 337.
    #[test]
    fn golden_disk_temperature_scaling_law() {
        let (m, mdot, r) = (1e8, 1e24, 1e14);
        let ratio = disk_temperature(2.0 * r, m, mdot) / disk_temperature(r, m, mdot);
        assert!((ratio - 2.0_f64.powf(-0.75)).abs() < 1.0e-9);
    }

    /// Golden test: pinned `disk_temperature` value at a documented triple,
    /// computed once from the SS73 formula and fixed as a regression anchor.
    ///
    /// Inputs: M = 1 M_sun, Mdot = 1e17 g/s, r = 1e7 cm.
    /// `T = (3 G M Mdot / (8 pi sigma_sb r^3))^(1/4) = 2.299181065e6 K`.
    ///
    /// Reference: Shakura & Sunyaev 1973, A&A 24, 337.
    #[test]
    fn golden_disk_temperature_pinned_value() {
        let t = disk_temperature(1.0e7, 1.0, 1.0e17);
        assert!(rel(t, 2_299_181.065_487_474_7) < 1.0e-9);
    }

    /// Round-trip: Mdot from L, then L back from Mdot, recovers the input.
    #[test]
    fn mdot_luminosity_round_trip() {
        let (l, eta) = (l_eddington(1e8), 0.1);
        let mdot = mdot_from_luminosity(l, eta);
        assert!(rel(eta * mdot * C * C, l) < 1.0e-12);
    }

    /// Sanity: a hot blackbody is bluer than a cool one (the disk reddens as it
    /// cools, the visual progression hook of the game).
    #[test]
    fn blackbody_color_temperature_ordering() {
        let (hr, _hg, hb) = blackbody_rgb(20_000.0);
        let (cr, _cg, cb) = blackbody_rgb(3_000.0);
        assert!(hb >= hr, "20000 K should be blue-dominant: {hr},{hb}");
        assert!(cr > cb, "3000 K should be red-dominant: {cr},{cb}");
    }
}
