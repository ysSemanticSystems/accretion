extends RefCounted
## Format InputMap action labels for settings / HUD hints (presentation only).

const ACTION_LABELS := {
	"ship_thrust_forward": "Thrust forward",
	"ship_thrust_back": "Thrust back",
	"ship_strafe_left": "Strafe left",
	"ship_strafe_right": "Strafe right",
	"ship_thrust_up": "Thrust up",
	"ship_thrust_down": "Thrust down",
	"ship_roll_left": "Roll left",
	"ship_roll_right": "Roll right",
	"ship_boost": "Cruise boost",
	"ship_look": "Look orbit",
	"ship_tractor": "Tractor beam",
	"ship_auto_level_toggle": "Toggle auto-level",
	"ui_cancel": "Pause / back",
}


static func action_key_text(action: StringName) -> String:
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					return "LMB"
				MOUSE_BUTTON_RIGHT:
					return "RMB"
				MOUSE_BUTTON_MIDDLE:
					return "MMB"
	return "?"


static func controls_reference_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for action in ACTION_LABELS.keys():
		lines.append("%s: %s" % [action_key_text(action), ACTION_LABELS[action]])
	return lines
