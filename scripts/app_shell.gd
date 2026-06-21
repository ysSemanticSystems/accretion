extends Node
## Root shell — screen stack and gameplay host. Spec: wiki/features/F008-game-shell.md

const SHIP_SCENE := preload("res://scenes/Ship.tscn")
const BH_LAB_SCENE := preload("res://scenes/BhSurvival.tscn")
const BACKDROP_SCENE := preload("res://scenes/BhMenuBackdrop.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/screens/MainMenu.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/screens/PauseMenu.tscn")
const SETTINGS_SCENE := preload("res://scenes/screens/SettingsMenu.tscn")
const UPGRADE_SCENE := preload("res://scenes/screens/UpgradeScreen.tscn")
const OPS_SCENE := preload("res://scenes/screens/OpsConsole.tscn")
const SUMMARY_SCENE := preload("res://scenes/screens/RunSummary.tscn")

@onready var backdrop_host: Node3D = $BackdropHost
@onready var gameplay_host: Node = $GameplayHost
@onready var screen_root: Control = $ScreenStack/Screens
@onready var dimmer: ColorRect = $ScreenStack/Dimmer

var _gameplay: Node
var _backdrop: Node3D
var _active_screen: Node
var _settings_origin_state: GameState.State = GameState.State.MENU
var _continue_requested := false


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	call_deferred("_boot")


func _boot() -> void:
	GameState.transition(GameState.State.MENU)


func continue_run() -> void:
	if not SessionSave.has_active_run:
		return
	_continue_requested = true
	GameState.transition(GameState.State.PLAYING)


func _on_state_changed(_from: GameState.State, to: GameState.State) -> void:
	dimmer.visible = to == GameState.State.PAUSED or to == GameState.State.OPS
	match to:
		GameState.State.MENU:
			_clear_gameplay()
			_show_backdrop(true)
			_swap_screen(MAIN_MENU_SCENE.instantiate())
		GameState.State.PLAYING:
			_show_backdrop(false)
			_clear_screen()
			_start_ship_run(_continue_requested)
			_continue_requested = false
		GameState.State.LAB:
			_show_backdrop(false)
			_clear_screen()
			_start_bh_lab()
		GameState.State.PAUSED:
			_swap_screen(PAUSE_MENU_SCENE.instantiate())
		GameState.State.OPS:
			var ops: Node = OPS_SCENE.instantiate()
			_swap_screen(ops)
			if ops.has_method("bind_gameplay") and _gameplay != null:
				ops.bind_gameplay(_gameplay)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.State.SUMMARY:
			_clear_gameplay()
			_show_backdrop(true)
			_swap_screen(SUMMARY_SCENE.instantiate())
		_:
			pass


func show_settings() -> void:
	_settings_origin_state = GameState.state
	_swap_screen(SETTINGS_SCENE.instantiate())


func show_upgrade_dock(progression: Node) -> void:
	if GameState.state != GameState.State.PLAYING:
		return
	get_tree().paused = true
	var screen: Node = UPGRADE_SCENE.instantiate()
	_swap_screen(screen)
	if screen.has_method("bind_progression"):
		screen.bind_progression(progression)
	if screen.has_method("bind_objectives") and _gameplay != null:
		var objectives: Node = _gameplay.get_node_or_null("RunObjectives")
		if objectives != null:
			screen.bind_objectives(objectives)


func show_settings_from_ops() -> void:
	_settings_origin_state = GameState.State.OPS
	show_settings()


func close_settings() -> void:
	_restore_after_settings(_settings_origin_state)


func close_upgrade_dock() -> void:
	get_tree().paused = false
	_clear_screen()
	if _gameplay != null and _gameplay.has_method("export_snapshot"):
		SessionSave.save_active_run(_gameplay.export_snapshot())


func save_active_run_from_gameplay() -> void:
	if _gameplay != null and _gameplay.has_method("export_snapshot"):
		SessionSave.save_active_run(_gameplay.export_snapshot())


func _restore_after_settings(origin: GameState.State) -> void:
	match origin:
		GameState.State.MENU:
			get_tree().paused = false
			_swap_screen(MAIN_MENU_SCENE.instantiate())
		GameState.State.PAUSED:
			get_tree().paused = true
			_swap_screen(PAUSE_MENU_SCENE.instantiate())
		GameState.State.OPS:
			get_tree().paused = true
			var ops: Node = OPS_SCENE.instantiate()
			_swap_screen(ops)
			if ops.has_method("bind_gameplay") and _gameplay != null:
				ops.bind_gameplay(_gameplay)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_:
			get_tree().paused = GameState.state == GameState.State.PAUSED
			_clear_screen()


func _start_ship_run(resume: bool = false) -> void:
	if _gameplay != null:
		if is_instance_valid(_gameplay):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			AudioManager.start_gameplay_audio()
			return
		_gameplay = null
	var seed: int = 1
	var snapshot: Dictionary = {}
	if resume and SessionSave.has_active_run:
		snapshot = SessionSave.active_snapshot()
		seed = int(snapshot.get("seed", 1))
	else:
		SessionSave.clear_active_run()
		seed = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
		if seed == 0:
			seed = 1
		RunTracker.begin_run(seed)
	_gameplay = SHIP_SCENE.instantiate()
	gameplay_host.add_child(_gameplay)
	if resume and not snapshot.is_empty():
		if _gameplay.has_method("restore_run"):
			_gameplay.restore_run(snapshot)
	else:
		if _gameplay.has_method("configure_run"):
			_gameplay.configure_run(seed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.start_gameplay_audio()


func _start_bh_lab() -> void:
	_clear_gameplay()
	_gameplay = BH_LAB_SCENE.instantiate()
	gameplay_host.add_child(_gameplay)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _clear_gameplay() -> void:
	AudioManager.stop_gameplay_audio()
	if _gameplay != null:
		_gameplay.queue_free()
		_gameplay = null


func _show_backdrop(visible: bool) -> void:
	if visible:
		if _backdrop == null:
			_backdrop = BACKDROP_SCENE.instantiate() as Node3D
			backdrop_host.add_child(_backdrop)
		_backdrop.visible = true
	elif _backdrop != null:
		_backdrop.visible = false


func _swap_screen(screen: Node) -> void:
	_clear_screen()
	_active_screen = screen
	screen_root.add_child(screen)


func _clear_screen() -> void:
	if _active_screen != null and is_instance_valid(_active_screen):
		_active_screen.queue_free()
	_active_screen = null
