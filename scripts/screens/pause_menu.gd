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
	SessionSave.clear_active_run()
	RunTracker.end_run()
	SessionSave.record_completed_run(RunTracker.summary_dict())
	GameState.transition(GameState.State.SUMMARY)


func _on_ops_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.OPS)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("save_active_run_from_gameplay"):
		shell.save_active_run_from_gameplay()
	RunTracker.end_run()
	get_tree().paused = false
	GameState.transition(GameState.State.MENU)
