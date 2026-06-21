extends Control
## Cmd tab — shell actions from the ops board. Spec: F014.

const OpsStyles = preload("res://scripts/ui/ops_styles.gd")

signal resume_requested
signal settings_requested
signal pause_requested
signal abandon_requested

@onready var resume_btn: Button = $VBox/ResumeBtn
@onready var settings_btn: Button = $VBox/SettingsBtn
@onready var pause_btn: Button = $VBox/PauseBtn
@onready var abandon_btn: Button = $VBox/AbandonBtn


func _ready() -> void:
	_style_button(resume_btn)
	_style_button(settings_btn)
	_style_button(pause_btn)
	_style_button(abandon_btn, OpsStyles.WARN)
	resume_btn.pressed.connect(func() -> void: resume_requested.emit())
	settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	pause_btn.pressed.connect(func() -> void: pause_requested.emit())
	abandon_btn.pressed.connect(func() -> void: abandon_requested.emit())


func _style_button(btn: Button, accent: Color = OpsStyles.ACCENT) -> void:
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", accent.lightened(0.15))
	btn.add_theme_color_override("font_pressed_color", accent.darkened(0.1))
