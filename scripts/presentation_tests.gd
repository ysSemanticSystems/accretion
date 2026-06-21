extends Node
## Headless presentation/shell tests — scene/script compatibility and navigation.
##
## Run: make godot-presentation  (or godot --headless --path . res://scenes/PresentationTests.tscn)

const SCENE_PATHS: Array[String] = [
	"res://scenes/Main.tscn",
	"res://scenes/Ship.tscn",
	"res://scenes/ui/GameHud.tscn",
	"res://scenes/harvestable_debris.tscn",
	"res://scenes/BhMenuBackdrop.tscn",
	"res://scenes/BhSurvival.tscn",
	"res://scenes/DistantBlackHole.tscn",
	"res://scenes/screens/MainMenu.tscn",
	"res://scenes/screens/PauseMenu.tscn",
	"res://scenes/screens/SettingsMenu.tscn",
	"res://scenes/screens/UpgradeScreen.tscn",
	"res://scenes/screens/OpsConsole.tscn",
	"res://scenes/screens/RunSummary.tscn",
]

const MAIN_SHELL := preload("res://scenes/Main.tscn")


func _ready() -> void:
	for _i in 30:
		if ClassDB.class_exists("BlackHole"):
			break
		await get_tree().process_frame
	var exit_code := await _run()
	get_tree().quit(exit_code)


func _run() -> int:
	var failures: Array[String] = []
	failures.append_array(_test_scene_script_compat())
	failures.append_array(_test_game_state_pause())
	failures.append_array(_test_settings_api())
	failures.append_array(await _test_shell_settings_navigation())
	failures.append_array(await _test_new_run_flow())
	failures.append_array(await _test_upgrade_dock_flow())
	failures.append_array(await _test_toast_queue_burst())
	failures.append_array(_test_visibility_constants())
	failures.append_array(_test_shader_qpo_fix())
	failures.append_array(_test_settings_apply_runtime())
	failures.append_array(await _test_bh_lab_flow())
	failures.append_array(_test_approach_zone_constants())
	failures.append_array(_test_session_save_roundtrip())
	if failures.is_empty():
		print("[presentation_tests] OK (%d scenes, shell + gameplay regressions)" % SCENE_PATHS.size())
		return 0
	for msg in failures:
		push_error("[presentation_tests] %s" % msg)
	return 1


func _test_scene_script_compat() -> Array[String]:
	var failures: Array[String] = []
	for path in SCENE_PATHS:
		var packed: PackedScene = load(path)
		if packed == null:
			failures.append("failed to load %s" % path)
			continue
		var root: Node = packed.instantiate()
		_collect_script_mismatches(root, path, failures)
		root.queue_free()
	return failures


func _collect_script_mismatches(node: Node, path: String, failures: Array[String]) -> void:
	var script: Script = node.get_script()
	if script != null:
		var base_type: String = script.get_instance_base_type()
		if base_type != "" and not node.is_class(base_type):
			failures.append(
				"%s: node '%s' (%s) cannot use script extending %s"
				% [path, node.name, node.get_class(), base_type]
			)
	for child in node.get_children():
		_collect_script_mismatches(child, path, failures)


func _test_game_state_pause() -> Array[String]:
	var failures: Array[String] = []
	var prior := GameState.state
	get_tree().paused = false
	GameState.state = GameState.State.PLAYING
	GameState.transition(GameState.State.PAUSED)
	if GameState.state != GameState.State.PAUSED:
		failures.append("GameState did not enter PAUSED")
	if not get_tree().paused:
		failures.append("tree.paused not set when GameState is PAUSED")
	GameState.transition(GameState.State.PLAYING)
	if get_tree().paused:
		failures.append("tree.paused still true after resume")
	GameState.state = prior
	get_tree().paused = prior == GameState.State.PAUSED
	return failures


func _test_settings_api() -> Array[String]:
	var failures: Array[String] = []
	var prior_sens: float = Settings.mouse_sensitivity
	Settings.set_setting("mouse_sensitivity", 0.0042)
	if not is_equal_approx(Settings.get_setting("mouse_sensitivity"), 0.0042):
		failures.append("Settings set/get round-trip failed for mouse_sensitivity")
	Settings.set_setting("mouse_sensitivity", prior_sens)
	return failures


func _test_shell_settings_navigation() -> Array[String]:
	var failures: Array[String] = []
	var prior_state := GameState.state
	get_tree().paused = false

	var shell: Node = MAIN_SHELL.instantiate()
	get_tree().root.add_child.call_deferred(shell)
	for _i in 120:
		if GameState.state != GameState.State.BOOT and is_instance_valid(shell.get_parent()):
			break
		await get_tree().process_frame

	if GameState.state != GameState.State.MENU:
		failures.append("shell boot did not reach MENU (state=%s)" % GameState.state)
		if is_instance_valid(shell):
			shell.queue_free()
		GameState.state = prior_state
		return failures

	if not _active_screen_named(shell, "MainMenu"):
		failures.append("expected MainMenu after boot, got %s" % _active_screen_name(shell))

	shell.show_settings()
	await get_tree().process_frame
	if not _active_screen_named(shell, "SettingsMenu"):
		failures.append("show_settings did not swap to SettingsMenu")

	shell.close_settings()
	await get_tree().process_frame
	if not _active_screen_named(shell, "MainMenu"):
		failures.append("close_settings from MENU did not restore MainMenu (blank-screen regression)")

	shell.queue_free()
	GameState.state = prior_state
	get_tree().paused = prior_state == GameState.State.PAUSED
	return failures


func _active_screen_name(shell: Node) -> String:
	var screen: Variant = shell.get("_active_screen")
	if screen == null or not is_instance_valid(screen):
		return "<none>"
	return screen.name


func _active_screen_named(shell: Node, expected: String) -> bool:
	return _active_screen_name(shell) == expected


func _test_game_hud_ready() -> Array[String]:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://scenes/ui/GameHud.tscn")
	var hud: Node = packed.instantiate()
	add_child.call_deferred(hud)
	for _i in 30:
		if hud.is_inside_tree() and hud.get_node_or_null("HudPanel") != null:
			break
		await get_tree().process_frame
	if hud.get_node_or_null("HudPanel") == null:
		failures.append("GameHud failed to enter tree / build panel")
	elif hud.has_method("cargo_bar_ref") and hud.cargo_bar_ref() == null:
		failures.append("GameHud cargo_bar_ref null after ready (scale-on-CanvasLayer regression)")
	hud.queue_free()
	return failures


func _test_new_run_flow() -> Array[String]:
	var failures: Array[String] = []
	failures.append_array(await _test_game_hud_ready())
	var prior_state := GameState.state
	get_tree().paused = false

	var shell: Node = MAIN_SHELL.instantiate()
	get_tree().root.add_child.call_deferred(shell)
	for _i in 120:
		if GameState.state != GameState.State.BOOT and is_instance_valid(shell.get_parent()):
			break
		await get_tree().process_frame

	if GameState.state != GameState.State.MENU:
		failures.append("new-run test: shell did not reach MENU")
		shell.queue_free()
		GameState.state = prior_state
		return failures

	GameState.transition(GameState.State.PLAYING)
	for _i in 120:
		var gameplay: Variant = shell.get("_gameplay")
		if gameplay != null and is_instance_valid(gameplay):
			break
		await get_tree().process_frame

	var gameplay_node: Node = shell.get("_gameplay")
	if gameplay_node == null or not is_instance_valid(gameplay_node):
		failures.append("New Run did not spawn Ship gameplay scene")
	elif gameplay_node.get_node_or_null("GameHud") == null:
		failures.append("Ship scene missing GameHud after New Run")
	elif gameplay_node.get_node_or_null("ChaseCamera") == null:
		failures.append("Ship scene missing ChaseCamera after New Run")
	elif gameplay_node.get_node_or_null("RunObjectives") == null:
		failures.append("Ship scene missing RunObjectives after New Run")
	elif gameplay_node.get_node_or_null("DistantBlackHole") == null:
		failures.append("Ship scene missing DistantBlackHole skyline after New Run")

	shell.queue_free()
	GameState.state = prior_state
	get_tree().paused = prior_state == GameState.State.PAUSED
	return failures


func _test_upgrade_dock_flow() -> Array[String]:
	var failures: Array[String] = []
	var prior_state := GameState.state
	get_tree().paused = false

	var shell: Node = MAIN_SHELL.instantiate()
	get_tree().root.add_child.call_deferred(shell)
	for _i in 120:
		if GameState.state != GameState.State.BOOT and is_instance_valid(shell.get_parent()):
			break
		await get_tree().process_frame

	GameState.transition(GameState.State.PLAYING)
	for _i in 120:
		var gameplay: Variant = shell.get("_gameplay")
		if gameplay != null and is_instance_valid(gameplay):
			break
		await get_tree().process_frame

	var gameplay_node: Node = shell.get("_gameplay")
	if gameplay_node == null or not is_instance_valid(gameplay_node):
		failures.append("upgrade-dock test: Ship gameplay missing")
		shell.queue_free()
		GameState.state = prior_state
		return failures

	var progression: Node = gameplay_node.get_node_or_null("Progression")
	if progression == null:
		failures.append("upgrade-dock test: Progression node missing")
		shell.queue_free()
		GameState.state = prior_state
		return failures

	if progression.has_method("add_banked"):
		progression.add_banked(100.0)
	shell.show_upgrade_dock(progression)
	await get_tree().process_frame

	if not _active_screen_named(shell, "UpgradeScreen"):
		failures.append("show_upgrade_dock did not open UpgradeScreen")

	shell.close_upgrade_dock()
	await get_tree().process_frame
	get_tree().paused = false

	shell.queue_free()
	GameState.state = prior_state
	get_tree().paused = prior_state == GameState.State.PAUSED
	return failures


func _test_toast_queue_burst() -> Array[String]:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://scenes/ui/GameHud.tscn")
	var hud: Node = packed.instantiate()
	add_child.call_deferred(hud)
	for _i in 30:
		if hud.is_inside_tree():
			break
		await get_tree().process_frame
	var queue: Node = hud.get_node_or_null("ToastQueue")
	if queue == null or not queue.has_method("push"):
		failures.append("ToastQueue missing from GameHud")
		hud.queue_free()
		return failures
	for i in 8:
		queue.push("burst toast %d" % i)
	for _i in 20:
		await get_tree().process_frame
	hud.queue_free()
	for _i in 10:
		await get_tree().process_frame
	return failures


func _test_visibility_constants() -> Array[String]:
	var failures: Array[String] = []
	const WorldScale = preload("res://scripts/world_scale.gd")
	if WorldScale.BEACON_FADE_IN_UNITS >= WorldScale.BEACON_FADE_OUT_UNITS:
		failures.append("BEACON_FADE_IN must be less than BEACON_FADE_OUT")
	if WorldScale.VISUAL_MESH_RADIUS_UNITS > WorldScale.BEACON_FADE_OUT_UNITS:
		failures.append("VISUAL_MESH_RADIUS should not exceed BEACON_FADE_OUT")
	if WorldScale.BH_WORLD_POSITION.z >= 0.0:
		failures.append("BH_WORLD_POSITION should lie inward (-Z)")
	if WorldScale.BH_VISUAL_SPHERE_RADIUS <= 0.0:
		failures.append("BH_VISUAL_SPHERE_RADIUS must be positive")
	if not WorldScale.is_inside_bh_volume(WorldScale.BH_WORLD_POSITION):
		failures.append("BH centre should read as inside capture volume")
	var outside: Vector3 = WorldScale.BH_WORLD_POSITION + Vector3(
		WorldScale.BH_VISUAL_SPHERE_RADIUS + 500.0, 0.0, 0.0
	)
	if WorldScale.is_inside_bh_volume(outside):
		failures.append("outside capture sphere should not read as inside")
	if WorldScale.bh_interior_blend(WorldScale.BH_WORLD_POSITION) < 0.99:
		failures.append("BH centre should have full interior blend")
	return failures


func _test_shader_qpo_fix() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://shaders/blackhole.gdshader"
	if not FileAccess.file_exists(path):
		failures.append("blackhole.gdshader missing")
		return failures
	var text := FileAccess.get_file_as_string(path)
	if "uv.y * PI * 2.0 + TIME * qpo_phase_rate" in text:
		failures.append("blackhole.gdshader still uses invalid uv.y in calc_disc_color")
	return failures


func _test_settings_apply_runtime() -> Array[String]:
	var failures: Array[String] = []
	if not Settings.has_method("apply_runtime"):
		failures.append("Settings missing apply_runtime()")
		return failures
	_settings_test_fired = false
	Settings.settings_changed.connect(_on_settings_test_fired)
	Settings.apply_runtime()
	Settings.settings_changed.disconnect(_on_settings_test_fired)
	if not _settings_test_fired:
		failures.append("Settings.apply_runtime() did not emit settings_changed")
	return failures


var _settings_test_fired := false


func _on_settings_test_fired() -> void:
	_settings_test_fired = true


func _test_bh_lab_flow() -> Array[String]:
	var failures: Array[String] = []
	var prior_state := GameState.state
	get_tree().paused = false

	var shell: Node = MAIN_SHELL.instantiate()
	get_tree().root.add_child.call_deferred(shell)
	for _i in 120:
		if GameState.state != GameState.State.BOOT and is_instance_valid(shell.get_parent()):
			break
		await get_tree().process_frame

	GameState.transition(GameState.State.LAB)
	for _i in 120:
		var gameplay: Variant = shell.get("_gameplay")
		if gameplay != null and is_instance_valid(gameplay):
			break
		await get_tree().process_frame

	var lab: Node = shell.get("_gameplay")
	if lab == null or not is_instance_valid(lab):
		failures.append("BH Lab did not spawn BhSurvival scene")
	elif lab.name != "BhSurvival":
		failures.append("BH Lab root should be named BhSurvival, got %s" % lab.name)

	GameState.transition(GameState.State.MENU)
	await get_tree().process_frame
	if GameState.state != GameState.State.MENU:
		failures.append("LAB→MENU transition failed")

	shell.queue_free()
	GameState.state = prior_state
	get_tree().paused = false
	return failures


func _test_approach_zone_constants() -> Array[String]:
	var failures: Array[String] = []
	const WorldScale = preload("res://scripts/world_scale.gd")
	if WorldScale.APPROACH_ZONE_COUNT != 4:
		failures.append("APPROACH_ZONE_COUNT expected 4")
	if WorldScale.APPROACH_ZONE_DISTANCES.size() != 4:
		failures.append("APPROACH_ZONE_DISTANCES expected 4 thresholds")
	if WorldScale.distance_to_bh_km(Vector3.ZERO) <= 0.0:
		failures.append("distance_to_bh_km at origin should be positive")
	var star_dir: Vector3 = (
		WorldScale.PRIMARY_STAR_POSITION - WorldScale.BH_WORLD_POSITION
	).normalized()
	if absf(star_dir.dot((WorldScale.BH_WORLD_POSITION - Vector3.ZERO).normalized())) > 0.92:
		failures.append("primary star should not share bearing with M87*")
	return failures


func _test_session_save_roundtrip() -> Array[String]:
	var failures: Array[String] = []
	SessionSave.clear_active_run()
	if SessionSave.has_active_run:
		failures.append("SessionSave still has active run after clear")
	var snap := {
		"seed": 4242,
		"ship_x": 12.0,
		"ship_y": 3.0,
		"ship_z": -50.0,
		"cargo_current": 120.0,
		"elapsed_sec": 99.5,
		"progression": {"banked_mass": 200.0, "cargo_level": 1},
		"objectives": {
			"max_approach_zone": 2,
			"max_sector_ring": 1,
		},
	}
	SessionSave.save_active_run(snap)
	if not SessionSave.has_active_run:
		failures.append("SessionSave did not mark active run after save")
	var loaded: Dictionary = SessionSave.active_snapshot()
	if int(loaded.get("seed", -1)) != 4242:
		failures.append("SessionSave round-trip seed mismatch")
	if float(loaded.get("cargo_current", 0.0)) != 120.0:
		failures.append("SessionSave round-trip cargo mismatch")
	SessionSave.clear_active_run()
	return failures
