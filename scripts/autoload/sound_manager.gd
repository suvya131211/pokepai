extends Node

# --- Volume / Mute controls ---
var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.4   # 0.0 - 1.0
var sfx_volume: float = 0.6

var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer

func _ready():
	for sfx_name in ["click", "damage", "critical", "catch_shake", "catch_success", "heal", "levelup", "encounter", "door", "item"]:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players[sfx_name] = player

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -10
	add_child(music_player)

# --- Toggle functions (called from controls) ---
func toggle_music():
	music_enabled = !music_enabled
	if not music_enabled:
		stop_music()
	else:
		# Restart current song
		var old = current_music
		current_music = ""
		if old != "":
			play_music(old)

func toggle_sfx():
	sfx_enabled = !sfx_enabled

func set_music_volume(vol: float):
	music_volume = clampf(vol, 0.0, 1.0)

func set_sfx_volume(vol: float):
	sfx_volume = clampf(vol, 0.0, 1.0)

# --- SFX ---
func play_sfx(name: String):
	if not sfx_enabled:
		return
	if name not in sfx_players:
		return
	var player = sfx_players[name]
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.2
	player.stream = gen
	player.volume_db = linear_to_db(sfx_volume)
	player.play()
	var playback = player.get_stream_playback()
	if playback:
		var frames = int(22050 * 0.12)
		var freq = _get_sfx_freq(name)
		var decay = _get_sfx_decay(name)
		for i in frames:
			var t = float(i) / 22050.0
			# Smooth sine wave (not square) for cleaner SFX
			var sample = sin(t * freq * TAU) * maxf(0.0, 1.0 - t * decay) * 0.25 * sfx_volume
			playback.push_frame(Vector2(sample, sample))

func _get_sfx_freq(name: String) -> float:
	match name:
		"click": return 800.0
		"damage": return 200.0
		"critical": return 350.0
		"catch_shake": return 500.0
		"catch_success": return 1200.0
		"heal": return 900.0
		"levelup": return 1000.0
		"encounter": return 400.0
		"door": return 600.0
		"item": return 700.0
	return 440.0

func _get_sfx_decay(name: String) -> float:
	match name:
		"click": return 18.0
		"damage": return 10.0
		"critical": return 6.0
		"catch_shake": return 5.0
		"catch_success": return 3.0
		"heal": return 4.0
		"levelup": return 3.0
		"encounter": return 8.0
		"door": return 12.0
		"item": return 10.0
	return 10.0

func play_victory_jingle():
	play_sfx("levelup")
	await get_tree().create_timer(0.15).timeout
	play_sfx("catch_success")

func play_encounter_jingle():
	play_sfx("encounter")

# --- Music system ---
var current_music: String = ""
var music_gen: AudioStreamGenerator
var music_playback: AudioStreamGeneratorPlayback
var music_time: float = 0.0
var music_tempo: float = 110.0  # slightly slower = more pleasant
var music_notes: Array = []
var music_note_index: int = 0
var music_note_timer: float = 0.0

const NOTES = {
	"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23,
	"G4": 392.00, "A4": 440.00, "B4": 493.88,
	"C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99,
	"R": 0.0,
}

var SONGS = {
	"overworld": [
		["E4",1],["G4",1],["A4",1],["G4",1],["E4",1],["C4",1],["D4",1],["E4",2],["R",1],
		["D4",1],["E4",1],["G4",1],["A4",2],["G4",1],["E4",1],["D4",1],["C4",2],["R",1],
		["C4",1],["E4",1],["G4",1],["C5",2],["B4",1],["A4",1],["G4",1],["E4",2],["R",1],
		["A4",1],["G4",1],["E4",1],["D4",1],["C4",2],["R",2],
	],
	"battle": [
		["E4",0.5],["E4",0.5],["R",0.25],["E4",0.5],["R",0.25],["C4",0.5],["E4",1],["G4",1],["R",0.5],
		["G4",0.5],["R",0.5],["C4",1],["R",0.5],["G4",0.5],["R",0.25],["E4",0.5],["R",0.25],
		["A4",0.5],["B4",0.5],["A4",0.5],["G4",1],["E4",0.5],["G4",0.5],["A4",1],["R",0.5],
		["E4",0.5],["E4",0.5],["R",0.25],["E4",0.5],["R",0.25],["C4",0.5],["E4",1],["G4",1],["R",1],
	],
	"town": [
		["C4",1],["E4",1],["G4",1.5],["E4",0.5],["C4",1],["R",0.5],
		["D4",1],["F4",1],["A4",1.5],["F4",0.5],["D4",1],["R",0.5],
		["E4",1],["G4",1],["B4",1.5],["G4",0.5],["E4",1],["R",0.5],
		["C4",1],["E4",0.5],["G4",0.5],["C5",2],["R",1],
	],
	"cave": [
		["C4",2],["R",1],["E4",1],["R",2],["G4",1],["R",1],
		["A4",2],["R",2],["E4",1],["R",1],["C4",2],["R",2],
		["D4",1],["R",1],["F4",2],["R",2],["C4",2],["R",2],
	],
	"gym": [
		["E4",0.5],["G4",0.5],["A4",0.5],["C5",0.5],["A4",0.5],["G4",0.5],["E4",0.5],["R",0.5],
		["D4",0.5],["F4",0.5],["A4",0.5],["D5",0.5],["A4",0.5],["F4",0.5],["D4",0.5],["R",0.5],
		["E4",0.5],["G4",0.5],["B4",0.5],["E5",0.5],["B4",0.5],["G4",0.5],["E4",0.5],["R",0.5],
		["C4",0.5],["E4",0.5],["G4",0.5],["C5",1],["R",1],
	],
}

func play_music(song_name: String):
	if not music_enabled:
		current_music = song_name
		return
	if song_name == current_music and music_player.playing:
		return
	current_music = song_name
	if song_name == "" or song_name not in SONGS:
		if music_player.playing:
			music_player.stop()
		return
	music_notes = SONGS[song_name]
	music_note_index = 0
	music_note_timer = 0.0
	music_time = 0.0
	music_gen = AudioStreamGenerator.new()
	music_gen.mix_rate = 22050
	music_gen.buffer_length = 0.5
	music_player.stream = music_gen
	music_player.volume_db = linear_to_db(music_volume * 0.5)
	music_player.play()
	music_playback = music_player.get_stream_playback()

func stop_music():
	current_music = ""
	if music_player.playing:
		music_player.stop()

func _process(_delta):
	if not music_enabled or not music_player.playing or music_notes.is_empty():
		return
	if not music_playback:
		return

	var beat_duration = 60.0 / music_tempo
	var frames_available = music_playback.get_frames_available()
	if frames_available <= 0:
		return

	for i in frames_available:
		music_time += 1.0 / 22050.0
		music_note_timer += 1.0 / 22050.0

		var current_note = music_notes[music_note_index]
		var note_freq = NOTES.get(current_note[0], 0.0)
		var note_duration = current_note[1] * beat_duration

		if music_note_timer >= note_duration:
			music_note_timer -= note_duration
			music_note_index = (music_note_index + 1) % music_notes.size()
			current_note = music_notes[music_note_index]
			note_freq = NOTES.get(current_note[0], 0.0)

		var sample = 0.0
		if note_freq > 0:
			# Soft triangle wave (much smoother than square wave)
			var phase = fmod(music_time * note_freq, 1.0)
			if phase < 0.25:
				sample = phase * 4.0
			elif phase < 0.75:
				sample = 2.0 - phase * 4.0
			else:
				sample = phase * 4.0 - 4.0

			# Envelope: attack + sustain + release
			var note_progress = music_note_timer / note_duration
			var env = 1.0
			if note_progress < 0.05:
				env = note_progress / 0.05  # attack
			elif note_progress > 0.8:
				env = (1.0 - note_progress) / 0.2  # release

			sample *= env * music_volume * 0.12

		music_playback.push_frame(Vector2(sample, sample))
