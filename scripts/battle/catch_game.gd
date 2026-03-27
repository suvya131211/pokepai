extends Control
class_name CatchScene

enum CatchPhase { AIM, THROW, SHAKE, BREAK, RESULT }

var wild_pokemon: Pokemon
var inventory: PlayerInventory
var phase: CatchPhase = CatchPhase.AIM
var ball_pos: Vector2
var ball_vel: Vector2
var ball_active: bool = false
var target_pos: Vector2
var shake_count: int = 0
var shake_timer: float = 0.0
var result: String = ""  # "caught" / ""
var result_timer: float = 0.0
var aim_angle: float = 0.0
var aim_dir: float = 1.0
var message: String = "Click to throw Pokeball!"
var razz_active: bool = false

signal catch_ended(result: String, wild: Pokemon)

func start(wild: Pokemon, inv: PlayerInventory) -> void:
	wild_pokemon = wild
	inventory = inv
	phase = CatchPhase.AIM
	ball_pos = Vector2(size.x / 2, size.y - 80)
	target_pos = Vector2(size.x * 0.65, size.y * 0.25)
	result = ""
	shake_count = 0
	message = "Click to throw Pokeball!"
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	aim_angle += delta * 2.0 * aim_dir
	if abs(aim_angle) > 0.5:
		aim_dir *= -1

	if ball_active:
		ball_pos += ball_vel * delta
		ball_vel.y += 50.0 * delta
		if ball_pos.distance_to(target_pos) < 30:
			ball_active = false
			_check_catch()
		elif ball_pos.y > size.y + 10 or ball_pos.x < 0 or ball_pos.x > size.x:
			ball_active = false
			ball_pos = Vector2(size.x / 2, size.y - 80)
			phase = CatchPhase.AIM
			message = "Missed! Try again." if inventory.total_balls() > 0 else "No balls left!"

	if phase == CatchPhase.SHAKE:
		shake_timer -= delta
		if shake_timer <= 0:
			shake_count += 1
			if shake_count >= 3:
				phase = CatchPhase.RESULT
				result = "caught"
				message = "Gotcha! %s was caught!" % wild_pokemon.pokemon_name
				result_timer = 2.0
			else:
				shake_timer = 0.6
				message = "...%d..." % shake_count

	if phase == CatchPhase.BREAK:
		shake_timer -= delta
		if shake_timer <= 0:
			phase = CatchPhase.AIM
			shake_count = 0
			message = "%s broke free!" % wild_pokemon.pokemon_name

	if result_timer > 0:
		result_timer -= delta
		if result_timer <= 0 and result == "caught":
			catch_ended.emit("caught", wild_pokemon)
			visible = false

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible or phase != CatchPhase.AIM:
		return
	if event is InputEventMouseButton and event.pressed:
		_throw_ball(event.position)

func _throw_ball(mouse_pos: Vector2) -> void:
	var ball_type := inventory.use_ball()
	if ball_type.is_empty():
		message = "No Pokeballs!"
		return
	var start := Vector2(size.x / 2, size.y - 80)
	var dir := (mouse_pos - start).normalized()
	ball_pos = start
	ball_vel = dir * 280.0 + Vector2(0, -70)
	ball_active = true
	phase = CatchPhase.THROW

func _check_catch() -> void:
	var catch_rate := wild_pokemon.get_catch_rate()
	if razz_active:
		catch_rate = minf(0.95, catch_rate + 0.2)
		razz_active = false
	if randf() < catch_rate:
		phase = CatchPhase.SHAKE
		shake_count = 0
		shake_timer = 0.8
		message = "..."
	else:
		phase = CatchPhase.BREAK
		shake_timer = 1.5
		message = "%s wiggled out!" % wild_pokemon.pokemon_name

func _draw() -> void:
	if not visible:
		return
	var w := size.x
	var h := size.y

	draw_rect(Rect2(0, 0, w, h), Color("#0d1b2a"))

	# Wild pokemon with wobble
	var wobble := sin(shake_timer * 20.0) * 8.0 if phase == CatchPhase.SHAKE else 0.0
	draw_circle(target_pos + Vector2(wobble, 0), 40.0, wild_pokemon.color)
	draw_arc(target_pos + Vector2(wobble, 0), 40.0, 0, TAU, 24, Color.WHITE, 2.0)

	# HP bar
	var ratio := float(wild_pokemon.hp) / float(wild_pokemon.max_hp)
	draw_rect(Rect2(target_pos.x - 40, target_pos.y - 55, 80, 6), Color("#333"))
	draw_rect(Rect2(target_pos.x - 40, target_pos.y - 55, 80 * ratio, 6), Color("#4caf50") if ratio > 0.5 else Color("#f44336"))

	# Aim line
	if phase == CatchPhase.AIM:
		var aim_x := w / 2 + sin(aim_angle) * 120
		draw_dashed_line(Vector2(w/2, h-80), Vector2(aim_x, h-250), Color(1,1,1,0.3), 1.0, 4.0)

	# Ball
	var br := 8.0
	draw_circle(ball_pos + Vector2(0, -br/2), br, Color("#f44336"))  # top half red
	draw_circle(ball_pos + Vector2(0, br/2), br, Color.WHITE)        # bottom half white
	draw_circle(ball_pos, 3, Color.WHITE)
	draw_arc(ball_pos, br, 0, TAU, 16, Color("#333"), 1.5)

	# Message
	draw_rect(Rect2(10, h - 80, w - 20, 65), Color("#1c3144"))
	draw_rect(Rect2(10, h - 80, w - 20, 65), Color("#4fc3f7"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22, h - 50), message, HORIZONTAL_ALIGNMENT_LEFT, w - 44, 14, Color("#e0e0e0"))

	# Inventory
	draw_string(ThemeDB.fallback_font, Vector2(20, 20), "Pokeball:%d  Great:%d  Ultra:%d" % [
		inventory.balls.get("pokeball",0), inventory.balls.get("greatball",0), inventory.balls.get("ultraball",0)
	], HORIZONTAL_ALIGNMENT_LEFT, w, 11, Color("#aaa"))
