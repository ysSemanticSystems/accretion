extends Control
## Arsenal tab — depot-gated upgrades. Spec: F014.

const OpsStyles = preload("res://scripts/ui/ops_styles.gd")

const TRACK_NAMES := ["Cargo Hold", "Tractor Beam", "Cruise Drive"]
const TRACK_EFFECTS := ["+100 u hold", "+40 km range", "+25% cruise accel"]
const MAX_PIPS := 3

var _progression: Node
var _depot: Node
var _selected := 0

@onready var status_label: Label = $VBox/StatusLabel
@onready var bank_label: Label = $VBox/BankLabel
@onready var rows: VBoxContainer = $VBox/Rows
@onready var hint_label: Label = $VBox/HintLabel


func bind_progression(progression: Node, depot: Node) -> void:
	_progression = progression
	_depot = depot
	if is_node_ready():
		refresh()


func refresh() -> void:
	if _progression == null:
		return
	var docked: bool = _depot != null and _depot.has_method("is_at_depot") and _depot.is_at_depot()
	status_label.text = "DOCK STATUS · ARMED" if docked else "DOCK STATUS · AWAY FROM HOME"
	status_label.add_theme_color_override(
		"font_color",
		OpsStyles.OK if docked else OpsStyles.WARN,
	)
	bank_label.text = "BANKED MASS · %.0f u" % _progression.banked_mass
	hint_label.text = (
		"↑↓ select · Enter purchase · dock at home beacon to buy"
		if docked
		else "Fly to the cyan home beacon to authorize purchases"
	)
	for child in rows.get_children():
		child.queue_free()
	for i in 3:
		rows.add_child(_make_row(i, docked))


func _make_row(kind: int, docked: bool) -> Label:
	var level: int = _progression.track_level(kind)
	var cost: float = _progression.track_cost(kind)
	var affordable: bool = docked and cost != INF and _progression.banked_mass >= cost
	var pips := ""
	for p in MAX_PIPS:
		pips += "●" if p < level else "○"
	var prefix := "> " if kind == _selected else "  "
	var cost_text := "MAXED" if cost == INF else "%.0f u" % cost
	var row := Label.new()
	row.text = "%s%s  %s  %s  %s" % [prefix, TRACK_NAMES[kind], pips, TRACK_EFFECTS[kind], cost_text]
	var col := OpsStyles.DIM
	if affordable:
		col = OpsStyles.OK
	elif docked:
		col = OpsStyles.WARN
	row.add_theme_color_override("font_color", col)
	return row


func handle_input(event: InputEvent) -> bool:
	if _progression == null or not visible:
		return false
	if event.is_action_pressed("ui_up"):
		_selected = (_selected + 2) % 3
		refresh()
		return true
	if event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % 3
		refresh()
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ship_upgrade_buy"):
		if _progression.try_purchase_track(_selected):
			AudioManager.play_ui_confirm()
			GameEvents.toast.emit("%s upgraded" % TRACK_NAMES[_selected])
			refresh()
		else:
			AudioManager.play_ui_deny()
		return true
	return false
