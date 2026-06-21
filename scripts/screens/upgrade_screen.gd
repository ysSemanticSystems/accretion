extends Control
## Docked upgrade shop — all tracks visible. Spec: wiki/features/F008-game-shell.md

const WorldScale = preload("res://scripts/world_scale.gd")
const UpgradeCatalog = preload("res://scripts/ui/upgrade_catalog.gd")
const MilestoneFormat = preload("res://scripts/ui/milestone_format.gd")
const UpgradePanelLogic = preload("res://scripts/ui/upgrade_panel_logic.gd")

@onready var bank_label: Label = $Panel/Margin/VBox/BankLabel
@onready var milestone_label: Label = $Panel/Margin/VBox/MilestoneLabel
@onready var progress_label: Label = $Panel/Margin/VBox/ProgressLabel
@onready var rows: VBoxContainer = $Panel/Margin/VBox/Rows

var _progression: Node
var _objectives: Node
var _selected := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _progression != null:
		_refresh()


func bind_progression(progression: Node) -> void:
	_progression = progression
	if is_node_ready():
		_refresh()


func bind_objectives(objectives: Node) -> void:
	_objectives = objectives
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _progression == null:
		return
	bank_label.text = "Banked: %.0f u" % _progression.banked_mass
	progress_label.text = "Upgrades %d / %d" % [
		_progression.total_upgrades(),
		_progression.max_upgrades(),
	]
	_update_milestone_label()
	for child in rows.get_children():
		child.queue_free()
	for i in UpgradeCatalog.TRACK_COUNT:
		rows.add_child(_make_row(i))


func _update_milestone_label() -> void:
	var max_zone := 0
	var next_zone := 1
	if _objectives != null:
		max_zone = _objectives.max_approach_zone
		next_zone = WorldScale.next_approach_zone(max_zone)
	milestone_label.text = MilestoneFormat.approach_line(
		max_zone,
		next_zone,
		WorldScale.APPROACH_ZONE_COUNT,
	)


func _make_row(kind: int) -> Label:
	var level: int = _progression.track_level(kind)
	var cost: float = _progression.track_cost(kind)
	var affordable: bool = cost != INF and _progression.banked_mass >= cost
	var row := Label.new()
	row.text = UpgradeCatalog.row_text(kind, _selected, level, cost, true)
	row.add_theme_color_override(
		"font_color",
		UpgradeCatalog.row_color(affordable, true, false),
	)
	return row


func _input(event: InputEvent) -> void:
	if not visible or _progression == null:
		return
	var next := UpgradePanelLogic.nav_selection(event, _selected)
	if next != _selected:
		_selected = next
		_refresh()
	elif UpgradePanelLogic.wants_buy(event):
		if UpgradePanelLogic.try_purchase(_progression, _selected):
			_refresh()
	elif event.is_action_pressed("ui_cancel"):
		_close()


func _close() -> void:
	GameShell.close_upgrade_dock()
