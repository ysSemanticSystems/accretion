extends Node
## Soft visual-only collection feedback. Spec: wiki/features/F002-tractor-cargo.md

@export var flash_duration := 0.25
@export var enable_sound := true
@export var sound_volume_db := -22.0

var _audio: AudioStreamPlayer
var _cargo_bar: ProgressBar


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.bus = &"SFX"
	_audio.volume_db = sound_volume_db
	add_child(_audio)


func set_cargo_bar(bar: ProgressBar) -> void:
	_cargo_bar = bar


func play_at(world_pos: Vector3, mass: float, cargo_bar: ProgressBar = null) -> void:
	var bar := cargo_bar if cargo_bar != null else _cargo_bar
	_spawn_burst(world_pos, mass)
	_spawn_floater(world_pos, mass)
	_pulse_cargo_bar(bar)
	if enable_sound:
		_play_soft_chime()


func _world_fx_parent() -> Node:
	var node: Node = self
	while node != null:
		if node.is_in_group("gameplay_root"):
			return node
		node = node.get_parent()
	return get_tree().root


func _spawn_burst(world_pos: Vector3, mass: float) -> void:
	var particles := GPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.amount = int(clampf(mass * 0.35, 6.0, 18.0))
	particles.lifetime = 0.35
	particles.global_position = world_pos
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 22.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.04
	mat.scale_max = 0.1
	mat.color = Color(1.0, 0.72, 0.35, 0.55)
	particles.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	particles.draw_pass_1 = quad
	_world_fx_parent().add_child(particles)
	particles.emitting = true
	var timer := get_tree().create_timer(particles.lifetime + 0.1)
	timer.timeout.connect(particles.queue_free)


func _pulse_cargo_bar(bar: ProgressBar) -> void:
	if bar == null:
		return
	var tween := create_tween()
	tween.tween_property(bar, "modulate", Color(1.15, 1.1, 0.85, 1.0), 0.08)
	tween.tween_property(bar, "modulate", Color(1, 1, 1, 1), flash_duration)


func _spawn_floater(world_pos: Vector3, mass: float) -> void:
	var label := Label3D.new()
	label.text = "+%.0f" % mass
	label.font_size = 22
	label.modulate = Color(1.0, 0.88, 0.5, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.global_position = world_pos + Vector3(0, 1.5, 0)
	_world_fx_parent().add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 5, 0), 0.65)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(label.queue_free)


func _play_soft_chime() -> void:
	if _audio.stream == null:
		_audio.stream = _make_chime_stream()
	_audio.pitch_scale = 1.0 + randf_range(-0.03, 0.03)
	_audio.play()


func _make_chime_stream() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.12
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in sample_count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 22.0) * (1.0 - smoothstep(0.0, duration, t))
		var sample: float = (
			sin(TAU * 392.0 * t) * 0.55 + sin(TAU * 523.25 * t) * 0.25
		) * env * 0.12
		data[i] = int(clampf((sample + 1.0) * 0.5 * 255.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
