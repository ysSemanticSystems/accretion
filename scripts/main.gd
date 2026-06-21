extends Node3D
## Presentation glue only (no physics, rule 10): wires the mass slider to the
## BlackHole gdext node and reads back Rust-computed disk state for display. The
## disk's inner-edge color uniform is pushed to the shader from Rust inside
## BlackHole._process; here we only mirror it into the readout swatch.

@onready var black_hole: Node = $BlackHole
@onready var camera: Camera3D = $Camera3D
@onready var mass_slider: HSlider = $UI/Panel/Controls/MassSlider
@onready var info_label: Label = $UI/Panel/Controls/InfoLabel
@onready var swatch: ColorRect = $UI/Panel/Controls/Swatch


func _ready() -> void:
	camera.look_at(Vector3.ZERO, Vector3.UP)
	mass_slider.value_changed.connect(_on_mass_changed)
	_apply()


func _on_mass_changed(_value: float) -> void:
	_apply()


func _apply() -> void:
	# Slider holds log10(mass); the core takes a linear mass in solar masses.
	black_hole.set("mass_solar", pow(10.0, mass_slider.value))
	_update_readout()


func _process(_delta: float) -> void:
	_update_readout()


func _update_readout() -> void:
	var m: float = black_hole.get("mass_solar")
	var r_in: float = black_hole.call("inner_radius_cm")
	var t: float = black_hole.call("disk_inner_temp", r_in)
	var c: Color = black_hole.call("disk_inner_color")
	swatch.color = c
	info_label.text = (
		"M_BH = %.3e M_sun\nMdot = %.2e g/s\nT_inner = %.3e K\ninner color (Rust) = (%.2f, %.2f, %.2f)"
		% [m, black_hole.get("mdot_gs"), t, c.r, c.g, c.b]
	)
