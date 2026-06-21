//! Thin gdext binding — presentation only (rule 10).

use accretion_core as phys;
use godot::classes::{INode, Node, ShaderMaterial};
use godot::prelude::*;

struct AccretionExt;

#[gdextension]
unsafe impl ExtensionLibrary for AccretionExt {}

/// Game-state inputs (mass, feed, spin) and Rust-computed disk observables.
#[derive(GodotClass)]
#[class(init, base = Node)]
struct BlackHole {
    #[export]
    #[init(val = 10.0)]
    mass_solar: f64,

    #[export]
    #[init(val = 1.0e18)]
    mdot_gs: f64,

    #[export]
    #[var(set = set_spin)]
    #[init(val = 0.0)]
    spin: f64,

    /// Kerr radiative efficiency `eta = 1 - E_isco`; kept in sync with `spin`.
    #[export]
    #[init(val = 0.1)]
    efficiency: f64,

    #[export]
    disk_material: Option<Gd<ShaderMaterial>>,

    #[export]
    #[init(val = "inner_color".into())]
    color_uniform: GString,

    base: Base<Node>,
}

#[godot_api]
impl INode for BlackHole {
    fn ready(&mut self) {
        self.sync_efficiency_from_spin();
    }

    fn process(&mut self, _delta: f64) {
        let color = self.disk_inner_color();
        let uniform = StringName::from(&self.color_uniform);
        if let Some(material) = self.disk_material.as_mut() {
            material.set_shader_parameter(&uniform, &color.to_variant());
        }
    }
}

#[godot_api]
impl BlackHole {
    #[func]
    fn set_spin(&mut self, spin: f64) {
        self.spin = spin;
        self.sync_efficiency_from_spin();
    }

    /// Radiative efficiency implied by the current spin (Kerr ISCO binding energy).
    #[func]
    fn efficiency_from_spin(&self) -> f64 {
        phys::efficiency_from_spin(self.spin)
    }

    #[func]
    fn disk_inner_temp(&self, r_cm: f64) -> f64 {
        phys::disk_temperature(r_cm, self.mass_solar, self.mdot_gs)
    }

    #[func]
    fn l_eddington(&self) -> f64 {
        phys::l_eddington(self.mass_solar)
    }

    #[func]
    fn luminosity_erg_s(&self) -> f64 {
        phys::luminosity_from_mdot(self.mdot_gs, self.efficiency)
    }

    #[func]
    fn eddington_ratio(&self) -> f64 {
        phys::eddington_ratio(self.mass_solar, self.mdot_gs, self.efficiency)
    }

    #[func]
    fn inner_radius_cm(&self) -> f64 {
        phys::r_isco(self.mass_solar, self.spin)
    }

    #[func]
    fn schwarzschild_radius_cm(&self) -> f64 {
        phys::r_s(self.mass_solar)
    }

    #[func]
    fn isco_in_rg(&self) -> f64 {
        phys::isco_radius(self.spin)
    }

    /// New mass \[M_sun\] after accreting at the current feed rate for `dt_s` \[s\].
    #[func]
    fn advance_mass(&self, dt_s: f64) -> f64 {
        phys::advance_mass(self.mass_solar, self.mdot_gs, self.efficiency, dt_s)
    }

    /// Salpeter (Eddington) e-folding time \[s\] at the current efficiency.
    #[func]
    fn salpeter_time_s(&self) -> f64 {
        phys::salpeter_time_s(self.efficiency)
    }

    /// Disk-support fraction `1 - lambda`: >0 stable/recovering, <0 disrupting.
    #[func]
    fn integrity_rate(&self) -> f64 {
        phys::integrity_rate(self.eddington_ratio())
    }

    /// Accretion rate \[g/s\] at the Eddington limit (`lambda = 1`) for current mass.
    #[func]
    fn mdot_at_eddington(&self) -> f64 {
        phys::mdot_at_eddington(self.mass_solar, self.efficiency)
    }

    /// Kerr spin after accreting at the current feed for `dt_s` \[s\].
    #[func]
    fn advance_spin(&self, dt_s: f64) -> f64 {
        phys::advance_spin(
            self.spin,
            self.mass_solar,
            self.mdot_gs,
            self.efficiency,
            dt_s,
        )
    }

    #[func]
    fn disk_inner_color(&self) -> Color {
        let t = phys::disk_temperature(self.inner_radius_cm(), self.mass_solar, self.mdot_gs);
        let (r, g, b) = phys::blackbody_rgb(t);
        Color::from_rgba(r as f32, g as f32, b as f32, 1.0)
    }

    /// Blackbody color of the disk at `r_over_risco` ISCO radii out (clamped to the
    /// inner edge), so the presentation can build a physical radial gradient.
    #[func]
    fn disk_color_at(&self, r_over_risco: f64) -> Color {
        let r = self.inner_radius_cm() * r_over_risco.max(1.0);
        let t = phys::disk_temperature(r, self.mass_solar, self.mdot_gs);
        let (red, g, b) = phys::blackbody_rgb(t);
        Color::from_rgba(red as f32, g as f32, b as f32, 1.0)
    }

    /// Disk inner-edge temperature \[K\] (Shakura-Sunyaev at the ISCO).
    #[func]
    fn disk_inner_temp_k(&self) -> f64 {
        phys::disk_temperature(self.inner_radius_cm(), self.mass_solar, self.mdot_gs)
    }

    /// Prograde orbital frequency \[Hz\] at the ISCO (high-frequency QPO scale).
    #[func]
    fn isco_orbital_frequency_hz(&self) -> f64 {
        phys::orbital_frequency_hz(self.mass_solar, phys::isco_radius(self.spin), self.spin)
    }

    fn sync_efficiency_from_spin(&mut self) {
        self.efficiency = phys::efficiency_from_spin(self.spin);
    }
}
