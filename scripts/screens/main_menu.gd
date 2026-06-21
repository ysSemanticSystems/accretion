extends Control
## Main menu — New Run, Settings, Quit. Spec: wiki/features/F008-game-shell.md

@onready var seed_label: Label = $Panel/Margin/VBox/SeedLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed_label.text = "Seed shown after New Run"
	if Settings:
		scale = Vector2.ONE * Settings.hud_scale


func _on_new_run_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.PLAYING)


func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("show_settings"):
		shell.show_settings()


func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
