# SoundSystem.gd
# All audio is synthesised at startup (no asset files): SFX are cached once,
# the background music is a seamless loop in the Hirajoshi scale (A B C E F).
class_name SoundSystem
extends Node

const SR := 22050
const MAX_PLAYERS := 8

var audio_players: Array[AudioStreamPlayer] = []
var current_player_index := 0
var sfx: Dictionary = {}
var music_player: AudioStreamPlayer
var _music_tween: Tween

# --- synthesis helpers -------------------------------------------------------

func _osc(kind: String, ph: float) -> float:
	var x := ph - floorf(ph)
	match kind:
		"square": return 1.0 if x < 0.5 else -1.0
		"pulse": return 1.0 if x < 0.25 else -1.0
		"saw": return 2.0 * x - 1.0
		"tri": return 4.0 * absf(x - 0.5) - 1.0
		_: return sin(TAU * x)

func _to_stream(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := minf(1.0, 0.92 / peak) # never clip; keep authored loudness when already quiet
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = SR
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s

# One tone/noise voice with exponential pitch sweep, attack and decay.
# noise: 0 = pure oscillator .. 1 = filtered noise only; cutoff sweeps lp0 -> lp1 (0..1).
func _voice(dur: float, f0: float, f1: float, kind: String, vol: float, attack := 0.004, noise := 0.0, lp0 := 1.0, lp1 := 1.0, decay := 5.0) -> PackedFloat32Array:
	var n := int(SR * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var f := f0 * pow(f1 / f0, t) if f0 > 0.0 else 0.0
		ph += f / SR
		var env := minf(1.0, float(i) / maxf(1.0, attack * SR)) * exp(-decay * t)
		var tone := _osc(kind, ph) if f0 > 0.0 else 0.0
		var a := lerpf(lp0, lp1, t)
		lp += a * (randf_range(-1.0, 1.0) - lp)
		out[i] = (tone * (1.0 - noise) + lp * noise * 2.0) * env * vol
	return out

# Add src into dst starting at offset (wrapping, so tails cross the loop seam).
func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, offset: int, wrap := false) -> void:
	for i in src.size():
		var j := offset + i
		if wrap:
			j %= dst.size()
		elif j >= dst.size():
			break
		dst[j] += src[i]

func _seq(freqs: Array, step: float, dur: float, kind: String, vol: float, total: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(SR * total))
	for i in freqs.size():
		_mix(out, _voice(dur, freqs[i], freqs[i], kind, vol, 0.005, 0.0, 1.0, 1.0, 3.5), int(SR * step * i))
	return out

# --- SFX ---------------------------------------------------------------------

func _build_sfx() -> void:
	# whoosh: short band of noise that brightens, quiet because it fires ~5x/s
	sfx["throw"] = _to_stream(_voice(0.09, 0.0, 1.0, "sine", 0.35, 0.006, 1.0, 0.08, 0.55, 4.0))
	# thud with a snap on top
	var hit := _voice(0.16, 200.0, 55.0, "sine", 0.9, 0.002, 0.0, 1.0, 1.0, 5.0)
	_mix(hit, _voice(0.04, 0.0, 1.0, "sine", 0.5, 0.001, 1.0, 0.7, 0.4, 6.0), 0)
	sfx["hit"] = _to_stream(hit)
	# low saw drop + grit
	var hurt := _voice(0.3, 330.0, 80.0, "saw", 0.5, 0.003, 0.0, 1.0, 1.0, 5.5)
	_mix(hurt, _voice(0.3, 0.0, 1.0, "sine", 0.25, 0.003, 1.0, 0.3, 0.1, 4.0), 0)
	sfx["hurt"] = _to_stream(hurt)
	# soft wooden tap
	sfx["click"] = _to_stream(_voice(0.05, 1500.0, 900.0, "tri", 0.6, 0.001, 0.0, 1.0, 1.0, 6.0))
	# blade: bright noise sweeping down + a ringing metallic ping
	var slash := _voice(0.18, 0.0, 1.0, "sine", 0.7, 0.003, 1.0, 0.75, 0.12, 4.5)
	_mix(slash, _voice(0.18, 2600.0, 1300.0, "sine", 0.3, 0.003, 0.0, 1.0, 1.0, 5.0), 0)
	sfx["slash"] = _to_stream(slash)
	# level up: rising pentatonic arpeggio
	sfx["level"] = _to_stream(_seq([440.0, 523.25, 659.25, 880.0, 1046.5], 0.07, 0.22, "tri", 0.7, 0.6))
	# game over: slow falling minor line
	sfx["over"] = _to_stream(_seq([659.25, 523.25, 440.0, 349.23, 220.0], 0.2, 0.45, "tri", 0.7, 1.4))

# --- Music -------------------------------------------------------------------

const BPM := 132.0
const STEPS_PER_BAR := 8
# Scale: A4 B4 C5 E5 F5 A5 B5 C6 (Hirajoshi). -1 = rest.
const NOTES := [440.0, 493.88, 523.25, 659.25, 698.46, 880.0, 987.77, 1046.5]
const MELODY := [
	0, -1, 2, 3, -1, 3, 2, 0,
	1, -1, 0, -1, 2, -1, -1, -1,
	4, -1, 3, 2, -1, 2, 3, 4,
	3, -1, 2, -1, 1, -1, -1, -1,
	3, -1, 4, 5, -1, 5, 4, 3,
	2, -1, 3, -1, 4, -1, -1, -1,
	5, -1, 6, 5, 4, 3, 2, 0,
	1, 0, -1, -1, -1, -1, -1, -1,
]
const BASS_ROOTS := [110.0, 110.0, 87.31, 87.31, 82.41, 82.41, 110.0, 110.0] # A A F F E E A A (per bar)

func _build_music() -> AudioStreamWAV:
	var step := 60.0 / BPM / 2.0
	var step_n := int(SR * step)
	var total := MELODY.size() * step_n
	var buf := PackedFloat32Array()
	buf.resize(total)
	seed(7) # deterministic noise so the loop is identical each launch
	var kick := _voice(0.22, 130.0, 42.0, "sine", 1.0, 0.002, 0.0, 1.0, 1.0, 6.0)
	var snare := _voice(0.16, 190.0, 150.0, "tri", 0.35, 0.002, 0.7, 0.6, 0.35, 7.0)
	var hat := _voice(0.04, 0.0, 1.0, "sine", 0.22, 0.001, 1.0, 0.9, 0.9, 7.0)
	var bass_cache := {}
	var lead_cache := {}
	for s in MELODY.size():
		var off := s * step_n
		var bar := s / STEPS_PER_BAR
		var b := s % STEPS_PER_BAR
		if b == 0 or b == 4:
			_mix(buf, kick, off, true)
		if b == 2 or b == 6:
			_mix(buf, snare, off, true)
		if b % 2 == 1:
			_mix(buf, hat, off, true)
		# bass: root on every step, octave jump on the off-beat for drive
		var root: float = BASS_ROOTS[bar] * (2.0 if b % 4 == 3 else 1.0)
		if not bass_cache.has(root):
			bass_cache[root] = _voice(0.28, root, root, "tri", 0.55, 0.004, 0.0, 1.0, 1.0, 5.0)
		_mix(buf, bass_cache[root], off, true)
		var ni: int = MELODY[s]
		if ni >= 0:
			if not lead_cache.has(ni):
				var f: float = NOTES[ni]
				var lead := _voice(0.34, f, f, "pulse", 0.22, 0.004, 0.0, 1.0, 1.0, 4.5)
				_mix(lead, _voice(0.34, f * 2.0, f * 2.0, "sine", 0.06, 0.004, 0.0, 1.0, 1.0, 6.0), 0)
				lead_cache[ni] = lead
			_mix(buf, lead_cache[ni], off, true)
	return _to_stream(buf, true)

# --- lifecycle / API ---------------------------------------------------------

func _ready() -> void:
	for i in MAX_PLAYERS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -14.0
	add_child(music_player)
	_build_sfx()
	music_player.stream = _build_music()

func _play(key: String, db := 0.0, pitch_var := 0.0) -> void:
	var p := audio_players[current_player_index]
	current_player_index = (current_player_index + 1) % MAX_PLAYERS
	p.stream = sfx[key]
	p.volume_db = db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

func play_shuriken_throw() -> void: _play("throw", -4.0, 0.08)
func play_enemy_hit() -> void: _play("hit", 0.0, 0.06)
func play_player_hurt() -> void: _play("hurt")
func play_click() -> void:
	ensure_music() # first user gesture is what unlocks web audio
	_play("click", -2.0)
func play_sword_slash() -> void: _play("slash", -1.0, 0.05)
func play_level_up() -> void: _play("level")
func play_game_over() -> void: _play("over")

func ensure_music() -> void:
	if not music_player.playing and music_player.stream:
		music_player.play()

# mode: "menu" (quiet), "play" (full), "paused" (ducked), "stop" (fade out)
func set_music_mode(mode: String) -> void:
	var db: float = {"menu": -14.0, "play": -9.0, "paused": -20.0, "stop": -60.0}.get(mode, -14.0)
	if _music_tween:
		_music_tween.kill()
	if mode != "stop":
		ensure_music()
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", db, 0.6)
	if mode == "stop":
		_music_tween.tween_callback(music_player.stop)
