//! # godot-ext
//!
//! Thin gdext binding that exposes [`accretion_core`] to the Godot scene tree.
//!
//! **Presentation boundary (rule 10):** this crate contains NO physics. Every
//! number it returns is a direct, one-line delegation to `accretion-core`. Its
//! only jobs are to expose properties to the editor, route input in, and push
//! disk state (temperature, color) out to the shader.

use accretion_core as phys;
use godot::classes::{INode, Node, ShaderMaterial};
use godot::prelude::*;

struct AccretionExt;

#[gdextension]
unsafe impl ExtensionLibrary for AccretionExt {}

/// A black hole + accretion disk. Holds the inputs (mass, feed rate, spin) and
/// exposes derived disk quantities computed in `accretion-core`. Each frame it
/// pushes the Rust-computed inner-edge color into `disk_material`'s shader
/// uniform, so the visual always reflects the physics.
#[derive(GodotClass)]
#[class(init, base = Node)]
struct BlackHole {
    /// Black hole mass in solar masses. The primary slider target.
    #[export]
    #[init(val = 10.0)]
    mass_solar: f64,

    /// Accretion rate in g/s (CGS). Placeholder feed rate for Slice 0.
    #[export]
    #[init(val = 1.0e18)]
    mdot_gs: f64,

    /// Dimensionless spin a/M in [-1, 1]; sets the ISCO (disk inner edge).
    #[export]
    #[init(val = 0.0)]
    spin: f64,

    /// The disk's shader material. If set, the inner-edge color uniform is
    /// driven from Rust every frame.
    #[export]
    disk_material: Option<Gd<ShaderMaterial>>,

    /// Name of the shader uniform that receives the inner-edge color.
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
    /// Disk effective temperature (K) at radius `r_cm`, computed in the Rust
    /// core. Delegates to [`accretion_core::disk_temperature`].
    #[func]
    fn disk_inner_temp(&self, r_cm: f64) -> f64 {
        phys::disk_temperature(r_cm, self.mass_solar, self.mdot_gs)
    }

    /// Eddington luminosity (erg/s) for the current mass.
    /// Delegates to [`accretion_core::l_eddington`].
    #[func]
    fn l_eddington(&self) -> f64 {
        phys::l_eddington(self.mass_solar)
    }

    /// Inner-edge (ISCO) radius in cm for the current mass and spin.
    /// Delegates to `isco_radius` x `gravitational_radius_cm`.
    #[func]
    fn inner_radius_cm(&self) -> f64 {
        phys::isco_radius(self.spin) * phys::gravitational_radius_cm(self.mass_solar)
    }

    /// HDR blackbody color of the disk's inner edge, computed in Rust by
    /// [`accretion_core::blackbody_rgb`] from the inner-edge temperature.
    /// Returned as a Godot `Color` (linear; brightest channel normalized to 1).
    #[func]
    fn disk_inner_color(&self) -> Color {
        let t = phys::disk_temperature(self.inner_radius_cm(), self.mass_solar, self.mdot_gs);
        let (r, g, b) = phys::blackbody_rgb(t);
        Color::from_rgba(r as f32, g as f32, b as f32, 1.0)
    }
}
