extends Control
## Screen-edge waypoint chevron. Spec: wiki/features/F010-hud-component.md

@onready var arrow: Label = $Arrow

var _target := Vector3.ZERO
var _kind := ""


func set_target(world_pos: Vector3, kind: String) -> void:
	_target = world_pos
	_kind = kind
	queue_redraw()


func _draw() -> void:
	if _kind == "none" or _kind.is_empty():
		return
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var on_screen: bool = cam.is_position_behind(_target)
	var screen_pos: Vector2 = cam.unproject_position(_target)
	var rect := get_viewport_rect()
	var center := rect.size * 0.5
	if rect.has_point(screen_pos) and not on_screen:
		arrow.visible = false
		return
	var dir := (screen_pos - center)
	if dir.length_squared() < 1.0:
		dir = Vector2.UP
	else:
		dir = dir.normalized()
	var edge := _clamp_to_edge(center + dir * min(rect.size.x, rect.size.y) * 0.42, rect)
	arrow.visible = true
	arrow.position = edge - arrow.size * 0.5
	arrow.rotation = dir.angle() + PI * 0.5
	var color := Color(0.35, 0.85, 1.0) if _kind == "depot" else Color(1.0, 0.65, 0.25)
	arrow.modulate = color


func _clamp_to_edge(p: Vector2, rect: Rect2) -> Vector2:
	var m := 48.0
	return Vector2(
		clampf(p.x, m, rect.size.x - m),
		clampf(p.y, m, rect.size.y - m),
	)
