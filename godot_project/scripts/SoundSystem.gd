# SoundSystem.gd
class_name SoundSystem
extends Node

var audio_players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS = 8
var current_player_index = 0

func _ready():
	for i in range(MAX_PLAYERS):
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)

func _get_next_player() -> AudioStreamPlayer:
	var p = audio_players[current_player_index]
	current_player_index = (current_player_index + 1) % MAX_PLAYERS
	return p

func play_tone(freq: float, duration: float = 0.1, vol: float = 0.25):
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var wave = sin(2.0 * PI * freq * t)
		var env = 1.0 - (float(i) / num_samples)
		var sample_val = int(clamp((wave * env * vol * 127.0) + 128.0, 0.0, 255.0))
		data[i] = sample_val
	stream.data = data
	var p = _get_next_player()
	p.stream = stream
	p.play()

func play_shuriken_throw():
	play_tone(800.0, 0.08, 0.2)

func play_enemy_hit():
	play_tone(220.0, 0.12, 0.3)

func play_player_hurt():
	play_tone(150.0, 0.2, 0.35)

func play_click():
	play_tone(600.0, 0.05, 0.2)

func play_sword_slash():
	play_tone(1200.0, 0.12, 0.4)

func play_level_up():
	var freqs = [523.0, 659.0, 783.0, 1046.0]
	for i in range(freqs.size()):
		get_tree().create_timer(i * 0.08).timeout.connect(func(): play_tone(freqs[i], 0.15, 0.3))

func play_game_over():
	var freqs = [400.0, 350.0, 300.0, 250.0, 180.0]
	for i in range(freqs.size()):
		get_tree().create_timer(i * 0.12).timeout.connect(func(): play_tone(freqs[i], 0.2, 0.3))
