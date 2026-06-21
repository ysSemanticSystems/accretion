extends Node
## Global game flow. Spec: wiki/architecture/game-shell.md

enum State { BOOT, MENU, PLAYING, PAUSED, OPS, UPGRADE, SUMMARY, LAB }

signal state_changed(from: State, to: State)

var state: State = State.BOOT


func transition(to: State) -> void:
	if state == to:
		return
	var from := state
	state = to
	get_tree().paused = (
		to == State.PAUSED or to == State.OPS or to == State.UPGRADE
	)
	state_changed.emit(from, to)


func is_playing() -> bool:
	return state == State.PLAYING


func is_paused() -> bool:
	return state == State.PAUSED
