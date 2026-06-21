extends Control
## Center reticle — tractor aim feedback. Spec: wiki/features/F010-hud-component.md

@onready var dot: ColorRect = $Dot
@onready var ring: ColorRect = $Ring

var _state := "idle"

const COLORS := {
	"idle": Color(1, 1, 1, 0.35),
	"in_cone": Color(0.45, 0.9, 1.0, 0.75),
	"pulling": Color(0.35, 1.0, 0.55, 0.9),
	"full": Color(1.0, 0.45, 0.35, 0.85),
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	set_state("idle")


func set_state(state: String) -> void:
	_state = state
	var c: Color = COLORS.get(state, COLORS.idle)
	dot.color = c
	ring.color = Color(c.r, c.g, c.b, c.a * 0.45)
