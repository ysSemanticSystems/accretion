extends Node
## Typed access to the root app shell. Spec: F008.

var _shell: Node


func register(shell: Node) -> void:
	_shell = shell


func show_settings() -> void:
	if _shell != null and _shell.has_method("show_settings"):
		_shell.show_settings()


func show_settings_from_ops() -> void:
	if _shell != null and _shell.has_method("show_settings_from_ops"):
		_shell.show_settings_from_ops()


func close_settings() -> void:
	if _shell != null and _shell.has_method("close_settings"):
		_shell.close_settings()


func show_upgrade_dock(progression: Node) -> void:
	if _shell != null and _shell.has_method("show_upgrade_dock"):
		_shell.show_upgrade_dock(progression)


func close_upgrade_dock() -> void:
	if _shell != null and _shell.has_method("close_upgrade_dock"):
		_shell.close_upgrade_dock()


func save_active_run() -> void:
	if _shell != null and _shell.has_method("save_active_run_from_gameplay"):
		_shell.save_active_run_from_gameplay()


func continue_run() -> void:
	if _shell != null and _shell.has_method("continue_run"):
		_shell.continue_run()
