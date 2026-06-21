extends Control
## Pause overlay — Resume, Settings, Abandon, Quit to menu.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Settings:
		scale = Vector2.ONE * Settings.hud_scale


func _on_resume_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.PLAYING)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("show_settings"):
		shell.show_settings()


func _on_abandon_pressed() -> void:
	AudioManager.play_ui_click()
	RunTracker.end_run()
	GameState.transition(GameState.State.SUMMARY)


func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	RunTracker.end_run()
	GameState.transition(GameState.State.MENU)
