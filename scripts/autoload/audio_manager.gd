extends Node
## Audio buses, ambient loops, and procedural SFX. Spec: wiki/features/F009-settings-audio.md

const BUS_MASTER := &"Master"
const BUS_SFX := &"SFX"
const BUS_MUSIC := &"Music"

var _music: AudioStreamPlayer
var _thrust: AudioStreamPlayer
var _tractor: AudioStreamPlayer
var _thrust_level: float = 0.0
var _explore_proximity: float = 0.0


func _ready() -> void:
	_ensure_buses()
	_music = _make_loop_player(BUS_MUSIC)
	_thrust = _make_loop_player(BUS_SFX)
	_tractor = _make_loop_player(BUS_SFX)
	add_child(_music)
	add_child(_thrust)
	add_child(_tractor)
	_thrust.stream = make_loop_hum(62.0, 0.35, 0.09)
	_tractor.stream = make_loop_hum(140.0, 0.28, 0.07)
	if Settings:
		Settings.settings_changed.connect(_on_settings_changed)
		apply_volumes(Settings.master_volume, Settings.sfx_volume, Settings.music_volume)


func _make_loop_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = -24.0
	return player


func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, BUS_SFX)
		AudioServer.set_bus_send(1, BUS_MASTER)
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, BUS_MUSIC)
		AudioServer.set_bus_send(2, BUS_MASTER)


func apply_volumes(master: float, sfx: float, music: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), linear_to_db(master))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), linear_to_db(sfx))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), linear_to_db(music))


func start_gameplay_audio() -> void:
	if _music.stream == null:
		_music.stream = make_ambient_loop()
	if not _music.playing:
		_music.play()


func stop_gameplay_audio() -> void:
	if _music.playing:
		_music.stop()
	set_thrust_level(0.0)
	set_tractor_active(false)


func set_explore_proximity(proximity: float) -> void:
	_explore_proximity = clampf(proximity, 0.0, 1.0)
	if not _music.playing:
		return
	_music.pitch_scale = lerpf(0.9, 1.12, _explore_proximity)
	var vol: float = lerpf(0.32, 0.58, _explore_proximity)
	_music.volume_db = linear_to_db(vol) - 8.0


func set_thrust_level(level: float) -> void:
	_thrust_level = clampf(level, 0.0, 1.0)
	if _thrust_level <= 0.02:
		if _thrust.playing:
			_thrust.stop()
		return
	if not _thrust.playing:
		_thrust.play()
	_thrust.volume_db = linear_to_db(_thrust_level) - 24.0
	_thrust.pitch_scale = lerpf(0.85, 1.15, _thrust_level)


func set_tractor_active(active: bool) -> void:
	if not active:
		if _tractor.playing:
			_tractor.stop()
		return
	if not _tractor.playing:
		_tractor.play()


func play_sfx(stream: AudioStream, pitch: float = 1.0, volume: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(clampf(volume, 0.0, 1.0))
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_ui_click() -> void:
	var pitch := 0.96 + fmod(float(Time.get_ticks_msec()) * 0.0011, 0.07)
	play_sfx(make_ui_click(), pitch, 0.72)


func play_ui_tab() -> void:
	play_sfx(make_ui_tab(), 1.0, 0.45)


func play_ui_confirm() -> void:
	play_sfx(make_ui_confirm(), randf_range(0.98, 1.02), 0.82)


func play_ui_deny() -> void:
	play_sfx(make_ui_deny(), randf_range(0.95, 1.0), 0.55)


func play_deposit_chunk() -> void:
	play_sfx(make_deposit_chunk(), randf_range(0.97, 1.03), 0.7)


func _on_settings_changed() -> void:
	apply_volumes(Settings.master_volume, Settings.sfx_volume, Settings.music_volume)


func make_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	return _build_wave(_sample_tone(freq, duration, amp))


func make_ui_click() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.034
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 130.0)
		var noise: float = _pseudo_noise(float(i) * 0.019 + 2.7)
		var thump: float = sin(TAU * 136.0 * t) * 0.42
		var snap: float = sin(TAU * 1800.0 * t) * 0.035 * exp(-t * 320.0)
		samples[i] = (noise * 0.18 + thump + snap) * env * 0.48
	return _build_wave(samples, sample_rate)


func make_ui_tab() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.02
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 180.0)
		var noise: float = _pseudo_noise(float(i) * 0.031 + 9.1)
		var thump: float = sin(TAU * 168.0 * t) * 0.28
		samples[i] = (noise * 0.12 + thump) * env * 0.38
	return _build_wave(samples, sample_rate)


func make_ui_confirm() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.16
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var attack: float = 1.0 - exp(-t * 220.0)
		var env: float = attack * exp(-t * 16.0)
		var body: float = sin(TAU * 174.61 * t) * 0.34 + sin(TAU * 261.63 * t) * 0.22
		var shimmer: float = sin(TAU * 392.0 * t) * 0.06 * exp(-t * 40.0)
		samples[i] = (body + shimmer) * env * 0.42
	return _build_wave(samples, sample_rate)


func make_ui_deny() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.055
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 95.0)
		var thud: float = sin(TAU * 88.0 * t) * 0.55
		var grit: float = _pseudo_noise(float(i) * 0.04 + 1.3) * 0.08
		samples[i] = (thud + grit) * env * 0.34
	return _build_wave(samples, sample_rate)


func make_deposit_chunk() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.11
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 28.0)
		var tone: float = sin(TAU * 196.0 * t) * 0.3 + sin(TAU * 294.0 * t) * 0.16
		var clink: float = _pseudo_noise(float(i) * 0.027 + 6.4) * 0.1 * exp(-t * 60.0)
		samples[i] = (tone + clink) * env * 0.38
	return _build_wave(samples, sample_rate)


func _sample_tone(freq: float, duration: float, amp: float) -> PackedFloat32Array:
	var sample_rate := 22050
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 18.0)
		samples[i] = sin(TAU * freq * t) * amp * env
	return samples


func _pseudo_noise(seed: float) -> float:
	return fmod(abs(sin(seed * 12.9898) * 43758.5453), 1.0) * 2.0 - 1.0


func _build_wave(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size())
	for i in samples.size():
		data[i] = int(clampf((samples[i] + 1.0) * 0.5 * 255.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func make_loop_hum(base_freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var sample: float = (
			sin(TAU * base_freq * t) * 0.55
			+ sin(TAU * base_freq * 1.47 * t) * 0.25
			+ sin(TAU * base_freq * 2.03 * t) * 0.12
		) * amp
		data[i] = int(clampf((sample + 1.0) * 0.5 * 255.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.data = data
	return stream


func make_ambient_loop() -> AudioStreamWAV:
	var sample_rate := 11025
	var duration := 6.0
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var sample: float = (
			sin(TAU * 55.0 * t) * 0.08
			+ sin(TAU * 82.5 * t + 0.7) * 0.05
			+ sin(TAU * 110.0 * t + 1.3) * 0.03
		)
		data[i] = int(clampf((sample + 1.0) * 0.5 * 255.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.data = data
	return stream
