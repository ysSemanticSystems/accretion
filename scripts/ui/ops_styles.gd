extends RefCounted
## Shared ops-console palette (Helldivers-inspired command board).

const BG := Color(0.03, 0.05, 0.08, 0.96)
const PANEL := Color(0.06, 0.09, 0.12, 0.98)
const BORDER := Color(0.22, 0.38, 0.48, 0.85)
const TEXT := Color(0.78, 0.86, 0.92, 1.0)
const DIM := Color(0.45, 0.52, 0.58, 1.0)
const ACCENT := Color(0.35, 0.82, 0.95, 1.0)
const WARN := Color(0.98, 0.72, 0.28, 1.0)
const OK := Color(0.42, 0.92, 0.58, 1.0)
const LOCKED := Color(0.28, 0.32, 0.36, 1.0)


static func panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 12
	box.content_margin_top = 10
	box.content_margin_right = 12
	box.content_margin_bottom = 10
	return box


static func sidebar_style() -> StyleBoxFlat:
	var box := panel_style()
	box.bg_color = Color(0.04, 0.07, 0.1, 0.98)
	return box
