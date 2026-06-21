extends Control
## End-of-run tally. Spec: wiki/features/F008-game-shell.md

@onready var body: RichTextLabel = $Panel/Margin/VBox/Body


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stats := RunTracker.summary_dict()
	body.text = (
		"[b]Seed[/b] %d\n"
		% stats.seed
		+ "[b]Banked[/b] %.0f u\n" % stats.banked
		+ "[b]Sectors visited[/b] %d\n" % stats.sectors
		+ "[b]Upgrades bought[/b] %d\n" % stats.upgrades
		+ "[b]Max distance[/b] %d sectors\n" % stats.max_distance
		+ "[b]Time[/b] %s\n" % _format_time(stats.time_sec)
	)


func _format_time(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	return "%d:%02d" % [m, s]


func _on_new_run_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.PLAYING)


func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.MENU)
