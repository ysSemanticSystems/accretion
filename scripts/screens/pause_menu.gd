extends Control
## Pause overlay — Resume, Settings, Abandon, Quit to menu.

const RunFlow = preload("res://scripts/ui/run_flow.gd")

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
	GameShell.show_settings()


func _on_abandon_pressed() -> void:
	AudioManager.play_ui_click()
	RunFlow.abandon_run()


func _on_ops_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.OPS)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	RunFlow.quit_to_menu(true)
