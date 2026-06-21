extends Control
## Docked upgrade shop — all tracks visible. Spec: wiki/features/F008-game-shell.md

const TRACK_NAMES := ["Cargo Hold", "Tractor", "Cruise Drive"]
const TRACK_EFFECTS := ["+100 hold", "+40 km range", "+25% cruise accel"]
const MAX_PIPS := 3

@onready var bank_label: Label = $Panel/Margin/VBox/BankLabel
@onready var rows: VBoxContainer = $Panel/Margin/VBox/Rows

var _progression: Node
var _selected := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)


func bind_progression(progression: Node) -> void:
	_progression = progression
	_refresh()


func _refresh() -> void:
	if _progression == null:
		return
	bank_label.text = "Banked: %.0f u" % _progression.banked_mass
	for child in rows.get_children():
		child.queue_free()
	for i in 3:
		rows.add_child(_make_row(i))
	_update_selection()


func _make_row(kind: int) -> Label:
	var level: int = _progression.track_level(kind)
	var cost: float = _progression.track_cost(kind)
	var affordable: bool = cost != INF and _progression.banked_mass >= cost
	var pips := ""
	for p in MAX_PIPS:
		pips += "●" if p < level else "○"
	var prefix := "▣ " if kind == _selected else "  "
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
		AudioManager.play_sfx(AudioManager.make_tone(523.25, 0.15, 0.12))
		GameEvents.toast.emit("%s upgraded" % TRACK_NAMES[_selected])
		_refresh()
	else:
		AudioManager.play_ui_click()


func _close() -> void:
	get_tree().paused = false
	var shell := get_tree().root.get_node_or_null("Main")
	if shell != null and shell.has_method("close_upgrade_dock"):
		shell.close_upgrade_dock()
	queue_free()