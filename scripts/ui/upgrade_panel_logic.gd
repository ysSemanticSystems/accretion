extends RefCounted
## Shared upgrade keyboard nav and purchase. Spec: F004, F014.

const UpgradeCatalog = preload("res://scripts/ui/upgrade_catalog.gd")


static func nav_selection(event: InputEvent, selected: int) -> int:
	if event.is_action_pressed("ui_up"):
		return (selected + UpgradeCatalog.TRACK_COUNT - 1) % UpgradeCatalog.TRACK_COUNT
	if event.is_action_pressed("ui_down"):
		return (selected + 1) % UpgradeCatalog.TRACK_COUNT
	return selected


static func wants_buy(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("ship_upgrade_buy")


static func try_purchase(progression: Node, selected: int) -> bool:
	if progression == null:
		return false
	if progression.try_purchase_track(selected):
		AudioManager.play_ui_confirm()
		GameEvents.toast.emit("%s upgraded" % UpgradeCatalog.track_name(selected))
		return true
	AudioManager.play_ui_deny()
	return false
