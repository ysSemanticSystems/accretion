extends Control
## In-flight ops console — chart, arsenal, intel, cmd. Spec: F014.

const OpsStyles = preload("res://scripts/ui/ops_styles.gd")
const RunFlow = preload("res://scripts/ui/run_flow.gd")

enum Tab { CHART, ARSENAL, INTEL, CMD }

const TAB_NAMES := ["CHART", "ARSENAL", "INTEL", "CMD"]
const TAB_HINTS := [
	"M87* approach ladder — cleared gates unlock inward nodes",
	"Ship loadout — purchases require home dock",
	"Live run telemetry and objective bearing",
	"Command links — pause, settings, abandon",
]

@onready var tab_title: Label = $Frame/HBox/Main/MainBody/Header/TabTitle
@onready var tab_hint: Label = $Frame/HBox/Main/MainBody/Header/TabHint
@onready var tab_buttons: VBoxContainer = $Frame/HBox/Sidebar/SidebarBody/Tabs
@onready var chart_panel: Control = $Frame/HBox/Main/MainBody/Content/ChartPanel
@onready var loadout_panel: Control = $Frame/HBox/Main/MainBody/Content/LoadoutPanel
@onready var intel_panel: Control = $Frame/HBox/Main/MainBody/Content/IntelPanel
@onready var cmd_panel: Control = $Frame/HBox/Main/MainBody/Content/CmdPanel

var _tab := Tab.CHART
var _ship: Node3D
var _home_pos := Vector3.ZERO
var _progression: Node
var _objectives: Node
var _nav: Node
var _cargo: Node
var _depot: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if Settings:
		scale = Vector2.ONE * Settings.hud_scale
	$Frame/HBox/Sidebar.add_theme_stylebox_override("panel", OpsStyles.sidebar_style())
	$Frame/HBox/Main.add_theme_stylebox_override("panel", OpsStyles.panel_style())
	_build_tab_buttons()
	cmd_panel.resume_requested.connect(_on_resume)
	cmd_panel.settings_requested.connect(_on_settings)
	cmd_panel.pause_requested.connect(_on_pause)
	cmd_panel.abandon_requested.connect(_on_abandon)
	GameEvents.milestone_updated.connect(_on_data_changed)
	GameEvents.mass_banked.connect(_on_data_changed_mass)
	GameEvents.cargo_changed.connect(_on_data_changed_cargo)
	GameEvents.run_stats_updated.connect(_on_data_changed_stats)
	_select_tab(Tab.CHART)


func _exit_tree() -> void:
	if GameEvents.milestone_updated.is_connected(_on_data_changed):
		GameEvents.milestone_updated.disconnect(_on_data_changed)
	if GameEvents.mass_banked.is_connected(_on_data_changed_mass):
		GameEvents.mass_banked.disconnect(_on_data_changed_mass)
	if GameEvents.cargo_changed.is_connected(_on_data_changed_cargo):
		GameEvents.cargo_changed.disconnect(_on_data_changed_cargo)
	if GameEvents.run_stats_updated.is_connected(_on_data_changed_stats):
		GameEvents.run_stats_updated.disconnect(_on_data_changed_stats)


func bind_gameplay(root: Node) -> void:
	if root == null:
		return
	_ship = root.get_node_or_null("ShipBody") as Node3D
	_progression = root.get_node_or_null("Progression")
	_objectives = root.get_node_or_null("RunObjectives")
	_nav = root.get_node_or_null("NavigationSystem")
	_cargo = root.get_node_or_null("CargoHold")
	_depot = root.get_node_or_null("HomeDepot")
	if _depot != null:
		_home_pos = _depot.depot_position
	loadout_panel.bind_progression(_progression, _depot)
	intel_panel.bind(_nav, _objectives, _cargo, _progression)
	_refresh_all()


func _on_data_changed(_a: int = 0, _b: int = 0, _c: int = 0) -> void:
	_refresh_all()


func _on_data_changed_mass(_a: float = 0.0, _b: float = 0.0) -> void:
	_refresh_all()


func _on_data_changed_cargo(_a: float = 0.0, _b: float = 0.0) -> void:
	_refresh_all()


func _on_data_changed_stats(_stats: Dictionary = {}) -> void:
	_refresh_all()


func _refresh_all() -> void:
	if _ship == null:
		return
	var max_zone: int = _objectives.max_approach_zone if _objectives != null else 0
	chart_panel.refresh(max_zone, _ship.global_position, _home_pos)
	loadout_panel.refresh()
	intel_panel.refresh()


func _build_tab_buttons() -> void:
	for i in TAB_NAMES.size():
		var btn := Button.new()
		btn.text = TAB_NAMES[i]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_color_override("font_color", OpsStyles.DIM)
		btn.pressed.connect(_select_tab.bind(i))
		tab_buttons.add_child(btn)


func _select_tab(tab: Tab) -> void:
	_tab = tab
	tab_title.text = TAB_NAMES[tab]
	tab_hint.text = TAB_HINTS[tab]
	chart_panel.visible = tab == Tab.CHART
	loadout_panel.visible = tab == Tab.ARSENAL
	intel_panel.visible = tab == Tab.INTEL
	cmd_panel.visible = tab == Tab.CMD
	var idx := 0
	for child in tab_buttons.get_children():
		if child is Button:
			var btn := child as Button
			var active := idx == tab
			btn.add_theme_color_override(
				"font_color",
				OpsStyles.ACCENT if active else OpsStyles.DIM,
			)
		idx += 1
	AudioManager.play_ui_tab()
	_refresh_all()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ops_console") or event.is_action_pressed("ui_cancel"):
		_close()
		return
	if loadout_panel.handle_input(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_tab(Tab.CHART)
			KEY_2:
				_select_tab(Tab.ARSENAL)
			KEY_3:
				_select_tab(Tab.INTEL)
			KEY_4:
				_select_tab(Tab.CMD)


func _on_resume() -> void:
	_close()


func _on_settings() -> void:
	AudioManager.play_ui_click()
	GameShell.show_settings_from_ops()


func _on_pause() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.PAUSED)


func _on_abandon() -> void:
	AudioManager.play_ui_click()
	RunFlow.abandon_run()


func _close() -> void:
	AudioManager.play_ui_click()
	GameState.transition(GameState.State.PLAYING)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
