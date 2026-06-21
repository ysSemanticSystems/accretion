extends Node
## Audio buses and procedural SFX helpers. Spec: wiki/features/F009-settings-audio.md

const BUS_MASTER := &"Master"
const BUS_SFX := &"SFX"
const BUS_MUSIC := &"Music"

var _music: AudioStreamPlayer


func _ready() -> void:
	_ensure_buses()
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	_music.volume_db = linear_to_db(0.5)
	add_child(_music)
	if Settings:
		Settings.settings_changed.connect(_on_settings_changed)
		apply_volumes(Settings.master_volume, Settings.sfx_volume, Settings.music_volume)


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


func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = BUS_SFX
	player.stream = stream
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_ui_click() -> void:
	play_sfx(make_tone(880.0, 0.04, 0.08))


func _on_settings_changed() -> void:
	apply_volumes(Settings.master_volume, Settings.sfx_volume, Settings.music_volume)


func make_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 18.0)
		var sample: float = sin(TAU * freq * t) * amp * env
		data[i] = int(clampf((sample + 1.0) * 0.5 * 255.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
