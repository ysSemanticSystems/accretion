extends Node
## Audio buses, ambient loops, and procedural SFX playback. Spec: wiki/features/F009-settings-audio.md

const AudioSynth = preload("res://scripts/audio/audio_synth.gd")

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
	_thrust.stream = AudioSynth.make_loop_hum(62.0, 0.35, 0.09)
	_tractor.stream = AudioSynth.make_loop_hum(140.0, 0.28, 0.07)
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
		_music.stream = AudioSynth.make_ambient_loop()
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
	play_sfx(AudioSynth.make_ui_click(), pitch, 0.72)


func play_ui_tab() -> void:
	play_sfx(AudioSynth.make_ui_tab(), 1.0, 0.45)


func play_ui_confirm() -> void:
	play_sfx(AudioSynth.make_ui_confirm(), randf_range(0.98, 1.02), 0.82)


func play_ui_deny() -> void:
	play_sfx(AudioSynth.make_ui_deny(), randf_range(0.95, 1.0), 0.55)


func play_deposit_chunk() -> void:
	play_sfx(AudioSynth.make_deposit_chunk(), randf_range(0.97, 1.03), 0.7)


func make_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	return AudioSynth.make_tone(freq, duration, amp)


func _on_settings_changed() -> void:
	apply_volumes(Settings.master_volume, Settings.sfx_volume, Settings.music_volume)
