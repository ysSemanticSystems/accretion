extends Control
## End-of-run exploration log. Spec: wiki/features/F008-game-shell.md

@onready var title: Label = $Panel/Margin/VBox/Title
@onready var body: RichTextLabel = $Panel/Margin/VBox/Body


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title.text = "Exploration Log"
	var stats := RunTracker.summary_dict()
	const WorldScale = preload("res://scripts/world_scale.gd")
	var closest_line := ""
	var closest: float = float(stats.get("closest_bh_km", -1.0))
	if closest >= 0.0:
		closest_line = "[b]Closest to M87*[/b] %s\n" % WorldScale.format_distance(
			closest * WorldScale.UNITS_PER_KM
		)
	var zone: int = int(stats.get("deepest_approach_zone", 0))
	var zone_line := ""
	if zone > 0:
		zone_line = "[b]Deepest approach[/b] %s\n" % WorldScale.approach_zone_label(zone)
	body.text = (
		"[b]Seed[/b] %d\n"
		% stats.seed
		+ closest_line
		+ zone_line
		+ "[b]Banked[/b] %.0f u\n" % stats.banked
		+ "[b]Sectors visited[/b] %d\n" % stats.sectors
		+ "[b]Upgrades bought[/b] %d\n" % stats.upgrades
		+ "[b]Max sector ring[/b] %d\n" % stats.max_distance
		+ "[b]Time[/b] %s\n" % _format_time(stats.time_sec)
	)


func _format_time(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	return "%d:%02d" % [m, s]


func _on_new_run_pressed() -> void:
	AudioManager.play_ui_click()
	SessionSave.clear_active_run()
	GameState.transition(GameState.State.PLAYING)


func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.MENU)
