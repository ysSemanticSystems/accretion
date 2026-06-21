extends Control
## Arsenal tab — depot-gated upgrades. Spec: F014.

const OpsStyles = preload("res://scripts/ui/ops_styles.gd")
const UpgradeCatalog = preload("res://scripts/ui/upgrade_catalog.gd")
const UpgradePanelLogic = preload("res://scripts/ui/upgrade_panel_logic.gd")

@onready var status_label: Label = $VBox/StatusLabel
@onready var bank_label: Label = $VBox/BankLabel
@onready var rows: VBoxContainer = $VBox/Rows
@onready var hint_label: Label = $VBox/HintLabel

var _progression: Node
var _depot: Node
var _selected := 0


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
	for i in UpgradeCatalog.TRACK_COUNT:
		rows.add_child(_make_row(i, docked))


func _make_row(kind: int, docked: bool) -> Label:
	var level: int = _progression.track_level(kind)
	var cost: float = _progression.track_cost(kind)
	var affordable: bool = docked and cost != INF and _progression.banked_mass >= cost
	var row := Label.new()
	row.text = UpgradeCatalog.row_text(kind, _selected, level, cost, true)
	row.add_theme_color_override(
		"font_color",
		UpgradeCatalog.row_color(affordable, docked, true),
	)
	return row


func handle_input(event: InputEvent) -> bool:
	if _progression == null or not visible:
		return false
	var next := UpgradePanelLogic.nav_selection(event, _selected)
	if next != _selected:
		_selected = next
		refresh()
		return true
	if UpgradePanelLogic.wants_buy(event):
		if UpgradePanelLogic.try_purchase(_progression, _selected):
			refresh()
		return true
	return false
