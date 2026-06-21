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
    #[init(val = 0.0)]
    spin: f64,

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

    #[func]
    fn disk_inner_color(&self) -> Color {
        let t = phys::disk_temperature(self.inner_radius_cm(), self.mass_solar, self.mdot_gs);
        let (r, g, b) = phys::blackbody_rgb(t);
        Color::from_rgba(r as f32, g as f32, b as f32, 1.0)
    }
}
