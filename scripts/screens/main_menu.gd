extends Control
## Main menu — New Run, Continue, BH Lab, Settings, Quit. Spec: wiki/features/F008-game-shell.md

@onready var seed_label: Label = $Panel/Margin/VBox/SeedLabel
@onready var continue_btn: Button = $Panel/Margin/VBox/Continue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_stats()
	if Settings:
		scale = Vector2.ONE * Settings.hud_scale


func _refresh_stats() -> void:
	seed_label.text = SessionSave.profile_line()
	continue_btn.visible = SessionSave.has_active_run
	continue_btn.disabled = not SessionSave.has_active_run


func _on_continue_pressed() -> void:
	AudioManager.play_ui_click()
	GameShell.continue_run()


func _on_new_run_pressed() -> void:
	AudioManager.play_ui_click()
	SessionSave.clear_active_run()
	GameState.transition(GameState.State.PLAYING)


func _on_bh_lab_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.LAB)


func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	GameShell.show_settings()


func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()
