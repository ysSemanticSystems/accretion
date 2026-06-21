extends Control
## Docked upgrade shop — all tracks visible. Spec: wiki/features/F008-game-shell.md

const TRACK_NAMES := ["Cargo Hold", "Tractor", "Cruise Drive"]
const TRACK_EFFECTS := ["+100 hold", "+40 km range", "+25% cruise accel"]
const MAX_PIPS := 3

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
	for i in 3:
		rows.add_child(_make_row(i))


func _update_milestone_label() -> void:
	const WorldScale = preload("res://scripts/world_scale.gd")
	var max_zone := 0
	var next_zone := 1
	if _objectives != null:
		max_zone = _objectives.max_approach_zone
		next_zone = WorldScale.next_approach_zone(max_zone)
	var zone_count := WorldScale.APPROACH_ZONE_COUNT
	var parts: PackedStringArray = []
	for zone in range(1, zone_count + 1):
		if zone <= max_zone:
			parts.append("●")
		elif zone == next_zone:
			parts.append("◐")
		else:
			parts.append("○")
	milestone_label.text = "M87* approach %s · next: %s" % [
		" ".join(parts),
		WorldScale.approach_zone_label(next_zone),
	]


func _make_row(kind: int) -> Label:
	var level: int = _progression.track_level(kind)
	var cost: float = _progression.track_cost(kind)
	var affordable: bool = cost != INF and _progression.banked_mass >= cost
	var pips := ""
	for p in MAX_PIPS:
		pips += "●" if p < level else "○"
	var prefix := "> " if kind == _selected else "  "
	var cost_text := "maxed" if cost == INF else "%.0f u" % cost
	var row := Label.new()
	row.text = "%s%s  %s  %s  %s" % [
		prefix,
		TRACK_NAMES[kind],
		pips,
		TRACK_EFFECTS[kind],
		cost_text,
	]
	row.add_theme_color_override(
		"font_color",
		Color(0.45, 0.95, 0.55) if affordable else Color(0.95, 0.75, 0.35),
	)
	return row


func _update_selection() -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up"):
		_selected = (_selected + 2) % 3
		_update_selection()
	elif event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % 3
		_update_selection()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ship_upgrade_buy"):
		_try_buy()
	elif event.is_action_pressed("ui_cancel"):
		_close()


func _try_buy() -> void:
	if _progression == null:
		return
	if _progression.try_purchase_track(_selected):
		AudioManager.play_ui_confirm()
		GameEvents.toast.emit("%s upgraded" % TRACK_NAMES[_selected])
		_refresh()
	else:
		AudioManager.play_ui_deny()


func _close() -> void:
	get_tree().paused = false
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("close_upgrade_dock"):
		shell.close_upgrade_dock()
	queue_free()
