extends Control
class_name BattleScene

var wild_pokemon = null
var wild_species: Dictionary = {}
var wild_level: int = 1
var sprite_texture: Texture2D = null
var inventory = null

# Catching state
var circle_radius: float = 80.0  # shrinks from 80 to 20, loops
var circle_speed: float = 40.0   # px/sec shrink speed
var circle_min: float = 20.0
var circle_max: float = 80.0
var circle_shrinking: bool = true

# Ball throw
var ball_pos: Vector2
var ball_vel: Vector2
var ball_active: bool = false
var ball_start: Vector2
var target_center: Vector2

# State
enum Phase { ENCOUNTER, AIM, THROW, SHAKE, RESULT }
var phase: Phase = Phase.ENCOUNTER
var message: String = ""
var message_timer: float = 0.0
var shake_count: int = 0
var shake_timer: float = 0.0
var result: String = ""  # "caught" / ""
var result_timer: float = 0.0
var throw_rating: String = ""  # "Nice!" / "Great!" / "Excellent!"
var throw_bonus: float = 1.0

# Animation
var pokemon_y_offset: float = 0.0
var encounter_timer: float = 1.5

signal battle_ended(result: String, wild)

func start(party: Array, wild) -> void:
	wild_pokemon = wild
	wild_species = wild.species
	wild_level = wild.level
	sprite_texture = PokemonDB.get_sprite_texture(wild.id)
	phase = Phase.ENCOUNTER
	message = "A wild %s appeared!" % wild.pokemon_name
	encounter_timer = 1.5
	circle_radius = circle_max
	result = ""
	throw_rating = ""
	visible = true
	queue_redraw()

func set_inventory(inv) -> void:
	inventory = inv

func _process(delta: float) -> void:
	if not visible:
		return

	match phase:
		Phase.ENCOUNTER:
			encounter_timer -= delta
			if encounter_timer <= 0:
				phase = Phase.AIM
				message = "Throw a Pokeball!"

		Phase.AIM:
			# Shrinking circle animation
			if circle_shrinking:
				circle_radius -= circle_speed * delta
				if circle_radius <= circle_min:
					circle_shrinking = false
			else:
				circle_radius += circle_speed * delta
				if circle_radius >= circle_max:
					circle_shrinking = true

		Phase.THROW:
			ball_pos += ball_vel * delta
			ball_vel.y += 80.0 * delta  # gravity
			# Check if ball reaches target
			if ball_pos.distance_to(target_center) < 40:
				ball_active = false
				_evaluate_throw()
			elif ball_pos.y > size.y + 20 or ball_pos.x < -20 or ball_pos.x > size.x + 20:
				ball_active = false
				phase = Phase.AIM
				message = "Missed! Try again."

		Phase.SHAKE:
			shake_timer -= delta
			if shake_timer <= 0:
				shake_count += 1
				if shake_count >= 3:
					phase = Phase.RESULT
					result = "caught"
					message = "Gotcha! %s was caught!" % wild_pokemon.pokemon_name
					result_timer = 2.0
				else:
					shake_timer = 0.5
					message = "...%d..." % shake_count

		Phase.RESULT:
			result_timer -= delta
			if result_timer <= 0:
				battle_ended.emit(result, wild_pokemon)
				visible = false

	# Pokemon bob
	pokemon_y_offset = sin(Time.get_ticks_msec() * 0.003) * 4.0

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if phase == Phase.AIM and event is InputEventMouseButton and event.pressed:
		_throw_ball(event.position)
	# Run button (bottom right)
	if phase == Phase.AIM and event is InputEventMouseButton and event.pressed:
		var run_rect = Rect2(size.x - 100, size.y - 50, 80, 36)
		if run_rect.has_point(event.position):
			result = "fled"
			battle_ended.emit("fled", wild_pokemon)
			visible = false

func _throw_ball(click_pos: Vector2) -> void:
	if not inventory or inventory.total_balls() <= 0:
		message = "No Pokeballs!"
		return
	inventory.use_ball()

	ball_start = Vector2(size.x / 2, size.y - 60)
	ball_pos = ball_start
	var dir = (click_pos - ball_start).normalized()
	ball_vel = dir * 350.0 + Vector2(0, -100)
	ball_active = true
	phase = Phase.THROW

func _evaluate_throw() -> void:
	# Rate based on circle size at throw time
	var ratio = (circle_radius - circle_min) / (circle_max - circle_min)  # 0 = smallest, 1 = biggest
	if ratio < 0.25:
		throw_rating = "Excellent!"
		throw_bonus = 1.75
	elif ratio < 0.5:
		throw_rating = "Great!"
		throw_bonus = 1.5
	elif ratio < 0.75:
		throw_rating = "Nice!"
		throw_bonus = 1.2
	else:
		throw_rating = ""
		throw_bonus = 1.0

	message = throw_rating if throw_rating else ""

	# Catch calculation
	var base_rate = wild_pokemon.get_catch_rate()
	var final_rate = base_rate * throw_bonus
	final_rate = minf(0.95, final_rate)

	if randf() < final_rate:
		phase = Phase.SHAKE
		shake_count = 0
		shake_timer = 0.6
		message = "..." if not throw_rating else throw_rating + " ..."
	else:
		phase = Phase.AIM
		circle_radius = circle_max
		message = "%s broke free!" % wild_pokemon.pokemon_name

func _draw() -> void:
	if not visible:
		return
	var w = size.x
	var h = size.y

	# Dark background with gradient
	draw_rect(Rect2(0, 0, w, h), Color("#0a0e1a"))
	# Slight gradient
	for i in 10:
		var alpha = 0.02 * (10 - i)
		draw_rect(Rect2(0, h * i / 10.0, w, h / 10.0), Color(0.1, 0.15, 0.3, alpha))

	target_center = Vector2(w / 2, h * 0.35)

	# Pokemon sprite (centered, larger)
	if sprite_texture:
		var wobble_x = 0.0
		if phase == Phase.SHAKE:
			wobble_x = sin(shake_timer * 25.0) * 10.0
		var sprite_size = 128.0
		var dst = Rect2(target_center.x - sprite_size/2 + wobble_x,
						target_center.y - sprite_size/2 + pokemon_y_offset,
						sprite_size, sprite_size)
		draw_texture_rect(sprite_texture, dst, false)
	else:
		draw_circle(target_center + Vector2(0, pokemon_y_offset), 50,
					wild_pokemon.color if wild_pokemon else Color.WHITE)

	# Shrinking colored circle (Pokemon Go style)
	if phase == Phase.AIM:
		# Outer static circle
		draw_arc(target_center, circle_max, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0)
		# Inner shrinking circle with color based on difficulty
		var ratio = circle_radius / circle_max
		var circle_color: Color
		if ratio > 0.6:
			circle_color = Color("#4caf50")  # green = easy
		elif ratio > 0.35:
			circle_color = Color("#ff9800")  # orange = medium
		else:
			circle_color = Color("#f44336")  # red = hard (but best bonus!)
		draw_arc(target_center, circle_radius, 0, TAU, 48, circle_color, 3.0)

	# Pokeball
	if ball_active or phase == Phase.AIM:
		var bp = ball_pos if ball_active else Vector2(w / 2, h - 60)
		var br = 12.0
		# Red top half
		draw_arc(bp, br, PI, TAU, 12, Color("#e53935"), br)
		draw_circle(bp + Vector2(0, -br/4), br * 0.6, Color("#e53935"))
		# White bottom half
		draw_circle(bp + Vector2(0, br/4), br * 0.6, Color.WHITE)
		# Center line and button
		draw_line(bp + Vector2(-br, 0), bp + Vector2(br, 0), Color("#333"), 2.0)
		draw_circle(bp, 4, Color.WHITE)
		draw_arc(bp, 4, 0, TAU, 8, Color("#333"), 1.5)

	# Name and level
	draw_string(ThemeDB.fallback_font, Vector2(w/2 - 60, 40),
				"%s  Lv.%d" % [wild_pokemon.pokemon_name if wild_pokemon else "???", wild_level],
				HORIZONTAL_ALIGNMENT_CENTER, 120, 16, Color.WHITE)

	# Throw rating text (fades)
	if throw_rating and phase in [Phase.SHAKE, Phase.RESULT]:
		var rating_color = Color("#ffd700") if throw_rating == "Excellent!" else (Color("#ff9800") if throw_rating == "Great!" else Color("#4caf50"))
		draw_string(ThemeDB.fallback_font, Vector2(w/2 - 40, h * 0.55),
					throw_rating, HORIZONTAL_ALIGNMENT_CENTER, 80, 20, rating_color)

	# Message box
	draw_rect(Rect2(10, h - 80, w - 20, 60), Color(0.11, 0.19, 0.27, 0.9))
	draw_rect(Rect2(10, h - 80, w - 20, 60), Color("#4fc3f7"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22, h - 50), message,
				HORIZONTAL_ALIGNMENT_LEFT, w - 44, 14, Color("#e0e0e0"))

	# Run button (bottom right)
	if phase == Phase.AIM:
		draw_rect(Rect2(w - 100, h - 50, 80, 36), Color(0.15, 0.15, 0.2))
		draw_rect(Rect2(w - 100, h - 50, 80, 36), Color("#f44336"), false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(w - 90, h - 26), "RUN",
					HORIZONTAL_ALIGNMENT_LEFT, 60, 13, Color("#f44336"))

	# Ball count
	if inventory:
		draw_string(ThemeDB.fallback_font, Vector2(20, h - 90),
					"Balls: %d" % inventory.total_balls(),
					HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("#aaa"))
