extends Node

var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer

func _ready():
	# Create SFX players
	for sfx_name in ["click", "damage", "critical", "catch_shake", "catch_success", "heal", "levelup", "encounter", "door", "item"]:
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players[sfx_name] = player

	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -6
	add_child(music_player)

func play_sfx(name: String):
	if name in sfx_players:
		var player = sfx_players[name]
		var gen = AudioStreamGenerator.new()
		gen.mix_rate = 22050
		gen.buffer_length = 0.15
		player.stream = gen
		player.play()
		# Fill with tone
		var playback = player.get_stream_playback()
		if playback:
			var frames = int(22050 * 0.1)
			var freq = _get_sfx_freq(name)
			var decay = _get_sfx_decay(name)
			for i in frames:
				var t = float(i) / 22050.0
				var sample = sin(t * freq * TAU) * maxf(0.0, 1.0 - t * decay) * 0.3
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
		"click": return 15.0
		"damage": return 8.0
		"critical": return 5.0
		"catch_shake": return 4.0
		"catch_success": return 2.0
		"heal": return 3.0
		"levelup": return 2.0
		"encounter": return 6.0
		"door": return 10.0
		"item": return 8.0
	return 10.0

func play_victory_jingle():
	# Play ascending tones
	play_sfx("levelup")
	await get_tree().create_timer(0.15).timeout
	play_sfx("catch_success")

func play_encounter_jingle():
	play_sfx("encounter")
