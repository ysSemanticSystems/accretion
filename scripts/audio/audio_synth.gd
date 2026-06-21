extends RefCounted
## Procedural WAV synthesis for UI and ambient loops. Spec: F009.


static func make_tone(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	return build_wave(_sample_tone(freq, duration, amp))


static func make_ui_click() -> AudioStreamWAV:
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
	return build_wave(samples, sample_rate)


static func make_ui_tab() -> AudioStreamWAV:
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
	return build_wave(samples, sample_rate)


static func make_ui_confirm() -> AudioStreamWAV:
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
	return build_wave(samples, sample_rate)


static func make_ui_deny() -> AudioStreamWAV:
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
	return build_wave(samples, sample_rate)


static func make_deposit_chunk() -> AudioStreamWAV:
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
	return build_wave(samples, sample_rate)


static func make_loop_hum(base_freq: float, duration: float, amp: float) -> AudioStreamWAV:
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


static func make_ambient_loop() -> AudioStreamWAV:
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


static func _sample_tone(freq: float, duration: float, amp: float) -> PackedFloat32Array:
	var sample_rate := 22050
	var count := int(sample_rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / float(sample_rate)
		var env: float = exp(-t * 18.0)
		samples[i] = sin(TAU * freq * t) * amp * env
	return samples


static func _pseudo_noise(seed: float) -> float:
	return fmod(abs(sin(seed * 12.9898) * 43758.5453), 1.0) * 2.0 - 1.0


static func build_wave(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
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
