extends RefCounted
## Shared run exit flows for pause menu and ops console. Spec: F008.


static func abandon_run() -> void:
	SessionSave.clear_active_run()
	RunTracker.end_run()
	SessionSave.record_completed_run(RunTracker.summary_dict())
	GameState.transition(GameState.State.SUMMARY)


static func quit_to_menu(save_active: bool) -> void:
	if save_active:
		GameShell.save_active_run()
	RunTracker.end_run()
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.paused = false
	GameState.transition(GameState.State.MENU)
